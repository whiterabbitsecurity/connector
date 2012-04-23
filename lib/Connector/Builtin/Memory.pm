# Connector::Builtin::Memory
#
# Proxy class for reading YAML configuration
#
# Written by Scott Hardin, Martin Bartosch and Oliver Welter 
# for the OpenXPKI project 2012
#
# THIS IS NOT WORKING IN A FORKING ENVIRONMENT!


package Connector::Builtin::Memory;

use strict;
use warnings;
use English;

use Moose;
extends 'Connector::Builtin';

has '+LOCATION' => ( required => 0 );

sub _build_config {
    my $self = shift;
    $self->_config( {} );
}


sub get {
    
    my $self = shift;
    my @path = $self->_build_path_with_prefix( shift );

    if ( scalar @path == 0) {
        return keys %{$self->_config()};
    }

    my $ptr = $self->_config();

    while (scalar @path > 1) {
    my $entry = shift @path;
    if (exists $ptr->{$entry}) {
        if (ref $ptr->{$entry} eq 'HASH') { 
        $ptr = $ptr->{$entry};
        } else {
        confess('Invalid data type in path: ' . ref $ptr->{$entry});
        }
    } else {
        confess('Invalid data type');
    }
    }
    
    my $entry = $ptr->{shift @path};
    # return the keys if it is a subtree
    if (ref $entry eq 'HASH') {
        return keys %{$entry};
    }
    return $entry;
}


sub set {
    
    my $self = shift;
    my @path = $self->_build_path_with_prefix( shift );

    my $value = shift;

    my $ptr = $self->_config();
    
    while (scalar @path > 1) {
        my $entry = shift @path;        
        if (!exists $ptr->{$entry}) {
            $ptr->{$entry} = {};
        } elsif (ref $ptr->{$entry} ne "HASH") {
            confess('Try to step over a value node at ' . $entry);
        }
        $ptr = $ptr->{$entry};    
    }
    
    my $entry = shift @path;

    if (exists $ptr->{$entry}) {
        if (ref $ptr->{$entry} ne ref $value) {
            confess('Try to override data type at node ' . $entry);
        }
    }
    $ptr->{$entry} = $value;
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head 1 Name

Connector::Builtin::Memory

=head 1 Description

A connector implementation to allow memory based caching
