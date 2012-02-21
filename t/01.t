# Tests for Connector::Proxy::YAML
#

use strict;
use warnings;
use English;

use Test::More tests => 5;

diag "LOAD MODULE\n";

BEGIN {
    use_ok( 'Connector::Proxy::YAML' ); 
}

require_ok( 'Connector::Proxy::YAML' );


diag "Connector::Proxy::YAML tests\n";
###########################################################################
my $yaml_config = Connector::Proxy::YAML->new(
    {
	SOURCE    => 't/config/config.yaml',
	KEY       => 'test',
    });

is($yaml_config->get('foo'), '1234');
is($yaml_config->get('bar'), '5678');

is($yaml_config->get('nonexistent'), undef);


