package KeePass4Web::Backend::Filesystem;
use strict;
use warnings;
use parent 'KeePass4Web::Backend::Abstract';

use Dancer qw/:syntax/;

use KeePass4Web::Constant;


sub init {};

sub _location {
    # use location from auth backend if available
    my $session_db = session SESSION_KP_DB;
    return $session_db if $session_db;

    # default is statically configured location
    return config->{Filesystem}->{db_location};
}

sub get_db {
    open my $fh, '<', _location or die $!;
    local $/ = undef;

    my $db = <$fh>;
    close $fh or warn $!;

    return \$db;
}

sub put_db {
    my ($self, $db);
    open my $fh, '>', _location or die $!;

    print $fh $$db or die $!;
    close $fh or warn $!;

    return $self;
}

# we don't want to store any keys on the local machine
sub get_key          { \undef }

# no credentials required
sub credentials_init { shift }
sub credentials_tpl  { }
sub authenticated    { 1 }

1;
