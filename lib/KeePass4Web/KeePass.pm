package KeePass4Web::KeePass;
use strict;
use warnings;

use Dancer qw/:syntax/;
use Dancer::Plugin::Ajax;
use IPC::ShareLite;
use Time::Duration::Parse;
use Crypt::Mode::CBC;
use Bytes::Random::Secure;
use Sereal::Encoder qw/encode_sereal/;
use Sereal::Decoder qw/decode_sereal/;
use Config ();
use MIME::Base64 qw/decode_base64/;
use URI::Escape qw/uri_escape_utf8/;
use File::LibMagic;

use File::KeePass::Web;
use Kernel::Keyring;

use KeePass4Web::Backend;
use KeePass4Web::Constant;

use constant DB_TIMEOUT      => parse_duration config->{db_session_timeout};
use constant IPC_ID          => config->{ipc_id};
use constant IPC_SIZE        => config->{ipc_segment_size} * 1024;
use constant SESSION_PW_KEY  => 'kp:pw_key_';
use constant SESSION_DB_KEY  => 'kp:db_key_';
use constant SESSION_DB_IV   => 'kp:db_iv_';
use constant KEYRING_TYPE    => 'user';
use constant KEYRING_SESSION => config->{keyring_session};
# all to possessor, none to everyone else
use constant KEYRING_PERM    => 0x3f000000;
use constant EPOCH_TEMPLATE  => $Config::Config{ivsize} == 8 ? 'Q' : 'L';

BEGIN {
    require Exporter;
    our @ISA = 'Exporter';
    our @EXPORT = qw/
        failure
        success
    /;

    # preload cipher module, so we don't get any surprises later
    my $module = 'Crypt::Cipher::' . config->{ipc_cipher} . '.pm';
    $module =~ s/::/\//g;
    require $module;

    $module = 'Crypt::Cipher::' . config->{pw_cipher} . '.pm';
    $module =~ s/::/\//g;
    require $module;
}

sub failure {
    status $_[1] || BAD_REQUEST;
    return to_json { success => \0, message => $_[0] }
}

sub success {
    status $_[2] if defined $_[2];
    return to_json { success => \1, message => $_[0], data => $_[1] }
}

sub store_keys {
    my ($pw_key, $db_key, $db_iv) = @_;

    my $user = session SESSION_USERNAME;

    # add keys to kernel keyring
    my $key_id_pw_key = key_add KEYRING_TYPE, SESSION_PW_KEY . $user, $$pw_key, KEYRING_SESSION;
    my $key_id_db_key = key_add KEYRING_TYPE, SESSION_DB_KEY . $user, $$db_key, KEYRING_SESSION;
    my $key_id_db_iv  = key_add KEYRING_TYPE, SESSION_DB_IV  . $user, $$db_iv,  KEYRING_SESSION;

    foreach my $key_id (($key_id_pw_key, $key_id_db_key, $key_id_db_iv)) {
        # set timeout on key for security
        key_timeout $key_id, DB_TIMEOUT;

        # limit permissions for other processes (of the same user)
        key_perm $key_id, KEYRING_PERM;
    }

    # add key ids to user session
    session SESSION_PW_KEY, $key_id_pw_key;
    session SESSION_DB_KEY, $key_id_db_key;
    session SESSION_DB_IV,  $key_id_db_iv;

    return;
}

sub update_key_timeout {
    key_timeout session(SESSION_PW_KEY), DB_TIMEOUT;

    key_timeout session(SESSION_DB_KEY), DB_TIMEOUT;
    key_timeout session(SESSION_DB_IV),  DB_TIMEOUT;

    return;
}

sub retrieve_pw_key () {
    return key_get_by_id session SESSION_PW_KEY;
}

sub retrieve_db_key () {

    # update key timeout on access
    # database becomes inaccessible after user idled for some time
    # need to update from db keys only since it is always called first
    update_key_timeout;

    return key_get_by_id(session SESSION_DB_KEY), key_get_by_id(session SESSION_DB_IV);
}

