# Connector::Proxy
#
# Proxy class for attaching other CPAN modules
#
# Written by Scott Hardin and Martin Bartosch for the OpenXPKI project 2012
#
package Connector::Proxy;

use strict;
use warnings;
use English;
use Moose;

extends 'Connector';

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head 1 Name

Connector

=head 1 Description

This is the base class for all Connector::Proxy implementations.
