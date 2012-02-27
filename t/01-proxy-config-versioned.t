# Tests for Connector::Proxy::Config::Versioned
#

use strict;
use warnings;
use English;

use Test::More tests => 4;

diag "LOAD MODULE\n";

BEGIN {
    use_ok( 'Connector::Proxy::Config::Versioned' ); 
}

require_ok( 'Connector::Proxy::Config::Versioned' );


diag "Connector::Proxy::Config::Versioned tests\n";
###########################################################################
my $conn = Connector::Proxy::Config::Versioned->new(
    {
	LOCATION  => 't/config/config.git',
	PREFIX    => '',
    });

# is($conn->get('foo'), 'bar');
# is($conn->get('nonexistent'), undef);


