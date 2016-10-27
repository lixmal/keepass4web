use strict;
use warnings;

use KeePass4Web;
use Test::More tests => 2;
use Plack::Test;
use HTTP::Request::Common;

my $app = KeePass4Web->to_app;
is ref $app, 'CODE', 'Got app';

my $test = Plack::Test->create($app);
my $res  = $test->request(GET '/');

ok $res->is_success, '[GET /] successful';
