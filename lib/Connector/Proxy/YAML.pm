# Connector::Proxy::YAML
#
# Proxy class for reading YAML configuration
#
# Written by Scott Hardin and Martin Bartosch for the OpenXPKI project 2012
#
package Connector::Proxy::YAML;

use strict;
use warnings;
use English;
use YAML;
use Data::Dumper;

use Moose;
extends 'Connector::Proxy';

has 'allowhash' => (
    is  => 'ro',
    isa => 'Bool',    
    default => 0,
);


sub _build_config {
    my $self = shift;

    my $config = YAML::LoadFile($self->LOCATION());
    $self->_config($config);
}


sub get {
    my $self = shift;
    my @path = $self->_build_path_with_prefix(@_);

    my $ptr = $self->_config();

    while (scalar @path > 1) {
	my $entry = shift @path;
	if (exists $ptr->{$entry}) {
	    if (ref $ptr->{$entry} eq 'HASH') {	
		$ptr = $ptr->{$entry};
	    } else {
		  return $self->_node_not_exists(ref $ptr->{$entry} );
	    }
	} else {
	    return $self->_node_not_exists( $entry );	    
	}
    }
    
    my $entry = $ptr->{shift @path};
    
    # Inner Node    
    if (ref $entry eq 'HASH') {
        # List context - return keys
        if (wantarray) {
            return keys %{$entry};  
        # Scalar but hash allowed - return Hash  
        } elsif ($self->allowhash()) {
            return $entry;
        } 
        # Default - size of keys
        return scalar keys %{$entry};        
    }
    
    return $entry;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head 1 Name

Connector::Proxy::YAML

=head 1 Description

