# Connector::Multi
#
# Connector class capable of dealing with multiple personalities.
#
# Written by Scott Hardin and Martin Bartosch for the OpenXPKI project 2012
#
package Connector::Multi;

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

Connector::Multi

=head 1 Description

This class implements a Connector that is capable of dealing with dynamically
configured Connector implementations and symlinks.
