package KeePass4Web::Test;

BEGIN {
    $ENV{DANCER_ENVDIR}      = 't/env';
    $ENV{DANCER_ENVIRONMENT} = 'test';
}

use HTTP::Request::Common ();
use Plack::Test;
use KeePass4Web;
use KeePass4Web::Auth::Test;

require Exporter;
our @ISA    = qw/Exporter/;
our @EXPORT = qw/
    GET
    POST
    ajax
    csrf_token
/;

BEGIN {
    no warnings 'redefine';
    *KeePass4Web::Auth::auth = \&KeePass4Web::Auth::Test::auth
}

my @ajax = ('X-Requested-With' => 'XMLHttpRequest');
my $host = 'http://localhost';

my $res;
my $cookie;
my $csrf_token;

my $app = KeePass4Web->to_app;
my $test = Plack::Test->create($app);

sub _req {
    my ($method, $url, $params, $ajax) = @_;

    my $req;
    if ($res && $res->header('Set-Cookie') && $res->header('Set-Cookie') =~ /^([^=]+=[^;]+);/) {
        $cookie = $1;
    }
    my @params = $params // ();
    if ($method eq 'POST') {
        $req = HTTP::Request::Common::POST "$host$url", @params, @ajax;
    }
    elsif ($method eq 'GET') {
        $req = HTTP::Request::Common::GET "$host$url", @ajax;
    }
    $req->header('Cookie', $cookie) if $cookie;
    $req->header('X-CSRF-Token', "$csrf_token") if $csrf_token;
    $res = $test->request($req);
    return $res;
}

sub POST { _req 'POST', @_ }
sub GET { _req 'GET', @_ }
sub ajax {
    my $action = shift;
    if ($action) {
        @ajax = ('X-Requested-With' => 'XMLHttpRequest');
    }
    else {
        @ajax = ();
    }
}

sub csrf_token { $csrf_token = shift }

1;
