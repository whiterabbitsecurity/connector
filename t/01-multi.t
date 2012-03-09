# Tests for Connector::Multi
#

use strict;
use warnings;
use English;

use Test::More tests => 22;
use Path::Class;
use DateTime;

my ($base, $conn);

BEGIN {
    use_ok( 'Config::Versioned' ); 
    use_ok( 'Connector::Multi' ); 
    use_ok( 'Connector::Proxy::YAML' ); 
    use_ok( 'Connector::Proxy::Config::Versioned' ); 
}

require_ok( 'Config::Versioned' );
require_ok( 'Connector::Multi' );
require_ok( 'Connector::Proxy::YAML' );
require_ok( 'Connector::Proxy::Config::Versioned' );

# The Connector::Multi uses Connector::Proxy::Config::Versioned, which
# must first be initialized with our test data.
my @test_data = (
    {
        dbpath => 't/config/01-multi-flat.git',
        filename => '01-multi-flat.conf',
        path => [ qw( t/config ) ],
    },
    {
        dbpath => 't/config/01-multi-sym1.git',
        filename => '01-multi-sym1.conf',
        path => [ qw( t/config ) ],
    },
);

foreach my $data ( @test_data ) {
    dir($data->{dbpath})->rmtree;
    my $cv = Config::Versioned->new(
        {
            dbpath => $data->{dbpath},
            autocreate => 1,
            filename => $data->{filename},
            path => $data->{path},
            commit_time => $data->{commit_time} ||
                DateTime->from_epoch( epoch => 1240341682 ),
            author_name => $data->{author_name} || 'Test User',
            author_mail => $data->{author_mail} || 'test@example.com',
        }
    ) or die "Error creating Config::Versioned: $@";
}


###########################################################################
#my $base = Connector::Proxy::Config::Versioned->new({
#	LOCATION  => $test_data[0]->{dbpath},
#});
#
#is($base->get('smartcards.tokens.token_1.status'), 'ACTIVATED',
#    'check base connector (1)');
#is($base->get('smartcards.owners.joe.tokenid'), 'token_1',
#    'check base connector (2)');
#is($base->get('smartcards.tokens.token_1.nonexistent'), undef,
#    'check base connector (3)');

$conn = Connector::Multi->new( {
    BASECONNECTOR => 'Connector::Proxy::Config::Versioned',
    LOCATION => $test_data[0]->{dbpath},
    });

is($conn->get('smartcards.tokens.token_1.status'), 'ACTIVATED',
    'multi with simple config (1)');
is($conn->get('smartcards.owners.joe.tokenid'), 'token_1',
    'multi with simple config (2)');
is($conn->get('smartcards.tokens.token_1.nonexistent'), undef, 'multi with simple config (3)');

# Reuse $base and $conn to ensure we don't accidentally test previous 
# connectors.
$base = Connector::Proxy::Config::Versioned->new({
	LOCATION  => $test_data[1]->{dbpath},
});

my $sym = $base->get('smartcards.tokens');
is( ref($sym), 'SCALAR', 'check value of symlink is anon ref to scalar');
is( ${ $sym }, 'connector:connectors.yaml-query-tokens', 'check target of symlink');

$conn = Connector::Multi->new( {
        BASECONNECTOR => $base,
});

my @leaf = sort $conn->get('smartcards');
is($leaf[0], 'owners', 'check that we even get a record with the symlink layout');
is(scalar @leaf, 2, 'should have received two records');
$sym = $conn->get('smartcards.tokens');
is(ref($sym), 'SCALAR', 'check that we even get a record with the symlink layout');

is($conn->get('smartcards.tokens.token_1.status'), 'ACTIVATED',
    'multi with symlink config (1)');
is($conn->get('smartcards.owners.joe.tokenid'), 'token_1',
    'multi with symlink simple config (2)');
is($conn->get('smartcards.tokens.token_1.nonexistent'), undef, 'multi with symlink simple config (3)');
