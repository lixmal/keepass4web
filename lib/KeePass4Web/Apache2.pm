package KeePass4Web::Apache2;

BEGIN {
    $ENV{PERL_INLINE_DIRECTORY} = $ENV{KP_APPDIR};
}

use Apache2::Const -compile => 'OK';
use Kernel::Keyring;

sub post_config {
    eval { key_session 'KeePass4Web' };

    return Apache2::Const::OK;
}

1;
