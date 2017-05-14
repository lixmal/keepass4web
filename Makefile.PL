use strict;
use warnings;
use ExtUtils::MakeMaker;

# Normalize version strings like 6.30_02 to 6.3002,
# so that we can do numerical comparisons on it.
my $eumm_version = $ExtUtils::MakeMaker::VERSION;
$eumm_version =~ s/_//;

WriteMakefile(
    NAME                => 'KeePass4Web',
    AUTHOR              => q{Viktor Liu},
    VERSION             => '0.6.2',
    ABSTRACT            => 'KeePass web application',
    ($eumm_version >= 6.3001  ? ('LICENSE'=> 'gpl_3') : ()),
    PL_FILES            => {},

    PREREQ_PM => {
        'Test::More'              => 0,
        'Plack::Test'             => 0,
        'Dancer2'                 => 0,
        'Dancer2::Plugin::Ajax'   => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'KeePass4Web-*' },
);


