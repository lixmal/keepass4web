package Auth::LDAP;
use strict;
use warnings;
use Net::LDAP ();
use Net::LDAP::Util ();

use constant LDAP_VERSION => 3;

our $VERSION = 0.2;

sub new {
    my ($class, %args) = @_;
    my @required = qw/
        server
        base_dn
        filter
        login_attr
    /;

    foreach my $arg (@required) {
        die "Missing parameter: $arg" if !defined $args{$arg};
    }

    push @{$args{attributes}}, $args{login_attr};

    return bless \%args, $class;
}


sub _err {
    my ($self, $msg, $op) = @_;

    $self->{error} = $op ? $op->error : $msg;
    $self->{error} = $msg if $self->{error} eq 'Success';
    my $ldap = delete $self->{_ldap};
    $ldap->disconnect if ref $ldap eq 'Net::LDAP';
    die $msg, "\n";
}

sub _bind {
    my $self = shift;


    my $ldap = Net::LDAP->new(
        $self->{server},
        async   => 0,
        version => LDAP_VERSION,
    ) or $self->_err('Connection to server failed');


    # bind as readonly user
    my $username = $self->{username};
    my $op;
    if (defined $username && $username ne '') {
        $op = $ldap->bind($username, password => $self->{password});
    }
    else {
        $op = $ldap->bind;
    }
    $self->_err('Binding to server failed', $op) if !$op || $op->is_error;

    return $self->{_ldap} = $ldap;
}

sub error {
    return shift->{error}
}
 
sub auth {
    my ($self, $username, $password) = @_;

    $self->_err('No credentials supplied') if !defined $username || !defined $password;

    $username = Net::LDAP::Util::escape_filter_value($username);
    my $login_attr = Net::LDAP::Util::escape_filter_value($self->{login_attr});

    my $ldap = $self->_bind;


    # find user dn
    my $user;
    my $result;
    eval {
        $result = $ldap->search(
            base   => $self->{base_dn},
            filter => "(&($login_attr=$username)$self->{filter})",
            attrs  => $self->{attributes},
            scope  => $self->{scope},
        );
        $user = $result->entry(0);
    };
    # no user found will result in 'Success' msg in $self->{error}
    $self->_err('Lookup failed', $result) if $@ || !$result || $result->is_error || !$user;
    my $dn = $user->dn;

    # check if we can bind as requested user
    my $op = $ldap->bind($dn, password => $password);
    $self->_err('Login failed', $op) if !$op || $op->is_error;

    $ldap->disconnect;

    return { map { $_ => [ $user->get_value($_) ] } @{$self->{attributes}} }
}

# returns all users found by the filter
sub users {
    my $self = shift;

    my $ldap = $self->_bind;

    my $result;
    
    eval {
        $result = $ldap->search(
            base   => $self->{base_dn},
            filter => $self->{filter},
            attrs  => [ $self->{login_attr} ],
        )
    };
    $self->_err('Lookup failed', $result) if $@ || !$result || $result->is_error;

    $ldap->disconnect;

    return [ map { scalar $_->get_value($self->{login_attr}) } $result->entries ];
}

1;
