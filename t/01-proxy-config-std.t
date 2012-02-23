# Tests for Connector::Proxy::Config::Std
#

use strict;
use warnings;
use English;

use Test::More tests => 8;

diag "LOAD MODULE\n";

BEGIN {
    use_ok( 'Connector::Proxy::Config::Std' ); 
}

require_ok( 'Connector::Proxy::Config::Std' );


diag "Connector::Proxy::Config::Std tests\n";
###########################################################################
my $conn = Connector::Proxy::Config::Std->new(
    {
	LOCATION  => 't/config/config.ini',
	PREFIX    => 'test',
    });

is($conn->get('abc'), '1111');
is($conn->get('def'), '2222');

is($conn->get('nonexistent'), undef);

# try full path access
is($conn->PREFIX(''), '');

# and repeat above tests
is($conn->get('test.entry.foo'), '1234');
is($conn->get('test.entry.bar'), '5678');

