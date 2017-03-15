use strict;
use warnings;

use KeePass4Web::Test;
use KeePass4Web;
use KeePass4Web::Constant;
use Test::More tests => 23;
use JSON ();
use Dancer2 '!pass';

my $res;

my $app = KeePass4Web->to_app;
is ref $app, 'CODE', 'Got app';
undef $app;

# tests without session
ajax 0;

$res = GET '/';
ok $res->is_success, '/';

$res = POST '/get_tree';
is $res->code, UNAUTHORIZED, '/get_tree';

$res = POST '/get_group';
is $res->code, UNAUTHORIZED, '/get_group';

$res = POST '/get_entry';
is $res->code, UNAUTHORIZED, '/get_entry';

$res = POST '/get_password';
is $res->code, UNAUTHORIZED, '/get_password';

$res = POST '/get_file';
is $res->code, UNAUTHORIZED, '/get_file';

$res = POST '/search_entries';
is $res->code, UNAUTHORIZED, '/search_entries';

$res = GET '/img/icon/0.png';
is $res->code, UNAUTHORIZED, '/img/icon/';

$res = GET '/img/icons/0.png';
ok $res->is_success, '/img/icons/0.png';

$res = POST '/close_db';
is $res->code, UNAUTHORIZED, '/close_db';

$res = POST '/user_login';
is $res->code, NOT_FOUND, '/user_login w/o ajax';

my $backend_dep = config->{auth_backend} ? UNAUTHORIZED : MTHD_NOT_ALLOWED;
ajax 1;
$res = POST '/user_login';
is $res->code, $backend_dep, '/user_login w/o params';

$res = POST '/user_login', [ username => int rand 2*32, password => int rand 2**32 ];
is $res->code, $backend_dep, '/user_login with params';
ajax 0;

$res = POST '/backend_login';
is $res->code, UNAUTHORIZED, '/backend_login';

$res = POST '/db_login';
is $res->code, UNAUTHORIZED, '/db_login';

$res = POST '/logout';
is $res->code, UNAUTHORIZED, '/logout';

$res = POST '/authenticated';
is $res->code, NOT_FOUND, '/authenticated w/o ajax';

ajax 1;
$res = POST '/authenticated';
is $res->code, UNAUTHORIZED, '/authenticated code';
is_deeply decode_json($res->content), {
    success => JSON::false,
    message => {
        user    => 0+!config->{auth_backend},
        backend => 0,
        db      => 0,
    },
}, '/authenticated content';
ajax 0;

$res = POST '/settings';
is $res->code, UNAUTHORIZED, '/settings code';

$res = POST '/csrf_token';
is $res->code, UNAUTHORIZED, '/csrf_token code';

$res = GET '/callback';
is $res->code, NOT_FOUND, '/callback';
