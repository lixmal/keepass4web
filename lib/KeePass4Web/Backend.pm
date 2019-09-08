package KeePass4Web::Backend;
use strict;
use warnings;

use Dancer2 appname => 'KeePass4Web';

# Simple wrapper for backends

my $name = config->{db_backend};
die "No db backend configured\n" if !defined $name || $name eq '';

my $type = __PACKAGE__ . "::$name";
(my $module = $type) =~ s/::/\//g;
require $module . '.pm';

my $backend = $type->new;

if (!$backend->DOES(__PACKAGE__ . '::Abstract')) {
    die "$type does not inherit from " . __PACKAGE__ . '::Abstract';
}

# returns KeePass database from configured backend as ref to scalar
# MUST die on error
sub get_db { defined($backend) and $backend->get_db(@_) }

# returns KeePass keyfile from configured backend as ref to scalar
# MUST die on error
# MUST return ref to undef if not implemented
sub get_key { defined($backend) and $backend->get_key(@_) }

# writes database to configured backend, parameter: ref to scalar
# MUST die on error
sub put_db { defined($backend) and $backend->put_db(@_) }

# backend login attempt, saving tokens to session, ...
# receives arguments from webclient
# MUST die on login error
# SHOULD return $self
sub credentials_init { defined($backend) and $backend->credentials_init(@_) }

# should return undef when no credentials for that backend are needed
# return ref to AoH if user input for credentials required
sub credentials_tpl { defined($backend) and $backend->credentials_tpl(@_) }

# checks if backend is authenticated
sub authenticated { defined($backend) and $backend->authenticated(@_) }

1;
