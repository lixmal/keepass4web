package KeePass4Web::Backend::Seafile;
use strict;
use warnings;
use parent 'KeePass4Web::Backend::Abstract';

use Dancer2 appname => 'KeePass4Web';

use Seafile::Client::REST;
use KeePass4Web::Constant qw/!BAD_REQUEST !NOT_FOUND/;

use constant SESSION_SF_TOKEN => 'seafile_token';

# hint: 'die's don't use trailing newlines, because Seafile::Client::REST already puts them there

sub init {}

sub _location {
    my $key_requested = shift;

    # might return undef, no key file available in that case
    return session SESSION_KP_KEYFILE if $key_requested;

    # use location from auth backend if available
    my $db_session = session SESSION_KP_DB;
    return $db_session if $db_session;

    # default is statically configured location
    return config->{Seafile}->{db_location};
}

sub _decrypt {
    my ($seafile, $repo_id, $args) = @_;

    debug "Decrypting repo $repo_id";
    # decrypt library if encrypted
    if ($args && exists $args->{password}) {
        eval {
            $seafile->decrypt_library(
                'repo-id' => $repo_id,
                password  => $args->{password},
            )
        };
        if ($@) {
            my $code = $seafile->code;
            # CONFLICT = not encrypted: we proceed like nothing happened
            if ($code == CONFLICT) {
                debug "Repo $repo_id not encrypted";
            }
            elsif ($code >= 400) {
                info 'Repo decryption: ', $seafile->code, $seafile->error;
                die "Failed to decrypt library: $@";
            }
        }
    }
}

sub _new {
    my $seafile = Seafile::Client::REST->new(
        host  => config->{Seafile}->{url},
        token => session SESSION_SF_TOKEN,
    );

    # set proxy to environment
    # FIXME: won't work with mod_perl, as there is no env
    $seafile->ua->env_proxy(1);

    return $seafile;
}

sub _init_repo {
    my ($get_key, $args) = @_;

    my $seafile = _new;

    my $location = _location $get_key;
    debug 'Seafile location: ', $location;

    my ($repo_id, $dir) = split /\//, $location, 2;
    if (!defined $repo_id || !defined $dir) {
        die "Invalid Seafile location\n";
    }
    debug 'Repo: ', $repo_id, ', dir: ', $dir;

    return $seafile, $repo_id, $dir;
}

sub _get {
    my ($self, $get_key, %args) = @_;

    my ($seafile, $repo_id, $dir) = _init_repo $get_key, \%args;

    # get download link
    my $db = eval {
        $seafile->download_file(
            'repo-id' => $repo_id,
            p         => "/$dir",
            reuse     => 0,
        );
    };
    if ($@) {
        error $seafile->code, $seafile->error;

        debug 'Database URL to download from Seafile: ', $seafile->location;
        # clear session token if library decryption expired, so user gets redirected to backend login screen
        session SESSION_SF_TOKEN, undef if $seafile->code == BAD_REQUEST;
        die $@;
    }

    return $db;
}

sub get_key {
    shift->_get(1, @_)
}

sub get_db {
    shift->_get(0, @_)
}

sub put_db {
    my ($self, $db, %args) = @_;

    my ($seafile, $repo_id, $dir) = _init_repo \%args;

    ($dir, my $filename) = $dir =~ /^(.*\/)(.*)$/;

    # get upload link
    my $url = eval {
        $seafile->upload_link(
            'repo-id' => $repo_id,
            p         => "/$dir",
        );
    };
    if ($@) {
        error $seafile->code, $seafile->error;
        die $@;
    }
    debug 'Database URL to upload to Seafile: ', $url;

    # upload file
    my $resp = $seafile->ua->post(
        $url,
        filename       => $filename,
        'Content-Type' => 'application/octet-stream',
        # need to deref here
        Content        => $db
    );
    return $resp->is_success || die "Failed to upload file\n";
}

sub credentials_init {
    my ($self, $args) = @_;

    if (!defined $args->{username} || !defined $args->{password}) {
        die "Username or password not supplied\n";
    }

    info 'Backend login attempt: ', $args->{username};

    my $seafile = _new;

    eval {
        $seafile->init(
            username => $args->{username},
            password => $args->{password},
        );
    };
    if ($@) {
        info 'Seafile credentials init: ', $seafile->code, $seafile->error;
        die "Backend authentication failed\n";
    }


    my ($repo_id_db) = split /\//, _location;
    my ($repo_id_kf) = split /\//, _location(1) // '';

    my $encrypted_db;
    my $encrypted_kf;

    eval {
        # check db library first
        my $repo = $seafile->library_info('repo-id' => $repo_id_db);
        $encrypted_db = $repo->{encrypted};

        debug 'Repo info database: ' , $repo;
        debug 'Repo database encrypted: ' , 0+!!$encrypted_db;

        # no need to check if it's the same repo
        if ($repo_id_kf && $repo_id_db ne $repo_id_kf) {
            $repo = $seafile->library_info('repo-id' => $repo_id_kf);
            $encrypted_kf = $repo->{encrypted};

            debug 'Repo info key file: ' , $repo;
            debug 'Repo key file encrypted: ' , 0+!!$encrypted_kf;
        }
    };
    if ($@) {
        error 'Seafile repo info: ', $seafile->error ? ($seafile->code, $seafile->error) : $@;
        die "Failed to fetch repo encryption status\n";
    }

    if ($encrypted_db || $encrypted_kf) {
        # use user supplied repo pw if supplied
        if ($args->{repo_pw}) {
            $args->{password} = $args->{repo_pw};
        }
        # login password == repo password
        elsif (config->{Seafile}->{reuse_repopw}) {
        }
        else {
            die "At least one repo is encrypted, but no repo password available\n";
        }

        _decrypt $seafile, $repo_id_db, $args if $encrypted_db;
        _decrypt $seafile, $repo_id_kf, $args if $encrypted_kf;
    }

    info 'Backend login successful: ', $args->{username};
    debug 'Token received: ', !!$seafile->token;

    session SESSION_SF_TOKEN, $seafile->token;

    return $self;
}

sub credentials_tpl {
    return {
        type        => 'mask',
        login_title => 'Login',
        # relative to public/
        icon_src    => 'img/seafile-logo.png',
        fields      => [
            {
                placeholder => 'Username / Email Address',
                field       => 'username',
                type        => 'text',
                required    => 1,
                autofocus   => 1,
            },
            {
                placeholder => 'Password',
                field       => 'password',
                type        => 'password',
                required    => 1,
            },
            {
                placeholder => 'Repo Password (optional)',
                field       => 'repo_pw',
                type        => 'password',
                required    => 0,
            },
        ],
    }
}

sub authenticated {
    # no need to try if there's no token
    return 0 if !defined session SESSION_SF_TOKEN;

    my $seafile = _new;

    my $resp = eval { $seafile->authping };
    if ($@) {
        session SESSION_SF_TOKEN, undef;
        debug $seafile->code, $seafile->error;
    }
    elsif ($resp eq 'pong') {
        return 1;
    }

    return 0;
}

1;
