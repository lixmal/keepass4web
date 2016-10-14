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
    VERSION             => '0.2.1',
    ABSTRACT            => 'KeePass web application',
    ($eumm_version >= 6.3001  ? ('LICENSE'=> 'gpl_3') : ()),
    PL_FILES            => {},

    PREREQ_PM => {
        'Test::More'              => 0,
        'YAML'                    => 0,
        'Inline::C'               => 0,
        'Dancer2'                 => 0,
        'Dancer2::Plugin::Ajax'   => 0,
        'File::KeePass'           => 0,
        'IPC::ShareLite'          => 0,
        'Crypt::URandom'          => 0,
        'Math::Random::ISAAC::XS' => 0,
        'JSON'                    => 0,
        'MIME::Base64'            => 0,
        'Crypt::Mode::CBC'        => 0,
        'Sereal::Encoder'         => 0,
        'Sereal::Decoder'         => 0,
        'File::LibMagic'          => 1.07,
        'URI::Escape'             => 0,
        'Config'                  => 0,

        'Kernel::Keyring'         => 0,
        'File::KeePass::Web'      => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'KeePass4Web-*' },
);


