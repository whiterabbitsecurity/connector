# Base tests for Connector
#

use strict;
use warnings;
use English;
use Data::Dumper;

use Test::More tests => 23;

# diag "LOAD MODULE\n";

BEGIN {
    use_ok( 'Connector' ); 
}

require_ok( 'Connector' );

my $conn = Connector->new(
    {
	LOCATION  => 'n/a',
    });

ok(defined $conn, 'Connector constructor');

#################################################################
# tests for path building
# diag('_build_path tests with empty PREFIX, without arguments');

is($conn->_build_path(), '', '_build_path: no arguments');
is($conn->_build_path(''), '', '_build_path: empty scalar');
is($conn->_build_path([]), '', '_build_path: empty arrayref');
is_deeply( [ $conn->_build_path() ], [], '_build_path in array context: no arguments');
is_deeply( [ $conn->_build_path('') ], [], '_build_path in array context: empty scalar');
is_deeply( [ $conn->_build_path([]) ], [], '_build_path in array context: empty arrayref');

# diag('_build_path tests with empty PREFIX, with arguments');
is($conn->_build_path('foo.bar.baz'), 'foo.bar.baz', '_build_path: string path');
is($conn->_build_path([ 'foo', 'bar', 'baz' ]), 'foo.bar.baz', '_build_path: arrayref');
is_deeply( [ $conn->_build_path('foo.bar.baz') ], [ 'foo', 'bar', 'baz' ], '_build_path in array context: empty scalar');

# diag('_build_path tests with empty PREFIX, with compound arguments');
is($conn->_build_path([ 'foo', 'bar' ], 'baz.bla'), 'foo.bar.baz.bla', '_build_path in scalar context: compound expression');
is_deeply( [ $conn->_build_path([ 'foo', 'bar' ], 'baz.bla') ], [ 'foo', 'bar', 'baz', 'bla' ], '_build_path in array context: compound expression');

# accessor tests
# diag('Accessor tests');
$conn->PREFIX('this.is.a.test');
is($conn->PREFIX(), 'this.is.a.test', 'Accessor: PREFIX');

# diag('Tests with PREFIX');
# building paths with prefix
is($conn->_build_path(), '', '_build_path without arguments');
is($conn->_build_path_with_prefix(), 'this.is.a.test', '_build_path_with_prefix without arguments');

is_deeply( [ $conn->_build_path() ], 
	   [  ], '_build_path: as array');

is_deeply( [ $conn->_build_path_with_prefix() ], 
	   [ 'this', 'is', 'a', 'test' ], '_build_path_with_preifx: as array');

is($conn->_build_path('abc123'), 'abc123', '_build_path: as scalar, with scalar argument');
is($conn->_build_path_with_prefix('abc123'), 'this.is.a.test.abc123', '_build_path: as scalar, with scalar argument');
is($conn->_build_path('abc123.def456'), 'abc123.def456', '_build_path: as scalar, with deep scalar argument');
is($conn->_build_path_with_prefix('abc123.def456'), 'this.is.a.test.abc123.def456', '_build_path: as scalar, with deep scalar argument');

