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

sub _build_config {
    my $self = shift;

#     my $config = Config::Versioned->new(
# 	{
# 	    dbpath => $self->LOCATION(),
# 	});

    $self->_config($config);
}


sub get {
    my $self = shift;
    my $arg = shift;

    # TBD

    return;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head 1 Name

Connector::Proxy::Config::Versioned

=head 1 Description

