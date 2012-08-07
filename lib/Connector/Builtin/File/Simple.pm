# Connector::Builtin::File::Simple
#
# Proxy class for accessing simple filex
#
# Written by Martin Bartosch for the OpenXPKI project 2012
#
package Connector::Builtin::File::Simple;

use strict;
use warnings;
use English;
use File::Spec;
use Data::Dumper;

use Moose;
extends 'Connector::Builtin';

sub _build_config {
    my $self = shift;

    if (! -r $self->{LOCATION}) {
	   confess("Cannot open input file " . $self->{LOCATION} . " for reading.");
    }
    
    return 1;
}

# this method always returns the file contents, regardless of the specified
# key
sub get {
    my $self = shift;
    my $arg = shift;

    my $filename = $self->{LOCATION};

    my $content;
    if (-r $filename) {
	$content = do {
	  local $INPUT_RECORD_SEPARATOR;
	  open my $fh, '<', $filename;
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

Connector::Builtin::File::Simple

=head 1 Description

