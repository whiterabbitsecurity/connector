# Connector::Wrapper
#
# Wrapper class to filter access to a connector by a prefix 
#
# Written by Oliver Welter for the OpenXPKI project 2012
#
package Connector::Wrapper;

use strict;
use warnings;
use English;
use Moose;
use Data::Dumper;

has '_prefix' => ( is => 'ro', required => 1, init_arg => 'TARGET' );

has 'BASECONNECTOR' => ( 
    is => 'ro', 
    required => 1, 
    init_arg => 'CONNECTOR'     
);

sub _assemble_path {
    
    my $self = shift;
    my $path = shift;
       
    # TODO - might be possible to have different delimiters   
    if (ref $path) {
        unshift @{$path}, $self->_prefix();
        $path = join(".", @{$path} );
    } elsif ($path) {
        $path = $self->_prefix() . $self->BASECONNECTOR()->DELIMITER() .  $path;
    } else {
        $path = $self->_prefix();
    }
    
    return $path;    
}

# Proxy Methods 
sub get {
    my $self = shift;
    return $self->BASECONNECTOR()->get( $self->_assemble_path( shift ), shift );        
}

sub get_list {
    my $self = shift;            
    return $self->BASECONNECTOR()->get( $self->_assemble_path( shift ), shift );        
}

sub get_size {
    my $self = shift;            
    return $self->BASECONNECTOR()->get( $self->_assemble_path( shift ), shift );        
}

sub get_hash {
    my $self = shift;            
    return $self->BASECONNECTOR()->get( $self->_assemble_path( shift ), shift );        
}

sub get_keys {
    my $self = shift;            
    return $self->BASECONNECTOR()->get( $self->_assemble_path( shift ), shift );        
}

sub set {
    my $self = shift;            
    return $self->BASECONNECTOR()->set( $self->_assemble_path( shift ), shift, shift );        
}

sub get_meta {
    my $self = shift;            
    return $self->BASECONNECTOR()->meta( $self->_assemble_path( shift ) );        
}
 

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head 1 Name

Connector

=head 1 Description

This provides a wrapper to the connector with a fixed prefix.

=head 2 Supported methods

get, get_list, get_size, get_hash, get_keys, set, meta

