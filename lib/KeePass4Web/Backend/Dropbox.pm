package KeePass4Web::Backend::Dropbox;
use strict;
use warnings;
use parent 'KeePass4Web::Backend::Abstract';

use Dancer qw/:syntax/;

use WebService::Dropbox;

use KeePass4Web::Constant qw/SESSION_KP_DB SESSION_KP_KEYFILE BAD_REQUEST/;

use constant SESSION_DB_TOKEN => 'dropbox_token';

sub init {}

sub _location {
    my $key_requested = shift;

    # might return undef, no key file available in that case
    return session SESSION_KP_KEYFILE if $key_requested;

    # use location from auth backend if available
    my $db_session = session SESSION_KP_DB;
    return $db_session if $db_session;

    # default is statically configured location
    return config->{Dropbox}->{db_location};
}


sub _new {
    # copy Dropbox config
    my %config = %{config->{Dropbox}};

    my $token = session SESSION_DB_TOKEN;
    # current session token will overwrite configured token
    $config{access_token} = $token if $token;

    my $dropbox = WebService::Dropbox->new(\%config);
    return $dropbox;
}

sub _err {
    my $err = shift->error;
    my $json = eval { from_json $err };
    return $json->{error_summary} if $json->{error_summary};
    return "$json->{error}: $json->{error_description}" if $json;
    return $err;
}

sub _get {
    my ($self, $get_key) = @_;
    my $location = _location $get_key;
    my $db;
    open my $fh, '>', \$db;
    my $dropbox = _new;
    $dropbox->download($location, $fh) or do {
        die _err($dropbox), "\n";
    };
    close $fh;

    return \$db;
}

sub get_key {
    shift->_get(1, @_)
}

sub get_db {
    shift->_get(0, @_)
}

sub put_db {
    my ($self, $db) = @_;
    my $location = _location;

    open my $fh, '<', \$db;
    my $dropbox = _new;
    $dropbox->upload($location, $fh) or do {
        die _err($dropbox), "\n";
    };
    close $fh;

    1
}

sub credentials_init { shift }

sub credentials_tpl { 
    my $uri = _new->authorize(
        {
            redirect_uri => config->{Dropbox}->{redirect_uri},
        }
    );

    debug 'Dropbox uri: ', $uri;

    return {
        type => 'redirect',
        url  => $uri,
    }
}

sub authenticated {
    # no need to try if there's no token
    return 0 if !defined session SESSION_DB_TOKEN and !config->{Dropbox}->{access_token};

    my $dropbox = _new;

    # random request, testing valid token
    my $resp = !!$dropbox->get_space_usage;
    if (!$resp) {
        session SESSION_DB_TOKEN, undef;
        debug 'Dropbox: ', _err $dropbox;
    }
    return $resp;
}

get '/callback' => sub {
    my $code = param 'code' or send_error 'Code parameter missing', BAD_REQUEST;

    my $dropbox = _new;
 
    my $token = $dropbox->token($code, config->{Dropbox}->{redirect_uri});
    if (!$token) {
        error 'Dropbox: ', _err $dropbox;
        send_error 'Failed to fetch token';
    }

    debug  'Dropbox received token';

    session SESSION_DB_TOKEN, delete $token->{access_token};
    info 'Dropbox user info: ', $token;
 
    redirect '/';
};
 

1;
