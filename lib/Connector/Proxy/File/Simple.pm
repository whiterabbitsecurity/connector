# Connector::Proxy::File::Simple
#
# Proxy class for accessing simple filex
#
# Written by Martin Bartosch for the OpenXPKI project 2012
#
package Connector::Proxy::File::Simple;

use strict;
use warnings;
use English;
use File::Spec;
use Data::Dumper;

use Moose;
extends 'Connector::Proxy';

sub _build_config {
    my $self = shift;
    
    return 1;
}

sub get {
    my $self = shift;
    my $arg = shift;

    my $path = File::Spec->catfile($self->_build_path($arg));
    my $content;

    print "path: $path\n";
    if (-r $path) {
      $content = do {
	  local $INPUT_RECORD_SEPARATOR;
	  open my $fh, '<', $path;
	  <$fh>;
      };
    }

    return $content;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head 1 Name

Connector::Proxy::File::Simple

=head 1 Description

