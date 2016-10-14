package File::KeePass::Web;
use strict;
use warnings;
use parent 'File::KeePass';

use Crypt::URandom;
use Digest::SHA 'sha256';
use MIME::Base64 ();
use Crypt::Mode::CBC;
use Crypt::Rijndael;

our $VERSION = 0.1;

### Differences to File::KeePass ###
# Subclassing of methods to support the following:
# - Use of cryptographically secure RNG
# - Save/load keys and iv outside of the module
# - Configurable cipher for passwords
# - Encryption of password in protected fields
# - Encryption of passwords and protected fields in history
# - Encryption files in entry and history


# TODO: encrypt salsa20 protected stuff after load (decrypt on demand)
# so no unencrypted passwords ever linger in memory after opening of the db (except for viewing)

sub get_crypt {
    my ($cipher) = @_;
    return Crypt::Mode::CBC->new($cipher);
}

sub parse_db {
    my ($self, $buffer, $pass, $args, $cipher, $hist_and_bin) = @_;
    $self = $self->new($args || {}) if !ref $self;
    $buffer = $$buffer if ref $buffer;

    my $head = $self->parse_header($buffer);
    local $head->{raw} = substr $buffer, 0, $head->{header_size} if $head->{version} == 2;
    $buffer = substr $buffer, $head->{header_size};


    my $meth = ($head->{version} == 1) ? '_parse_v1_body'
             : ($head->{version} == 2) ? '_parse_v2_body'
             : die "Unsupported keepass database version ($head->{version})\n";
    (my $meta, $self->{'groups'}) = $self->$meth($buffer, $pass, $head);
    $self->{header} = {%$head, %$meta};
    $self->auto_lock($args->{auto_lock}) if exists $args->{auto_lock};

    my $key;
    $key = $self->lock(undef, $cipher, $hist_and_bin) if $self->auto_lock;
    return $key;
}

sub encrypt_strings {
    my ($crypt, $key, $entry) = @_;
    my $strings = $entry->{strings};
    my $protected = $entry->{protected};
    foreach my $string (keys %$strings) {
        if ($protected->{$string}) {
            my $iv = Crypt::URandom::urandom(16);
            $strings->{$string} = $iv . $crypt->encrypt($strings->{$string}, $$key, $iv);
        }
    }
}

sub encrypt_files {
    my ($crypt, $key, $entry) = @_;
    my $files = $entry->{binary};
    foreach my $file (keys %$files) {
        my $iv = Crypt::URandom::urandom(16);
        $files->{$file} = $iv . $crypt->encrypt($files->{$file}, $$key, $iv);
    }
}

sub lock {
    my ($self, $groups, $cipher, $hist_and_bin) = @_;
    $groups //= $self->groups;

    my $key = Crypt::URandom::urandom(32);
    my $iv  = Crypt::URandom::urandom(16);

    my $crypt = get_crypt($cipher);
    foreach my $e ($self->find_entries({}, $groups)) {
        # encrypt main pw
        $e->{password} //= '';
        $e->{password} = $iv . $crypt->encrypt($e->{password}, $key, $iv);

        # encrypt string pws
        encrypt_strings $crypt, \$key, $e;

        # don't include history and files if requested
        unless ($hist_and_bin) {
            $e->{history} = undef;
            $e->{binary} = undef;
            next;
        }

        # encrypt files
        encrypt_files $crypt, \$key, $e;

        # encrypt all history pws, so we don't leak any data
        foreach my $hist_e (@{$e->{history}}) {
            # encrypt history main pw
            $hist_e->{password} //= '';
            $iv = Crypt::URandom::urandom(16);
            $hist_e->{password} = $iv . $crypt->encrypt($hist_e->{password}, $key, $iv);

            # encrypt history string pws
            encrypt_strings $crypt, \$key, $hist_e;

            # encrypt history string pws
            encrypt_files $crypt, \$key, $hist_e;
        }
    }

    return \$key;
}

sub unlock {
    my ($self, $key, $groups, $cipher) = @_;
    $groups //= $self->groups;

    foreach my $e ($self->find_entries({}, $groups)) {
        my ($iv, $ciphertext) = unpack 'a16a*', $e->{password};
        my $crypt = get_crypt($key, \$iv, $cipher);
        $e->{password} = $crypt->decrypt($ciphertext);
        foreach my $key (keys %{$e->{strings}}) {
            ($iv, $ciphertext) = unpack 'a16a*', $e->{strings}->{$key};
            $crypt->iv($iv);
            $e->{strings}->{$key} = $crypt->decrypt($ciphertext) if $e->{protected}->{$key};
        }
    }
    return 1;
}

sub locked_entry_password {
    my ($self, $entry, $name, $key, $cipher) = @_;
    $entry = $self->find_entry({id => $entry}) if !ref $entry;
    return if !$entry;
    my $pass;
    if (!defined $name || $name eq 'password') {
        my ($iv, $ciphertext) = unpack 'a16a*', $entry->{password};
        $pass = \get_crypt($key, \$iv, $cipher)->decrypt($ciphertext);
    }
    else {
        my ($iv, $ciphertext) = unpack 'a16a*', $entry->{strings}->{$name};
        $pass = \get_crypt($key, \$iv, $cipher)->decrypt($ciphertext) if $entry->{protected}->{$name};
    }
    $entry->{accessed} = $self->now;

    # returning a reference to avoid copying the password around in memory
    return $pass;
}

sub _master_key {
    my ($self, $pass, $head) = @_;
    my $file;
    ($pass, $file) = @$pass if ref($pass) eq 'ARRAY';
    $pass = sha256($pass) if defined($pass) && length($pass);
    if ($file) {
        $file = ref($file) ? $$file : $self->slurp($file);
        if (length($file) == 64) {
            $file = join '', map {chr hex} ($file =~ /\G([a-f0-9A-F]{2})/g);
        } elsif (length($file) != 32) {
            $file = sha256($file);
        }
    }
    my $key = (!$pass && !$file) ? die "One or both of password or key file must be passed\n"
            : ($head->{'version'} && $head->{'version'} eq '2') ? sha256(grep {$_} $pass, $file)
            : ($pass && $file) ? sha256($pass, $file) : $pass ? $pass : $file;
    $head->{'enc_iv'}     ||= Crypt::URandom::urandom(16);
    $head->{'seed_rand'}  ||= Crypt::URandom::urandom($head->{'version'} && $head->{'version'} eq '2' ? 32 : 16);
    $head->{'seed_key'}   ||= sha256 Crypt::URandom::urandom(32);
    #$head->{'seed_key'}   ||= sha256 time.rand(2**32-1).$$;
    $head->{'rounds'} ||= $self->{'rounds'} || ($head->{'version'} && $head->{'version'} eq '2' ? 6_000 : 50_000);

    my $cipher = Crypt::Rijndael->new($head->{'seed_key'}, Crypt::Rijndael::MODE_ECB());
    $key = $cipher->encrypt($key) for 1 .. $head->{'rounds'};
    $key = sha256 $key;
    $key = sha256 $head->{'seed_rand'}, $key;
    return $key;
}


sub clear {
    my $self = shift;
    delete @$self{qw(header groups)};
}

sub decode_base64 {
    my ($self, $content) = @_;
    return MIME::Base64::decode_base64($content);
}

sub encode_base64 {
    my ($self, $content) = @_;
    ($content = MIME::Base64::encode_base64($content)) =~ s/\n//g;
    return $content;
}


1;
