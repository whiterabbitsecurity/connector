# Tests for Connector::Proxy::Config::Std
#

use strict;
use warnings;
use English;

use Test::More tests => 12;

# diag "LOAD MODULE\n";

BEGIN {
    use_ok( 'Connector::Proxy::Config::Std' );
    use_ok( 'Connector::Multi' ); 
}

require_ok( 'Connector::Proxy::Config::Std' );
require_ok( 'Connector::Multi' );

# diag "Connector::Proxy::Config::Std tests\n";
###########################################################################
my $base = Connector::Proxy::Config::Std->new(
    {
    LOCATION  => 't/config/config.ini',
    PREFIX    => '',
    });

# Test if connector is good
is($base->get('test.entry.foo'), '1234');
is($base->get('test.entry.bar'), '5678');

# Load Multi
my $conn = Connector::Multi->new( {
        BASECONNECTOR => $base,
});

# diag "Test Connector::Mutli is working\n";
# Test if multi is good
is($conn->get('test.entry.foo'), '1234');   
is($conn->get('test.entry.bar'), '5678');

# diag "Test Wrapper\n"; 
my $wrapper = $conn->get_wrapper('test.entry');
is($wrapper->get('foo'), '1234');
is($wrapper->get('bar'), '5678');

# diag "Test Wrapper with Prefix\n";
$base->PREFIX('');
my $wrapper_prefix = $conn->get_wrapper('test.entry');
is($wrapper_prefix->get('foo'), '1234');
is($wrapper_prefix->get('bar'), '5678');

