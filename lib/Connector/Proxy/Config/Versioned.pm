# Connector::Proxy::Config::Versioned
#
# Proxy class for reading Config::Versioned configuration
#
# Written by Scott Hardin, Martin Bartosch and Oliver Welter 
# for the OpenXPKI project 2012

# Todo - need some more checks on value types

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

    # We need a change to C:V backend to check if this is a node or not    
    my $val = $self->_config()->get( $path );
    
    return $val;    
}

sub get_size { 

    my $self = shift;
    my $path = $self->_build_path_with_prefix( shift ); 
    
    # We check if the value is an integer to see if this looks like 
    # an array - This is not bullet proof but should do
    
    my $val = $self->_config()->get( $path );
    
    return 0 unless( $val );
    
    die "requested path looks not like a list" unless( $val =~ /^\d+$/);
    
    return $val;

};

sub get_list { 
    
    my $self = shift;
    my $path = $self->_build_path_with_prefix( shift );

    # C::V uses an array with numeric keys internally - we use this to check if this is an array    
    my @keys = $self->_config()->get( $path );    
    $self->_node_not_exists( $path ) unless(@keys);
    
    my @list;
    foreach my $key (@keys) {
        if ($key !~ /^\d+$/) {
            die "requested path looks not like a list";
        }                
        push @list, $self->_config()->get( $path.$self->DELIMITER().$key );
    }    
    return @list;
};

sub get_keys { 

    my $self = shift;
    my $path = $self->_build_path_with_prefix( shift );   
    
    my @keys = $self->_config()->get( $path );
    
    return @{[]} unless(@keys);
    
    return @keys;

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
 
 
# This can be a very expensive method and includes some guessing
sub get_meta {
    
    my $self = shift;
    my $path = $self->_build_path_with_prefix( shift );
    
    my @keys = $self->_config()->get( $path );
    
    return unless( @keys );
        
    my $meta = {
        ITEMS => \@keys,
        TYPE => "hash"
    };
    
    #print Dumper( @keys );
    
    # Do some guessing    
    if (@keys == 1) {
        # a redirector reference
        if (ref $keys[0] eq "SCALAR") {
            $meta->{TYPE} = "reference";
            $meta->{VALUE} = ${$keys[0]};            
        } else {
        # probe if there is something "below"
            my $val = $self->_config()->get(  $path . $self->DELIMITER() . $keys[0] );             
            if (!defined $val) {
                $meta->{TYPE} = "scalar";
                $meta->{VALUE} = $keys[0];
            } elsif( $keys[0] =~ /^\d+$/) {
                $meta->{TYPE} = "list";
            }
        }
    } elsif( $keys[0] =~ /^\d+$/) {
        $meta->{TYPE} = "list";       
    }
    
    return $meta;
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head 1 Name

Connector::Proxy::Config::Versioned

=head 1 Description

