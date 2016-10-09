package KeePass4Web::Backend::HTTP;
use strict;
use warnings;
use parent 'KeePass4Web::Backend::Abstract';

use Dancer qw/:syntax/;
use LWP::UserAgent ();
use HTTP::Request::Common qw/GET POST/;
use Encode ();

use KeePass4Web::Constant qw/SESSION_KP_DB SESSION_KP_KEYFILE/;

BEGIN {
    if (config->{HTTP}->{upload}->{use_rfc5987}) {
        require URI::Escape;
    }
}


sub init {}

sub _location {
    my $key_requested = shift;

    # might return undef, no key file available in that case
    return session SESSION_KP_KEYFILE if $key_requested;

    # use location from auth backend if available
    my $db_session = session SESSION_KP_DB;
    return $db_session if $db_session;

    # default is statically configured location
    return config->{HTTP}->{db_location};
}

# TODO:  add explicit proxy setting
sub _get {
    my ($self, $get_key) = @_;

    my $ua = LWP::UserAgent->new(%{config->{HTTP}->{lwp_options}});

    my $location = _location $get_key;
    debug 'HTTP location: ', $location;

    die "Invalid backend location\n" if !$location;

    my $request = GET $location;


    my $password = config->{HTTP}->{password};
    if (defined $password) {
        $request->authorization_basic(config->{HTTP}->{username} || '', $password);
    }

    my $response = $ua->request($request);
    if ($response->is_success) {
        return \$response->decoded_content;
    }

    error $response->status_line;
    die $response->message, "\n";
}

sub get_key {
    shift->_get(1, @_)
}

sub get_db {
    shift->_get(0, @_)
}

sub put_db {
    my ($self, $db) = @_;

    my $config = config->{HTTP};
    my $ua = LWP::UserAgent->new(%{$config->{lwp_options}});

    my $location = _location;
    debug 'HTTP location: ', $location;

    die "Invalid backend location\n" if !$location;

    # extract filename
    ($location, my $filename) = $location =~ /^(.+\/)([^\/]+)$/;


    my @headers = $config->{upload}->{use_rfc5987} ?
        ('Content-Disposition' => "form-data; name=\"$config->{upload}->{fieldname}\"; filename*=UTF-8''" . URI::Escape::uri_escape_utf8($filename))
        : ()
    ;

    my $request = POST $location,
        Content_Type => 'form-data',
        Content => [
            $config->{upload}->{fieldname} => [
                undef,
                Encode::encode_utf8($filename),
                'Content-Type' => 'application/octet-stream',
                @headers,
                # FIXME: might not work very well with big files
                Content => $$db,
            ]
        ];

    my $password = $config->{password};
    if (defined $password) {
        $request->authorization_basic($config->{username} || '', $password);
    }

    my $response = $ua->request($request);
    if ($response->is_error) {
        error $response->status_line;
        die $response->message, "\n";
    }

    return 1;
}

sub credentials_init { shift }

sub credentials_tpl { undef }
sub authenticated { 1 }

1;
