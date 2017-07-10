package File::KeePass::Web;
use strict;
use warnings;
use parent 'File::KeePass';

use Crypt::URandom;
use Digest::SHA 'sha256';
use MIME::Base64 ();
use Crypt::Mode::CBC;
use Crypt::Rijndael;
use Crypt::Mac::HMAC 'hmac';
use Encode ();

use constant PASSWORD         => '0';
use constant HISTORY_PASSWORD => '1';
use constant FILE             => '2';
use constant STRING           => '3';
use constant IV_SIZE          => 16;
use constant KEY_SIZE         => 32;


our $VERSION = '0.2.0';

### Differences to File::KeePass ###
# Subclassing of methods to support the following:
# - Use of cryptographically secure RNG
# - Save/load keys and iv outside of the module
# - Configurable cipher for passwords
# - Encryption of password in protected fields
# - Encryption of passwords and protected fields in history
# - Encryption of files in entry and history


# TODO: encrypt salsa20 protected stuff after load (decrypt on demand)
# so no unencrypted passwords ever linger in memory after opening of the db (except for viewing)

sub get_crypt {
    my ($enc_cipher, $mac_cipher, $enc_key, $mac_key) = @_;

    my $crypt = Crypt::Mode::CBC->new($enc_cipher);
    return sub {
        my ($plaintext, @adata) = @_;

        my $iv = Crypt::URandom::urandom(IV_SIZE);

        my $ciphertext = $crypt->encrypt($plaintext, $$enc_key, $iv);
        my $mac = hmac $mac_cipher, $$mac_key, $iv, $ciphertext, map { Encode::encode 'UTF-8', $_ } @adata;

        return $iv . $mac . $ciphertext;
    }
}

sub parse_db {
    my ($self, $buffer, $pass, $args, $enc_cipher, $mac_cipher, $hist_and_bin) = @_;
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

    my ($enc_key, $mac_key);
    ($enc_key, $mac_key) = $self->lock(undef, $enc_cipher, $mac_cipher, $hist_and_bin) if $self->auto_lock;
    return $enc_key, $mac_key;
}

sub encrypt_strings {
    my ($crypt, $entry) = @_;
    my $strings = $entry->{strings};
    my $protected = $entry->{protected};
    foreach my $string (keys %$strings) {
        if ($protected->{$string}) {
            $strings->{$string} = $crypt->($strings->{$string}, STRING . " $string");
        }
    }
}

sub encrypt_files {
    my ($crypt, $entry) = @_;
    my $files = $entry->{binary};
    foreach my $filename (keys %$files) {
        $files->{$filename} = $crypt->($files->{$filename}, FILE . " $filename");
    }
}

sub lock {
    my ($self, $groups, $enc_cipher, $mac_cipher, $hist_and_bin) = @_;
    $groups //= $self->groups;

    my $enc_key = Crypt::URandom::urandom(KEY_SIZE);
    my $mac_key = Crypt::URandom::urandom(KEY_SIZE);

    my $crypt = get_crypt $enc_cipher, $mac_cipher, \$enc_key, \$mac_key;

    foreach my $e ($self->find_entries({}, $groups)) {
        # encrypt main pw
        $e->{password} //= '';
        $e->{password} = $crypt->($e->{password}, PASSWORD);

        # encrypt string pws
        encrypt_strings $crypt, $e;

        # don't include history and files if requested
        unless ($hist_and_bin) {
            $e->{history} = undef;
            $e->{binary} = undef;
            next;
        }

        # encrypt files
        encrypt_files $crypt, $e;

        # encrypt all history pws, so we don't leak any data
        foreach my $hist_e (@{$e->{history}}) {
            # encrypt history main pw
            $hist_e->{password} //= '';
            # TODO: use unique string per history entry
            $hist_e->{password} = $crypt->($hist_e->{password}, PASSWORD);

            # encrypt history string pws
            encrypt_strings $crypt, $hist_e;

            # encrypt history files
            encrypt_files $crypt, $hist_e;
        }
    }

    return \$enc_key, \$mac_key;
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
    $head->{'enc_iv'}     ||= Crypt::URandom::urandom(IV_SIZE);
    $head->{'seed_rand'}  ||= Crypt::URandom::urandom($head->{'version'} && $head->{'version'} eq '2' ? 32 : 16);
    $head->{'seed_key'}   ||= Crypt::URandom::urandom(KEY_SIZE);
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
