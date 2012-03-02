# Tests for Connector::Proxy::Net::LDAP
#

use strict;
use warnings;
use English;

use Test::More tests => 2;

diag "LOAD MODULE\n";

BEGIN {
    use_ok( 'Connector::Proxy::Net::LDAP' ); 
}

require_ok( 'Connector::Proxy::Net::LDAP' );


diag "Connector::Proxy::Net::LDAP tests\n";
###########################################################################


my $conn = Connector::Proxy::Net::LDAP->new(
    {
	LOCATION  => 'ldap://ldap.example.com:389',
	base      => 'dc=example,dc=com',
	filter    => '(cn=[% ARG.0 %])'
    });

is($conn->get('abc'), '1111');
