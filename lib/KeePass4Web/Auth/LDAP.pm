package KeePass4Web::Auth::LDAP;
use strict;
use warnings;
use parent 'KeePass4Web::Auth::Abstract';

use Dancer ':syntax';

use KeePass4Web::Constant;
use Auth::LDAP;

sub init {}

sub auth {
    my ($self, $username, $password) = @_;

    my $ldap = Auth::LDAP->new(
        server     => config->{LDAP}->{uri},
        scope      => config->{LDAP}->{scope},
        username   => config->{LDAP}->{bind},
        password   => config->{LDAP}->{password},
        login_attr => config->{LDAP}->{login_attribute},
        base_dn    => config->{LDAP}->{base_dn},
        filter     => config->{LDAP}->{filter},
        attributes => [
            'CN',
            # insert emtpy list if undef
            config->{LDAP}->{database_attribute} || (),
            config->{LDAP}->{keyfile_attribute}  || (),
        ],
    );
    my $user = eval {
        $ldap->auth($username, $password);
    };
    if ($@) {
        # error msg to be seen by user
        my $err = $@;

        # verbose error
        info "LDAP login error for $username: ", $ldap->error;

        # no need to use trailing newline, Auth::LDAP does that job
        die $err;
    }
    

    # set db and keyfile location for session, if configured in auth backend
    my $db_attr      = config->{LDAP}->{database_attribute};
    my $keyfile_attr = config->{LDAP}->{keyfile_attribute};
    # only take first returned attribute
    session SESSION_KP_DB,      eval { $user->{$db_attr}->[0] }      if $db_attr;
    session SESSION_KP_KEYFILE, eval { $user->{$keyfile_attr}->[0] } if $keyfile_attr;

    return $user;
}

1;
