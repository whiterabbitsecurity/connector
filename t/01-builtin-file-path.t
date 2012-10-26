# Tests for Connector::Builtin::File::Path
#

use strict;
use warnings;
use English;

use Test::More tests => 15;

diag "LOAD MODULE\n";

Log::Log4perl->easy_init( { level   => 'DEBUG' } );

BEGIN {
    use_ok( 'Connector::Builtin::File::Path' ); 
}

require_ok( 'Connector::Builtin::File::Path' );


diag "Connector::Proxy::File::Path tests\n";
###########################################################################
my $conn = Connector::Builtin::File::Path->new(
    {
	LOCATION  => 't/config/',
    });

ok($conn->set('test.txt', 'Hello'),'write file');
is($conn->get('test.txt'), 'Hello');

$conn->file('[% ARGS %].txt');
diag "Use dynamic filename";
ok($conn->set('test', 'Hello Alice'),'write file');
ok(-f 't/config/test.txt', 'file exists');
is($conn->get('test'), 'Hello Alice');


$conn->content("[% HELLO %] - [% NAME %]\n");
diag "Use dynamic content";
ok($conn->set('test', { HELLO => 'Hello', NAME => 'Alice'}),'write file');
is($conn->get('test'), "Hello - Alice\n");

diag "Append";
$conn->ifexists('append');
ok($conn->set('test', { HELLO => 'Hello', NAME => 'Bob'}),'write file');
is($conn->get('test'), "Hello - Alice\nHello - Bob\n");

diag "Fail on Exist";
$conn->ifexists('fail');
eval {
    $conn->set('test', 'wont see');
};
like($EVAL_ERROR,"/File .* exists/",'die on overwrite');
is($conn->get('test'), "Hello - Alice\nHello - Bob\n");

diag "Silent Fail";
$conn->ifexists('silent');
eval {
    $conn->set('test', 'wont see');
};
is( $EVAL_ERROR, '', 'silent fail');
is($conn->get('test'), "Hello - Alice\nHello - Bob\n");
