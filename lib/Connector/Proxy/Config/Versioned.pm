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
    lazy => 0,
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

    return $self->_config()->get(@_);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head 1 Name

Connector::Proxy::Config::Versioned

=head 1 Description

