# Connector::Proxy::Config::Versioned
#
# Proxy class for reading Config::Versioned configuration
#
# Written by Scott Hardin and Martin Bartosch for the OpenXPKI project 2012
#
package Connector::Proxy::Config::Versioned;

use strict;
use warnings;
use English;
use Config::Versioned;
use Data::Dumper;

use Moose;
extends 'Connector::Proxy';

has '+_config' => (
    lazy => 1,
);

sub _build_config {
    my $self = shift;

    my $config = Config::Versioned->new( { dbpath => $self->LOCATION(), } );

    if ( not defined $config ) {
        return; # try to throw exception
    }
    $self->_config($config);
}

sub get {
    my $self = shift;
    my $path = $self->_build_path_with_prefix( shift );

    return $self->_config()->get( $path );
}

sub get_size { 

    my $self = shift;
    my $path = $self->_build_path_with_prefix( shift );   
    return $self->_config()->get( $path ) || 0;

};

sub get_list { 
    
    my $self = shift;
    my $path = $self->_build_path_with_prefix( shift );
    
    my $item_count = $self->_config()->get( $path );
    
    $self->_node_not_exists( $path ) unless( $item_count );
    
    my @list;
    for (my $index = 0; $index < $item_count; $ index++) {  
        push @list, $self->_config()->get( $path.$self->DELIMITER().$index );        
    } 
    return \@list;
};

sub get_keys { 

    my $self = shift;
    my $path = $self->_build_path_with_prefix( shift );   
    
    my @keys = $self->_config()->get( $path );
    
    return $self->_node_not_exists( $path ) unless(@keys);
    
    return \@keys;

}; 

sub get_hash { 
    
    my $self = shift;
    my $path = $self->_build_path_with_prefix( shift );
    
    my @keys = $self->_config()->get( $path );
    
    $self->_node_not_exists( $path ) unless(@keys);
    my $data = {};
    foreach my $key (@keys) {  
        $data->{$key} = $self->_config()->get( $path.$self->DELIMITER().$key );
    }    
    return $data;
};
 

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head 1 Name

Connector::Proxy::Config::Versioned

=head 1 Description