sub get_crypt {
    my ($alt_cipher) = @_;
    return Crypt::Mode::CBC->new($alt_cipher // config->{ipc_cipher});
}

sub ipc {
    my $ipc = IPC::ShareLite->new(
        -key       => IPC_ID,
        -mode      => 0600,
        -create    => 1,
        -destroy   => 0,
        -exclusive => 0,
        -size      => IPC_SIZE
    ) or die "$!\n";

    debug 'IPC memory usage: ', $ipc->size * $ipc->num_segments;

    my $shared = $ipc->fetch;
    $shared = $shared ? decode_sereal $shared : {};
    return $shared, $ipc;
}

sub ipc_store {
    my $data = shift;
    my ($shared, $ipc) = ipc;

    foreach my $user (keys %$shared) {
        my $time = $shared->{$user}->{expires};
        if (time >= $time) {
            debug "Removed expired database of $user";
            delete $shared->{$user};
        }
    }

    if ($data) {
        $shared->{session SESSION_USERNAME}->{groups} = $data;
        $shared->{session SESSION_USERNAME}->{expiry} = time + DB_TIMEOUT;
    }
    else {
        delete $shared->{session SESSION_USERNAME};
    }
    $ipc->store(encode_sereal $shared);
}

sub fetch_and_decrypt {
    my %args = @_;

    # grab db ref from backend
    my $db = KeePass4Web::Backend::get_db;

    # key file user input overrides configured key file location
    # eval in case key file location is not available
    my $keyfile = ${$args{keyfile}} || eval { ${KeePass4Web::Backend::get_key()} };
    my $keyfile_ref;
    $keyfile_ref = \$keyfile if $keyfile;

    # untaint
    my ($password) = $args{password} =~ /^(.*)$/;
    $password = $args{password};

    my $kp = File::KeePass::Web->new;
    # keyfile is a ref to a scalar
    # returns key and IV for newly encrypted entry passwords
    my $pw_key = $kp->parse_db($db, [$password, $keyfile_ref], undef, config->{pw_cipher}, config->{hist_and_bin});
    my $b = Bytes::Random::Secure->new(NonBlocking => 1);
    my ($db_key, $db_iv) = ($b->bytes(32), $b->bytes(16));

    # reencrypt db and store in shared memory
    # add expiry date in front
    ipc_store get_crypt->encrypt(encode_sereal($kp->groups), $db_key, $db_iv);

    # pw key is already a ref
    store_keys $pw_key, \$db_key, \$db_iv;
}

sub ipc_retrieve {
    my ($shared, $ipc) = ipc;

    my $user = $shared->{session SESSION_USERNAME};

    # update expiry date
    if (defined $user) {
        $user->{expires} = time + DB_TIMEOUT;
        $ipc->store(encode_sereal $shared);
    }
    else {
        die "Database is closed\n";
    }

    return decode_sereal get_crypt->decrypt($user->{groups}, retrieve_db_key);
}

# remove database from shared memory
sub clear_db {
    # invalidate all key ids
    eval {
        key_revoke session SESSION_PW_KEY if session SESSION_PW_KEY;
        key_revoke session SESSION_DB_KEY if session SESSION_DB_KEY;
        key_revoke session SESSION_DB_IV  if session SESSION_DB_IV;
    };
    if ($@) {
        debug session(SESSION_USERNAME) . ": $@";
    }

    # remove keys from user session
    session SESSION_PW_KEY, undef;
    session SESSION_DB_KEY, undef;
    session SESSION_DB_IV, undef;

    # delete db
    ipc_store undef;
}


sub opened {
    eval { ipc_retrieve };
    if ($@) {
        debug session(SESSION_USERNAME), ": $@";
        clear_db;
        return 0;
    }
    return 1;
}


sub walk_tree {
    my ($group, $children, $counter) = @_;
    $counter++;

    # not interested in leafs
    my $groups = $group->{groups} // return;

    my $grandchildren = [];

    foreach my $subgroup (@$groups) {
        walk_tree($subgroup, $grandchildren, $counter);
    }

    push @$children, {
        name     => $group->{title},
        id       => $group->{id},
        toggled  => $counter >= config->{toggled_levels} ? \0 : $group->{expanded} ? \1 : \0,
        # no toggling if no children
        children => @$grandchildren ? $grandchildren : undef,
    };


=pod
    # if it has groups, it also has entries, even if empty
    foreach my $entry (@{$group->{entries}}) {
        # only grabbing name and id, no details
        push @$grandchildren, {
            name => $entry->{title},
            id   => $entry->{id},
        }
    }
=cut
}

sub debloat {
    my $entry = shift;

    $entry->{password}  = undef;
    $entry->{binary}    = undef;
    $entry->{history}   = undef;
    $entry->{strings}   = undef;
    $entry->{protected} = undef;
}

ajax '/get_tree' => sub {
    my $kp = eval { ipc_retrieve->[0] };
    if ($@) {
        debug session(SESSION_USERNAME), ": $@";
        clear_db;
        return failure 'Failed to load database', UNAUTHORIZED;
    }

    my $children = [];
    my $tree = {
        id       => $kp->{id},
        name     => $kp->{title},
        toggled  => $kp->{expanded} ? \1 : \0,
        children => $children,
    };

    my $counter = 0;
    foreach my $group (@{$kp->{groups}}) {
        walk_tree $group, $children, $counter;
    }

=pod
    foreach my $entry (@{$kp->{entries}}) {
        # only grabbing name and id, no details
        push @$children, {
            name => $entry->{title},
            id   => $entry->{id},
        }
    }
=cut

    return success undef, $tree;
};

ajax '/get_group' => sub {
    my $id = param 'id' or return failure 'No id given';

    my $kp = eval { ipc_retrieve };
    if ($@) {
        debug session(SESSION_USERNAME), ": $@";
        clear_db;
        return failure 'Failed to load database', UNAUTHORIZED;
    }

    # create new object for the find methods
    my @entries = File::KeePass::Web->new(groups => $kp)->find_entries({ group_id => $id });

    # remove bloated / protected fields
    foreach my $entry (@entries) {
        debloat $entry;
    }

    return success undef, \@entries;
};

ajax '/get_entry' => sub {
    my $id = param 'id' or return failure 'No id given';

    my $kp = eval { ipc_retrieve };
    if ($@) {
        debug session(SESSION_USERNAME), ": $@";
        clear_db;
        return failure 'Failed to load database', UNAUTHORIZED;
    }

    my $entry = eval { File::KeePass::Web->new(groups => $kp)->find_entry({ id => $id }) };
    if ($@) {
        error session(SESSION_USERNAME), ": $@";
        return failure 'Search returned more than one entry', SERVER_ERROR;
    }
    return failure 'Could not find entry', SERVER_ERROR if !$entry;

    $entry->{password} = undef;
    my $strings = $entry->{strings};
    my $protected = $entry->{protected};
    foreach my $string (keys %$strings) {
        $strings->{$string} = undef if $protected->{$string};
    }

    # remove history and files to keep the size small
    $entry->{history} = undef;
    my $files = $entry->{binary};
    if (ref $files eq 'HASH') {
        foreach my $file (keys %$files) {
            $files->{$file} = undef;
        }
    }

    return success undef, $entry;
};

ajax '/get_password' => sub {
    my $id   = param 'id' or return failure 'No id given';
    my $name = param 'name' or return failure 'No name given';


    my $kp = eval { ipc_retrieve };
    if ($@) {
        debug session(SESSION_USERNAME), ": $@";
        clear_db;
        return failure 'Failed to load database', UNAUTHORIZED;
    }

    my $entry = eval { File::KeePass::Web->new(groups => $kp)->find_entry({ id => $id }) };
    if ($@) {
        error session(SESSION_USERNAME), ": $@";
        return failure 'Search returned more than one entry', SERVER_ERROR;
    }
    return failure 'Could not find entry', SERVER_ERROR if !$entry;

    if ($entry->{protected}->{$name}) {
        # TODO: update timestamp and usecount, but requires saving back to backend
         my ($iv, $ciphertext) = unpack 'a16a*', $name eq 'password' ? $entry->{password} : $entry->{strings}->{$name};
         return success undef, get_crypt(config->{pw_cipher})->decrypt($ciphertext, retrieve_pw_key, $iv);
    }
    return failure 'Field is not encrypted';
};

ajax '/get_file' => sub {
    my $id       = param 'id' or return failure 'No id given';
    my $filename = param 'filename' or return failure 'No filename given';

    my $kp = eval { ipc_retrieve };
    if ($@) {
        debug session(SESSION_USERNAME), ": $@";
        clear_db;
        return failure 'Failed to load database', UNAUTHORIZED;
    }

    my $entry = eval { File::KeePass::Web->new(groups => $kp)->find_entry({ id => $id }) };
    if ($@) {
        error session(SESSION_USERNAME), ": $@";
        return failure 'Search returned more than one entry', SERVER_ERROR;
    }
    return failure 'Could not find entry', SERVER_ERROR if !$entry;

    my $binary = $entry->{binary};
    if (ref $binary eq 'HASH' && exists $binary->{$filename}) {
         my ($iv, $ciphertext) = unpack 'a16a*', $binary->{$filename};
         my $file = get_crypt(config->{pw_cipher})->decrypt($ciphertext, retrieve_pw_key, $iv);

         # set header for download and proper file name, according to rfc5987
         header 'Content-Disposition' => "attachment; filename*=UTF-8''" . uri_escape_utf8($filename);
         # guess and set content type
         # Dancer will convert text/* types to UTF-8 here
         # TODO: make the module optional
         content_type(File::LibMagic->new->info_from_string(\$file)->{mime_type});

         return $file;
    }
    return failure 'File not found', NOT_FOUND;
};

ajax '/search_entries' => sub {
    my $term = param 'term' or return success undef, [];

    my $kp = eval { ipc_retrieve };
    if ($@) {
        debug session(SESSION_USERNAME), ": $@";
        clear_db;
        return failure 'Failed to load database', UNAUTHORIZED;
    }


    my $extra_fields = config->{search}->{extra_fields};
    my $rgx = config->{search}->{allow_regex} ? qr/$term/i : qr/\Q$term\E/i;

    my @matches;
    my @entries = File::KeePass::Web->new(groups => $kp)->find_entries({});

    outer: foreach my $entry (@entries) {
        # configured fields
        foreach my $field (@{config->{search}->{fields}}) {
            if (defined $entry->{$field} && $entry->{$field} =~ $rgx) {
                debloat $entry;
                push @matches, $entry;
                next outer;
            }
        }

        # string fields
        next if !$extra_fields || ref $entry->{strings} ne 'HASH';
        foreach my $field (keys %{$entry->{strings}}) {
            # checking field key
            if ($field =~ $rgx) {
                debloat $entry;
                push @matches, $entry;
                next outer;
            }
            if (ref $entry->{protected} eq 'HASH' && $entry->{protected}->{$field}) {
                next
            }
            # checking field value
            if (defined $entry->{strings}->{$field} && $entry->{strings}->{$field} =~ $rgx) {
                debloat $entry;
                push @matches, $entry;
                next outer;
            }
        }

        # file names
        next if ref $entry->{binary} ne 'HASH';
        foreach my $filename (keys %{$entry->{binary}}) {
            if ($filename =~ $rgx) {
                debloat $entry;
                push @matches, $entry;
                next outer;
            }
        }

        # ignore history entries
    }

    return success undef, \@matches;
};

ajax '/close_db' => sub {
    eval { clear_db };
    if ($@) {
        error session(SESSION_USERNAME), ": $@";
        return failure, 'Failed to clear DB', SERVER_ERROR;
    }
    return success 'DB closed';
};


1;
