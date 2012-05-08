# Connector::Proxy::Config::Std
#
# Proxy class for reading Config::Std configuration
#
# Written by Scott Hardin and Martin Bartosch for the OpenXPKI project 2012
#
package Connector::Proxy::Config::Std;

use strict;
use warnings;
use English;
use Config::Std;
use Data::Dumper;

use Moose;
extends 'Connector::Proxy';

sub _build_config {
    my $self = shift;

    my $config;
    read_config($self->LOCATION(), $config);
    $self->_config($config);
}


sub get {
    my $self = shift;
    my @path = $self->_build_path_with_prefix( shift );
    
    # Config::Std does not allow nested data structures, emulate that
    # by separating last element from path and using that as key
    # in the section defined by the remaining prefix
    my $key = pop @path;
    my $section = $self->_build_path(@path);

    return $self->_config()->{$section}->{$key};
}

sub _get_node {

    my $self = shift;
    my @path = $self->_build_path_with_prefix( shift );
    
    my $fullpath = $self->_build_path(@path);
    
    return $self->_config()->{$fullpath};
}


sub get_size {
    
    my $self = shift;       
    my $node = $self->get( shift );
    
    if (!defined $node) {
        return 0;
    }
    
    if (ref $node ne "ARRAY") {
       die "requested path looks not like a list";
    }
    
    return scalar @{$node};    
}


sub get_list {
    
    my $self = shift;
    my $path = shift;
    
    # List is similar to scalar, the last path item is a hash key
    # in the section of the remaining prefix
        
    my $node = $self->get( $path );
    
    if (!defined $node) {
        return $self->_node_not_exists( $path );
    }
    
    if (ref $node ne "ARRAY") {
       die "requested path looks not like a hash";
    }
    return @{$node};    
}


sub get_keys {
    
    my $self = shift;
    my $node = $self->_get_node( shift );
    
    if (!defined $node) {
        return @{[]};
    }
    
    if (ref $node ne "HASH") {
       die "requested path looks not like a hash";
    }
    return keys (%{$node});    
}

sub get_hash {
    
    my $self = shift;
    my $path = shift;
        
    my $node = $self->_get_node( $path );
    
    if (!defined $node) {
        return $self->_node_not_exists($path);
    }
    
    if (ref $node ne "HASH") {
       die "requested path looks not like a hash";
    }
    return $node;    
}


sub get_meta {
    
    my $self = shift;
    my $origin = shift;
    
    my @path = $self->_build_path_with_prefix( $origin );
    
    # We dont have a real tree, so we look if there is a config entry
    # that has the full path as key

    my $section = $self->_build_path(@path);

    # This is either a hash or undef
    my $node = $self->_config()->{$section};
    my $meta;
    
    # Array and scalar exist one level above
    if (!defined $node) {

        my $key = pop @path;
        my $section = $self->_build_path(@path);
        $node = $self->_config()->{$section}->{$key};
                        
        if (!defined $node) {
            return undef;
        }
        if (ref $node eq '') {            
            $meta = {TYPE  => "scalar", VALUE => $node };
        } elsif (ref $node eq "SCALAR") {
            # I guess thats not supported
            $meta = {TYPE  => "reference", VALUE => $$node };               
        } elsif (ref $node eq "ARRAY") {
            $meta = {TYPE  => "list", VALUE => $node };            
        } else {
            die "Unsupported node type";    
        }
    } elsif (ref $node eq "HASH") {
        my @keys = keys(%{$node});
        $meta = {TYPE  => "hash", VALUE => \@keys };        
    } else {
        die "Unsupported node type";
    }    
    return $meta;
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head 1 Name

Connector::Proxy::Config::Std

=head 1 Description

