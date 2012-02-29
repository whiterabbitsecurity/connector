# Tests for Connector::Proxy::Proc::SafeExec
#

use strict;
use warnings;
use English;
use Try::Tiny;

use Test::More tests => 14;

diag "LOAD MODULE\n";

our $req_err;
BEGIN {
    eval 'require Proc::SafeExec;';
    our $req_err = $@;

    use_ok( 'Connector::Proxy::Proc::SafeExec' ); 
}

require_ok( 'Connector::Proxy::Proc::SafeExec' );


diag "Connector::Proxy::Proc::SafeExec\n";
###########################################################################
my $conn = Connector::Proxy::Proc::SafeExec->new(
    {
	LOCATION  => 't/config/test.sh',
	args => [ 'foo' ],
	timeout => 2,
    });

ok(defined $conn);

SKIP: {
    skip "Proc::SafeExec not installed", 12 if $req_err;

    is($conn->get(), 'foo', 'Simple invocation');

    $conn->args( [ '--quote-character', '**', 'foo' ] );
    is($conn->get(), '**foo**', 'Multiple arguments and options');

    my $exception;
    $conn->args( [ '--exit-with-error', '1' ] );

    undef $exception;
    try {
	$conn->get();
    } catch {
	$exception = $_;
    };
    like($exception, qr/^System command exited with return code/, 'Error code handling');

    $conn->args( [ '--sleep', '1', 'foo' ] );
    is($conn->get(), 'foo', 'Timeout: not triggered');

    $conn->args( [ '--sleep', '3', 'foo' ] );
    undef $exception;
    try {
	$conn->get();
    } catch {
	$exception = $_;
    };
    like($exception, qr/^System command timed out/, 'Timeout: triggered');

    ####
    # argument passing tests
    $conn->args( [ 'abc[% ARG.0 %]123' ] );
    is($conn->get('foo'), 'abcfoo123', 'Passing parameters from get arguments');

    $conn->args( [ 'abc[% ARG.0 %]123[% ARG.1 %]xyz' ] );
    is($conn->get('foo', 'bar'), 'abcfoo123barxyz', 'Multiple parameters from get arguments');

    ###
    # stdin tests
    $conn->stdin('54321');
    $conn->args( [ '--' ] );
    is($conn->get('foo'), '54321', 'Passing scalar data via STDIN 1/2');
    is($conn->get('bar'), '54321', 'Passing scalar data via STDIN 2/2');
    
    $conn->stdin('54321[% ARG.0 %]abc');
    is($conn->get('foo'), '54321fooabc', 'Passing data via STDIN with template');

    $conn->stdin( [ '1234[% ARG.0 %]abc', '4321[% ARG.1 %]def' ]);
    is ($conn->get('foo', 'bar'), '1234fooabc
4321bardef', 'Passing multiple lines via STDIN');
}

