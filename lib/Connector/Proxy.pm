# Connector::Proxy
#
# Proxy class for attaching other CPAN modules
#
# Written by Scott Hardin and Martin Bartosch for the OpenXPKI project 2012
#
package Connector::Proxy;

use strict;
use warnings;
use English;
use Moose;
use Connector::Wrapper;

extends 'Connector';

has LOOPBACK => (
    is => 'ro',
    isa => 'Connector::Wrapper',
    reader => 'conn',
    required => 0,
);

around BUILDARGS => sub {
    
    my $orig = shift;
    my $class = shift;

    my $args = $_[0];

    if (  ref($args) eq 'HASH'
            && defined($args->{CONNECTOR})
            && defined($args->{TARGET}) ) {
                
            $args->{LOOPBACK} = Connector::Wrapper->new( $args );                
    }
    
    return $class->$orig(@_);
    
};

# Transparently add support for arrayref pathspec
around get => sub {
    my $orig = shift;
    my $class = shift;
     
    my $path = shift;
      
    # TODO - might be possible to have different delimiters
    if (ref $path) {
        $path = join( $class->DELIMITER() , @{$path} );
    }
     
    return $class->$orig($path);
    
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 Name

Connector

=head1 Description

This is the base class for all Connector::Proxy implementations.

=head1 Developer Info

When creating the connector, all class attributes that have a corresponding config
item are initialised with the given values.

All configuration options, that are denoted on the same level as the connector 
definition are accessible inside the class using  C<$self->conn()->get()>.
