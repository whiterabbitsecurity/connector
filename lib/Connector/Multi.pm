# Connector::Multi
#
# Connector class capable of dealing with multiple personalities.
#
# Written by Scott Hardin and Martin Bartosch for the OpenXPKI project 2012
#
package Connector::Multi;

use strict;
use warnings;
use English;
use Moose;

extends 'Connector';

has 'BASECONNECTOR' => ( is => 'ro', required => 1 );

has '+LOCATION' => ( required => 0 );

sub _build_config {
    my $self = shift;

    # Our config is merely a hash of connector instances
    my $config = {};
    my $baseconn = $self->BASECONNECTOR();
    my $baseref;

    if ( ref($baseconn) ) { # if it's a ref, assume that it's a Connector
        $baseref = $baseconn;
    } else {
        eval "use $baseconn;1" or die "Error use'ing $baseconn: $@";
        $baseref = $baseconn->new({ LOCATION => $self->LOCATION() });
    }
    $config->{''} = $baseref;
    $self->_config($config);
}

sub get {
    my $self = shift;
    my $location = shift;

    my $delim = $self->DELIMITER();

#    my $conn = $self->BASECONNECTOR();  # get default connector
    my $conn = $self->_config()->{''};  # get default connector
    if ( ! $conn ) {
        die "ERR: no default connector for Connector::Multi";
    }
    
    if (ref $location) {
        $location = join (".", @{$location});
    }
    
    my @prefix = ();
    my @suffix = split(/[$delim]/, $location);
    
    while ( @suffix > 1 ) { # always treat the last section as non-symlink
        my $node = shift @suffix;
        push @prefix, $node;
        my $val = $conn->get(join($delim, @prefix));
        if ( defined($val) and ( ref($val) eq 'SCALAR' ) ) {
            if ( ${ $val } =~ m/^([^:]+):(.+)$/ ) {
                my $schema = $1;
                my $target = $2;
                if ( $schema eq 'connector' ) {
                    $conn = $self->get_connector($target);
                    if ( ! $conn ) {
                        die "Connector::Multi: error creating connector for '$target': $@";
                    }
                    if ( wantarray ) {
                        return ( $conn->get(join($delim, @suffix)) );
                    } else {
                        return scalar $conn->get(join($delim, @suffix));
                    }
                } else {
                    die "Connector::Multi: unsupported schema for symlink: $schema";
                }
            } else {
                # redirect
                @prefix = split(/[$delim]/, $val);
            }
        }
    }

    if ( wantarray ) {
        # coerce the connector's get to return a list
        return ( $conn->get(join($delim, @prefix, @suffix)) );
    } else {
        return scalar $conn->get(join($delim, @prefix, @suffix));
    }
}


sub set {
    my $self = shift;
    my $location = shift;
    my $value = shift;

    my $delim = $self->DELIMITER();

    my $conn = $self->BASECONNECTOR();  # get default connector
    if ( ! $conn ) {
        die "ERR: no default connector for Connector::Multi";
    }
    
    if (ref $location) {
        $location = join (".", @{$location});
    }
    
    my @prefix = ();
    my @suffix = split(/[$delim]/, $location);
    
    while ( @suffix > 1 ) { # always treat the last section as non-symlink
        my $node = shift @suffix;
        push @prefix, $node;
        my $val = $conn->get(join($delim, @prefix));
        if ( defined($val) and ( ref($val) eq 'SCALAR' ) ) {
            if ( ${ $val } =~ m/^([^:]+):(.+)$/ ) {
                my $schema = $1;
                my $target = $2;
                if ( $schema eq 'connector' ) {
                    $conn = $self->get_connector($target);
                    if ( ! $conn ) {
                        die "Connector::Multi: error creating connector for '$target': $@";
                    }                    
                    return $conn->set(join($delim, @suffix), $value );                    
                } else {
                    die "Connector::Multi: unsupported schema for symlink: $schema";
                }
            } else {
                # redirect
                @prefix = split(/[$delim]/, $val);
            }
        }
    }    
    return scalar $conn->set($location, $value );    
}

