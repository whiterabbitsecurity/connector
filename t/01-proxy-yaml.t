# Tests for Connector::Proxy::YAML
#

use strict;
use warnings;
use English;

use Test::More tests => 17;

diag "LOAD MODULE\n";

BEGIN {
    use_ok( 'Connector::Proxy::YAML' ); 
}

require_ok( 'Connector::Proxy::YAML' );


diag "Connector::Proxy::YAML tests\n";
###########################################################################
my $conn = Connector::Proxy::YAML->new(
    {
	LOCATION  => 't/config/config.yaml',
	PREFIX    => 'test.entry',	
    });

is($conn->get('foo'), '1234');
is($conn->get('bar'), '5678');


is($conn->get('nonexistent'), undef);

# try full path access
diag('Tests without PREFIX');
$conn->PREFIX(undef);
is($conn->PREFIX(), undef, 'Accessor test');

# and repeat above tests
is($conn->get('test.entry.foo'), '1234');
is($conn->get('test.entry.bar'), '5678');

# test with array ref path
is($conn->get( [ 'test.entry.foo' ] ), '1234');
is($conn->get( [ 'test.entry','bar' ] ), '5678');

# check for completely wrong entry
is($conn->get('test1.entry.bar'), undef, 'handle completely wrong entry gracefully');

diag "Test List functionality\n";
is( $conn->get_size('list.test'), 4, 'Check size of list');
is( ref $conn->get_list('list.test'), 'ARRAY', 'Check if return is array ref');
is( $conn->get_list('list.test')->[0], 'first', 'Check element');

diag "Test Hash functionality\n";
is( ref $conn->get_keys('test.entry'), 'ARRAY', 'Check if get_keys is array ');
is( ref $conn->get_hash('test.entry'), 'HASH', 'Check if get_hash is hash');
is( $conn->get_hash('test.entry')->{bar}, '5678', 'Check element');


 


