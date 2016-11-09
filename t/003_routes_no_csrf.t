use strict;
use warnings;

use KeePass4Web::Test;
use KeePass4Web::Constant;
use Test::More tests => 19;

my $res;

# tests with session, without csrf token

# login first
$res = POST '/user_login', [ username => 'TESTUSER', password => 'TESTPASSWORD' ];
ok $res->is_success, '/user_login login';

$res = GET '/';
ok $res->is_success, '/';

$res = POST '/get_tree';
is $res->code, FORBIDDEN, '/get_tree';

$res = POST '/get_group';
is $res->code, FORBIDDEN, '/get_group';

$res = POST '/get_entry';
is $res->code, FORBIDDEN, '/get_entry';

$res = POST '/get_password';
is $res->code, FORBIDDEN, '/get_password';

$res = POST '/get_file';
is $res->code, FORBIDDEN, '/get_file';

$res = POST '/search_entries';
is $res->code, FORBIDDEN, '/search_entries';

$res = GET '/img/icon/0.png';
is $res->code, NOT_FOUND, '/img/icon/';

$res = POST '/close_db';
is $res->code, FORBIDDEN, '/close_db';

$res = POST '/user_login';
is $res->code, FORBIDDEN, '/user_login w/o params';

$res = POST '/user_login', [ username => int rand 2*32, password => int rand 2**32 ];
is $res->code, FORBIDDEN, '/user_login with params';

$res = POST '/backend_login';
is $res->code, FORBIDDEN, '/backend_login';

$res = POST '/db_login';
is $res->code, FORBIDDEN, '/db_login';

$res = POST '/logout';
is $res->code, FORBIDDEN, '/logout';

$res = POST '/authenticated';
is $res->code, FORBIDDEN, '/authenticated';

$res = POST '/settings';
is $res->code, FORBIDDEN, '/settings';

$res = POST '/csrf_token';
ok $res->is_success, '/csrf_token';

$res = GET '/callback';
is $res->code, NOT_FOUND, '/callback';
