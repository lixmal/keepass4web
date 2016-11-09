use strict;
use warnings;

use KeePass4Web::Test;
use KeePass4Web::Constant;
use Test::More tests => 6;
use JSON ();
use Dancer2 '!pass';
use MIME::Base64 qw/decode_base64/;

my $res;

# tests with session, with csrf token

# login first
$res = POST '/user_login', [ username => 'TESTUSER', password => 'TESTPASSWORD' ];
ok $res->is_success, '/user_login login';

my $data = decode_json($res->content)->{data};
my $token = $data->{csrf_token};
csrf_token $token;

is length decode_base64($token), CSRF_TOKEN_LENGTH, 'csrf token';

is $data->{cn}, 'TESTUSER CN', 'cn';

ok !ref $data->{credentials_tpl} || ref $data->{credentials_tpl} eq 'HASH', 'credentials tpl';

my $type = $data->{credentials_tpl}->{type};
ok !defined $type || $type =~ /^(?:redirect|mask)$/, 'credentials tpl type';


$res = GET '/';
ok $res->is_success, '/';
