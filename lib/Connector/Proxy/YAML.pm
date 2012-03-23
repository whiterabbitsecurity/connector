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

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head 1 Name

Connector::Proxy::YAML

=head 1 Description

