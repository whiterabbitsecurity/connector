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

has 'BASECONNECTOR' => ( is => 'ro', required => 1, init_arg => 'CONNECTOR' );

sub get {
    
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
     
    return $self->BASECONNECTOR()->get( $path );        
}

sub set {
    
    my $self = shift;
    my $path = shift;
    my $value = shift;
       
    if (ref $path) {
        unshift @{$path}, $self->_prefix();
        $path = join(".", @{$path} );
    } elsif ($path) {
        $path = $self->_prefix() . $self->BASECONNECTOR()->DELIMITER() .  $path;
    } else {
        $path = $self->_prefix();
    }
     
    return $self->BASECONNECTOR()->set( $path, $value );        
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head 1 Name

Connector

=head 1 Description

This is the base class for all Connector::Proxy implementations.
