# Tests for Connector::Builtin::Static
#

use strict;
use warnings;
use English;

use Test::More tests => 7;

# diag "LOAD MODULE\n";

BEGIN {
    use_ok( 'Connector::Builtin::Memory' ); 
}

require_ok( 'Connector::Builtin::Memory' );


# diag "Connector::Proxy::Static tests\n";
###########################################################################
my $conn = Connector::Builtin::Memory->new(
    {	
    });


$conn->set('bar', '1234');
$conn->set('foo', '4567');

$conn->set('use.hash', { foo => 1, bar => 2});
$conn->set('use.list', [ 'foo','bar' ] );

is( $conn->get('bar'), '1234');
is( $conn->get('foo'), '4567');

is( $conn->get_meta('use.hash')->{TYPE}, 'hash' );
is( $conn->get_meta('use.list')->{TYPE}, 'list' );
is_deeply( [ $conn->get_list('use.list') ], [ 'foo','bar' ] );






