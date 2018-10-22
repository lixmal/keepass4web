package KeePass4Web::Auth::Test;
use strict;
use warnings;
use parent 'KeePass4Web::Auth::Abstract';

use Dancer2 appname => 'KeePass4Web';

use KeePass4Web::Constant;

sub init {}

sub auth {
    my ($username, $password) = @_;
    die "Login failed\n" if $username ne 'TESTUSER' && $password ne 'TESTPASSWORD';

    session SESSION_KP_DB,      'db.kdbx';
    session SESSION_KP_KEYFILE, 'db.key';

    return {
        CN => [
            'TESTUSER CN',
        ],
    }
}

sub case_sensitive { 1 }

1;
