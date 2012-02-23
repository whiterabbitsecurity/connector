# Base tests for Connector
#

use strict;
use warnings;
use English;
use Data::Dumper;

use Test::More tests => 2;

diag "LOAD MODULE\n";

BEGIN {
    use_ok( 'Connector' ); 
}

require_ok( 'Connector' );

my $conn = Connector->new(
    {
	LOCATION  => 'n/a',
	PREFIX    => 'this.is.a.test',
    });

ok(defined $conn);

my $prefix = $conn->PREFIX();
my @prefix = $conn->PREFIX();
print Dumper $prefix;
print Dumper \@prefix;

my $path = $conn->_build_path('foo.bar');
my @path = $conn->_build_path('foo.bar');
print Dumper $path;
print Dumper \@path;
