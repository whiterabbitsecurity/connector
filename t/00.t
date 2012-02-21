# Base tests for Connector
#

use strict;
use warnings;
use English;

use Test::More tests => 2;

diag "LOAD MODULE\n";

BEGIN {
    use_ok( 'Connector' ); 
}

require_ok( 'Connector' );