sub get_connector {
    my $self = shift;
    my $target = shift;
    my $delim = $self->DELIMITER();

    my $conn = $self->_config()->{$target};    
    if ( ! $conn ) {
        # use the 'root' connector instance
        my $class = $self->BASECONNECTOR()->get($target . $delim . 'class');
        $conn = $class->new( { CONNECTOR => $self->BASECONNECTOR(), TARGET => $target } );
    }
    return $conn;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

Connector::Multi

=head1 DESCRIPTION

This class implements a Connector that is capable of dealing with dynamically
configured Connector implementations and symlinks.

The underlying concept is that there is a primary (i.e.: boot) configuration
source that Multi accesses for get() requests. If the request returns a reference
to a SCALAR, Multi interprets this as a symbolic link. The content of the 
link contains an alias and a target key. 

=head1 Example

In this example, we will be using a YAML configuration file that is accessed
via the connector Connector::Proxy::YAML.

From the programmer's view, the configuration should look something like this:

  smartcards:
    tokens:
        token_1:
            status: ACTIVATED
        token_2:
            status: DEACTIVATED
    owners:
        joe:
            tokenid: token_1
        bob:
            tokenid: token_2
 
In the above example, calling get('smartcards.tokens.token_1.status') returns
the string 'ACTIVATED'.

To have the data fetched from an LDAP server, we can redirect the
'smartcards.tokens' key to the LDAP connector using '@' to indicate symlinks.
Our primary configuration source for both tokens and owners would contain
the following entries:

  smartcards:
    @tokens: connector:connectors.ldap-query-token
    @owners: connector:connectors.ldap-query-owners

With the symlink now in the key, Multi must walk down each level itself and 
handle the symlink. When 'smartcards.tokens' is reached, it reads the contents 
of the symlink, which is an alias to a connector 'ldap-query-token'. The
connector configuration is in the 'connectors' namespace of our primary data source.

  connectors:
    ldap-query-tokens: 
        class: Connector::Proxy::Net::LDAP
        basedn: ou=smartcards,dc=example,dc=org
        server:
            uri: ldaps://example.org
            bind_dn: uid=user,ou=Directory Users,dc=example,dc=org
            password: secret

  connectors:
    ldap-query-owners:
        class: Connector::Proxy::Net::LDAP
        basedn: ou=people,dc=example,dc=org
        server: 
            uri: ldaps://example.org
            bind_dn: uid=user,ou=Directory Users,dc=example,dc=org
            password: secret

B<NOTE: The following is not implemented yet.>

Having two queries with duplicate server information could also be simplified.
In this case, we define that the server information is found when the
connector accesses 'connectors.ldap-query-token.server.<param>'. The 
resulting LDAP configuration would then be:

  connectors:
    ldap-query-token:
        class: Connector::Proxy::Net::LDAP
        basedn: ou=smartcards,dc=example,dc=org
        @ldap-server: redirect:connectors.ldap-example-org
    ldap-query-owners:
        class: Connector::Proxy::Net::LDAP
        basedn: ou=people,dc=example,dc=org
        @ldap-server: redirect:connectors.ldap-example-org
    ldap-example-org:
        uri: ldaps://example.org
        bind_dn: uid=user,ou=Directory Users,dc=example,dc=org
        password: secret


The alias 'connectors.ldap-example-org' contains the definition needed by the LDAP
connector. In this case, we don't need a special connector object.
Instead, all we need is a simple redirect that allows two different
entries (in this case, the other two connectors) to share a common
entry in the tree.

=head1 SYNOPSIS

The parameter BASECONNECTOR may either be a class instance or
the name of the class, in which case the additional arguments
(e.g.: LOCATION) are passed to the base connector.

  use Connector::Proxy::Config::Versioned;
  use Connector::Multi;

  my $base = Connector::Proxy::Config::Versioned->new({
    LOCATION => $path_to_internal_config_git_repo,
  });

  my $multi = Connector::Multi->new( {
    BASECONNECTOR => $base,
  });

  my $tok = $multi->get('smartcard.owners.bob.tokenid');

or...

  use Connector::Multi;

  my $multi = Connector::Multi->new( {
    BASECONNECTOR => 'Connector::Proxy::Config::Versioned',
    LOCATION => $path_to_internal_config_git_repo,
  });

  my $tok = $multi->get('smartcard.owners.bob.tokenid');
  
You can also pass the path as an arrayref, where each element can be a path itself

  my $tok = $multi->get( [ 'smartcard.owners', 'bob.tokenid' ]);

=head1 OPTIONS

When creating a new instance, the C<new()> constructor accepts the
following options:

=over 8

=item BASECONNECTOR

This is a reference to the Connector instance that Connector::Multi
uses at the base of all get() requests.

=back

