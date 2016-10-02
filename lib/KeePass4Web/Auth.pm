package KeePass4Web::Auth;
use strict;
use warnings;

use Dancer qw/:syntax/;

# Simple wrapper for backends


return 1 if !config->{auth_backend};

my $type = __PACKAGE__ . '::' . config->{auth_backend};
my $module = $type =~ s/::/\//gr . '.pm';
require $module;

my $auth = $type->new;

if (!$auth->DOES(__PACKAGE__ . '::Abstract')) {
    die "$type does not inherit from " . __PACKAGE__ . '::Abstract';
}
 
# auth attempt with configured backend
# MUST die on error
# MAY return HoA with more info on the authenticated user
sub auth { defined($auth) and $auth->auth(@_) }

1;
