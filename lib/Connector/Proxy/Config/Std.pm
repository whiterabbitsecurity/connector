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

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head 1 Name

Connector::Proxy::Config::Std

=head 1 Description

