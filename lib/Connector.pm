# Connector
#
# A generic abstraction for accessing information.
#
# Written by Scott Hardin and Martin Bartosch for the OpenXPKI project 2012
#

use strict;
use warnings;
use English;
use Moose;

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head 1 Name

Connector

=head 1 Description

This is the base class for all Connector implementation. It provides
common helper methods and performs common sanity checking.

Usually this class should not be instantiated directly.
