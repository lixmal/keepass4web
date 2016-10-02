use strict;
use warnings;
use ExtUtils::MakeMaker;
use lib 'lib';

# Normalize version strings like 6.30_02 to 6.3002,
# so that we can do numerical comparisons on it.
my $eumm_version = $ExtUtils::MakeMaker::VERSION;
$eumm_version =~ s/_//;

WriteMakefile(
    NAME                => 'KeePass4Web',
    AUTHOR              => q{Viktor Liu},
    VERSION             => '0.1.0',
    ABSTRACT            => 'KeePass web application',
    ($eumm_version >= 6.3001  ? ('LICENSE'=> 'GPLv3') : ()),
    PL_FILES            => {},

    PREREQ_PM => {
        'Test::More'              => 0,
        'YAML'                    => 0,
        'Dancer'                  => 1.312,
        'Inline'                  => 0,
        'Inline::C'               => 0,
        'Dancer'                  => 0,
        'Dancer::Plugin::Ajax'    => 0,
        'File::KeePass'           => 0,
        'IPC::ShareLite'          => 0,
        'Bytes::Random::Secure'   => 0,
        'JSON'                    => 0,
        'File::KeePass::Web'      => 0,
        'MIME::Base64'            => 0,
        'Crypt::Mode::CBC'        => 0,
        'Time::Duration::Parse'   => 0,
        'Sereal::Encoder'         => 0,
        'Sereal::Decoder'         => 0,
        'File::Type'              => 0,
        'URI::Escape'             => 0,
        'Config'                  => 0,
        'Kernel::Keyring'         => 0,
        'File::KeePass::Web'      => 0,
# optional modules
#        'Crypt::Cipher::AES'      => 0,
#        'Dancer::Session::Cookie' => 0,
#        'Math::Random::ISAAC::XS' => 0,
#        'Plack'                   => 0,
#        'Auth::LDAP'              => 0,
#        'REST::Client'            => 0,
#        'Seafile::Client::REST'   => 0,
#        'LWP::Simple'             => 0,
#        'Net::LDAP'               => 0,
#        'Net::LDAP::Util'         => 0,
#        'Authen::Htpasswd'        => 0,
#        'Crypt::Eksblowfish::Bcrypt' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'KeePass4Web-*' },
);


