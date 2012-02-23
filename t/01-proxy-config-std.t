# Tests for Connector::Proxy::Config::Std
#

use strict;
use warnings;
use English;

use Test::More tests => 5;

diag "LOAD MODULE\n";

BEGIN {
    use_ok( 'Connector::Proxy::Config::Std' ); 
}

require_ok( 'Connector::Proxy::Config::Std' );


diag "Connector::Proxy::Config::Std tests\n";
###########################################################################
my $yaml_config = Connector::Proxy::Config::Std->new(
    {
	SOURCE    => 't/config/config.ini',
	KEY       => 'test',
    });

is($yaml_config->get('foo'), '1234');
is($yaml_config->get('bar'), '5678');

is($yaml_config->get('nonexistent'), undef);


