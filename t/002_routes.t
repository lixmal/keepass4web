use strict;
use warnings;

use KeePass4Web ();
use KeePass4Web::Constant;
use Test::More tests => 22;
use Plack::Test;
use HTTP::Request::Common;
use JSON ();
use Dancer2 '!pass';

my $app = KeePass4Web->to_app;
is ref $app, 'CODE', 'Got app';

my $test = Plack::Test->create($app);
my $res;

my @ajax = ('X-Requested-With' => 'XMLHttpRequest');


# tests without session

$res = $test->request(GET '/');
ok $res->is_success, '/';

$res = $test->request(POST '/get_tree');
is $res->code, UNAUTHORIZED, '/get_tree';

$res = $test->request(POST '/get_group');
is $res->code, UNAUTHORIZED, '/get_group';

$res = $test->request(POST '/get_entry');
is $res->code, UNAUTHORIZED, '/get_entry';

$res = $test->request(POST '/get_password');
is $res->code, UNAUTHORIZED, '/get_psasword';

$res = $test->request(POST '/get_file');
is $res->code, UNAUTHORIZED, '/get_file';

$res = $test->request(POST '/search_entries');
is $res->code, UNAUTHORIZED, '/search_entries';

$res = $test->request(GET '/img/icon/0.png');
is $res->code, UNAUTHORIZED, '/img/icon/';

$res = $test->request(POST '/close_db');
is $res->code, UNAUTHORIZED, '/close_db';

$res = $test->request(POST '/user_login');
is $res->code, NOT_FOUND, '/user_login w/o ajax';

my $backend_dep = config->{auth_backend} ? UNAUTHORIZED : MTHD_NOT_ALLOWED;
$res = $test->request(POST '/user_login', @ajax);
is $res->code, $backend_dep, '/user_login w/o params';

$res = $test->request(POST '/user_login', [ username => int rand 2*32, password => int rand 2**32 ], @ajax);
is $res->code, $backend_dep, '/user_login with params';

$res = $test->request(POST '/backend_login');
is $res->code, UNAUTHORIZED, '/backend_login';

$res = $test->request(POST '/db_login');
is $res->code, UNAUTHORIZED, '/db_login';

$res = $test->request(POST '/logout');
is $res->code, UNAUTHORIZED, '/logout';

$res = $test->request(POST '/authenticated');
is $res->code, NOT_FOUND, '/authenticated w/o ajax';

$res = $test->request(POST '/authenticated', @ajax);
is $res->code, UNAUTHORIZED, '/authenticated code';
is_deeply decode_json($res->content), {
    success => JSON::false,
    message => {
        user    => 0+!config->{auth_backend},
        backend => 0,
        db      => 0,
    },
}, '/authenticated content';

$res = $test->request(GET '/settings');
is $res->code, UNAUTHORIZED, '/settings code';

$res = $test->request(GET '/csrf_token');
is $res->code, UNAUTHORIZED, '/csrf_token code';

$res = $test->request(GET '/callback');
is $res->code, NOT_FOUND, '/callback';

