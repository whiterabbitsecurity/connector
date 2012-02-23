# Tests for Connector::Proxy::File::Simple
#

use strict;
use warnings;
use English;

use Test::More tests => 4;

diag "LOAD MODULE\n";

BEGIN {
    use_ok( 'Connector::Proxy::File::Simple' ); 
}

require_ok( 'Connector::Proxy::File::Simple' );


diag "Connector::Proxy::File::Simple tests\n";
###########################################################################
my $conn = Connector::Proxy::File::Simple->new(
    {
	LOCATION  => '',
	PREFIX    => 't/config',
    });

is($conn->get('file'), 'test');
is($conn->get('nonexistent'), undef);


