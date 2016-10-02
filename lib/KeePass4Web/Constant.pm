package KeePass4Web::Constant;
use strict;
use warnings;

use constant BAD_REQUEST        => 400;
use constant UNAUTHORIZED       => 401;
use constant NOT_FOUND          => 404;
use constant MTHD_NOT_ALLOWED   => 405;
use constant NOT_ACCEPTABLE     => 406;
use constant SERVER_ERROR       => 500;

use constant SESSION_KP_DB      => 'kp_db';
use constant SESSION_KP_KEYFILE => 'kp_keyfile';
use constant SESSION_CN         => 'CN';
use constant SESSION_USERNAME   => 'username';

BEGIN {
    require Exporter;
    our @ISA = 'Exporter';
    our @EXPORT = qw/
        BAD_REQUEST
        UNAUTHORIZED
        NOT_FOUND
        MTHD_NOT_ALLOWED
        NOT_ACCEPTABLE
        SERVER_ERROR

        SESSION_KP_DB
        SESSION_KP_KEYFILE
        SESSION_CN
        SESSION_USERNAME
    /;
}

1;
