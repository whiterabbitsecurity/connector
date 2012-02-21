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
    $self->_config(YAML::LoadFile($self->SOURCE()));
}

sub get {
    my $self = shift;
    my $arg = shift;

    return $self->_config()->{$self->KEY()}->{$arg};
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head 1 Name

Connector::Proxy::YAML

=head 1 Description

