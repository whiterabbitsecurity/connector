# Tests for Connector::Builtin::Static
#

use strict;
use warnings;
use English;

use Test::More tests => 7;

# diag "LOAD MODULE\n";

BEGIN {
    use_ok( 'Connector::Builtin::Static' ); 
}

require_ok( 'Connector::Builtin::Static' );


# diag "Connector::Proxy::Static tests\n";
###########################################################################
my $conn = Connector::Builtin::Static->new(
    {
	LOCATION  => '42',
    });

is($conn->get(), '42');
is($conn->get('foo'), '42');
is($conn->get('bar'), '42');
is( $conn->get_meta('bar')->{TYPE}, 'scalar' );
is( $conn->get_meta('bar')->{VALUE}, '42' );


