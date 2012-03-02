# Connector::Wrapper
#
# Wrapper class to filter access to a connector by a prefix 
#
# Written by Oliver Welter for the OpenXPKI project 2012
#
# TODO: To make this really transparent it need to be inherited 
# from Connector and implement the prefix stuff 

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

sub _route_call {
    
    my $self = shift;
    my $call = shift;
    my $path = shift;
    my @args = @_;
           
    # TODO - might be possible to have different delimiters   
    if (ref $path) {
        unshift @{$path}, $self->_prefix();
        $path = join(".", @{$path} );
    } elsif ($path) {
        $path = $self->_prefix() . $self->BASECONNECTOR()->DELIMITER() .  $path;
    } else {
        $path = $self->_prefix();
    }
    
    unshift @args, $path; 
    
    return $self->BASECONNECTOR()->$call( @args );       
}


# Proxy calls
sub get {    
    my $self = shift;        
    unshift @_, 'get'; 
    return $self->_route_call( @_ );     
}

sub get_list {    
    my $self = shift;        
    unshift @_, 'get_list';    
    return $self->_route_call( @_ );     
}

sub get_size {    
    my $self = shift;        
    unshift @_, 'get_size'; 
    return $self->_route_call( @_ );     
}

sub get_hash {    
    my $self = shift;        
    unshift @_, 'get_hash'; 
    return $self->_route_call( @_ );     
}

sub get_keys {    
    my $self = shift;        
    unshift @_, 'get_keys';     
    return $self->_route_call( @_ );     
}

sub set {    
    my $self = shift;        
    unshift @_, 'set'; 
    return $self->_route_call( @_ );     
}

sub get_meta {    
    my $self = shift;        
    unshift @_, 'get_meta'; 
    return $self->_route_call( @_ );     
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
