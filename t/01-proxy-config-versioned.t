# Tests for Connector::Proxy::Config::Versioned
#

use strict;
use warnings;
use English;

use Test::More tests => 9;
my $gittestdir = qw( t/config/01-proxy-config-versioned.git );

my $cv_ver1 = 'fd3033aa0f4c2d18bff7a176d2bde41336d76430';

diag "LOAD MODULE\n";

BEGIN {
    my $gittestdir = qw( t/config/01-proxy-config-versioned.git );

    # remove artifacts from previous run
    use Path::Class;
    use DateTime;
    dir($gittestdir)->rmtree;

    # Config::Versioned is used directly to initialize the data source
    {
        use_ok(
            'Config::Versioned',

        );
    };
    use_ok('Connector::Proxy::Config::Versioned');
}

require_ok('Connector::Proxy::Config::Versioned');

diag "Connector::Proxy::Config::Versioned init\n";
my $cv = Config::Versioned->new(
            {
                dbpath      => $gittestdir,
                autocreate  => 1,
                filename    => '01-proxy-config-versioned-1.conf',
                path        => [qw( t/config )],
                commit_time => DateTime->from_epoch( epoch => 1240341682 ),
                author_name => 'Test User',
                author_mail => 'test@example.com',
            }
);
ok( $cv, 'create new config instance' );

# Internals: check that the head really points to a commit object
is( $cv->_git()->head->kind, 'commit', 'head should be a commit' );
is( $cv->version, $cv_ver1, 'check version (sha1 hash) of first commit' );

diag "Connector::Proxy::Config::Versioned tests\n";
###########################################################################
my $conn = Connector::Proxy::Config::Versioned->new(
    {
        LOCATION => $gittestdir,
        PREFIX   => '',
    }
);

ok( $conn, "instance created" ) || die "Unable to continue - no object instance";
is( $conn->get('group1.ldap1.uri'),
    'ldaps://example1.org', 'check single attribute' );
is( $conn->get('nonexistent'), undef, 'check for nonexistent attribute' );

