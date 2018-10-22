package KeePass4Web::Auth::Htpasswd;
use strict;
use warnings;
use parent 'KeePass4Web::Auth::Abstract';

use Dancer2 appname => 'KeePass4Web';

use KeePass4Web::Constant;
use KeePass4Web::KeePass;

sub BEGIN {
    my $hash_algo = config->{Htpasswd}->{hash};

    if ($hash_algo eq 'bcrypt') {
        require Crypt::Eksblowfish::Bcrypt;
    }
    else {
        require Authen::Htpasswd;
        require Authen::Htpasswd::Util;
    }
}


sub init {}

sub _bcrypt {
    my ($path, $username, $password) = @_;

    my ($user, $pwhash, $storedhash);

    open my $fh, '<' , $path or die $!;
    my @lines = <$fh>;
    close $fh or warning $!;

    # timing attacks might still reveal valid usernames
    foreach my $line (@lines) {
        # colon not allowed in username, so shouldn't be an issue
        if (($user, $storedhash) = $line =~ /^(\Q$username\E):(\$.*)/) {
            last;
        }
    }
    die "User not found\n" if !defined $user;

    return if !$storedhash;

    # need to parse this manually, because Crypt::Eksblowfish::Bcrypt::bcrypt takes 'a2' bcrypt versions only
    if (my ($id, $rounds, $salt, $hash) = $storedhash =~ /^
        \$
        (2[axyb]?)
        \$
        (\d{2})
        \$
        ([.\/A-Za-z0-9]{22})
        ([.\/A-Za-z0-9]{31})
    /x) {
        $pwhash = Crypt::Eksblowfish::Bcrypt::en_base64(
            Crypt::Eksblowfish::Bcrypt::bcrypt_hash({
                cost    => $rounds,
                salt    => Crypt::Eksblowfish::Bcrypt::de_base64($salt),
                key_nul => 1,
            }, $password)
        ) or die "Failed to generate hash for supplied password\n";

        $storedhash = $hash;
    }
    else {
        die "Invalid bcrypt string\n";
    }

    return ($pwhash, $storedhash);
}

sub _other {
    my ($path, $username, $password, $hash_algo) = @_;

    my ($pwhash, $storedhash);

    my $ht = Authen::Htpasswd->new(
        $path,
        { encrypt_hash => $hash_algo }
    );
    my $user = $ht->lookup_user($username);

    $storedhash = $user->hashed_password;
    $pwhash = Authen::Htpasswd::Util::htpasswd_encrypt($hash_algo, $password, $storedhash);

    return ($pwhash, $storedhash);
}

sub auth {
    my ($self, $username, $password) = @_;
    my $hash_algo = config->{Htpasswd}->{hash};
    my $path = config->{Htpasswd}->{filepath};

    my $pwhash;
    my $storedhash;

    if ($hash_algo eq 'bcrypt') {
        ($pwhash, $storedhash) = _bcrypt $path, $username, $password;
    }
    else {
        ($pwhash, $storedhash) = _other $path, $username, $password, $hash_algo;
    }


    die "Failed to generate hash for supplied password\n" if !defined $pwhash;
    die "Failed to get stored hash\n" if !defined $storedhash;

    die "Passwords do not match\n" if !KeePass4Web::KeePass::equal $pwhash, $storedhash;

    return 1;
}

sub case_sensitive { 1 }

1;
