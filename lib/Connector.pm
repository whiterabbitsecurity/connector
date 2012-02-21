# Connector
#
# A generic abstraction for accessing information.
#
# Written by Scott Hardin and Martin Bartosch for the OpenXPKI project 2012
#
package Connector;

our $VERSION = '0.01';

use strict;
use warnings;
use English;
use Carp qw( confess );
use Moose;

has SOURCE => (
    is => 'ro',
    isa => 'Str',
    required => 1,
    );

has KEY => (
    is => 'ro',
    required => 1,
    isa => 'Str',
    );

# internal representation of the instance configuration
# NB: this should be a private variable and not accessible from outside
# an instance.
# TODO: figure out how to protect it.
has _config => (
    is       => 'rw',
    lazy     => 1,
    init_arg => undef,   # not settable via constructor
    builder  => '_build_config',
    );

# subclasses must implement this to initialize _config
sub _build_config { return undef };

# subclasses must implement get and/or set in order to do something useful
sub get { confess "No get() method defined.";  };
sub set { confess "No set() method defined.";  };

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head 1 Name

Connector

=head 1 Description

This is the base class for all Connector implementations. It provides
common helper methods and performs common sanity checking.

Usually this class should not be instantiated directly.
