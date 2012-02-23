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
use Data::Dumper;

use Moose;
use Connector::Types;

has LOCATION => (
    is => 'ro',
    isa => 'Connector::Types::Location',
    required => 1,
    );

has PREFIX => (
    is => 'rw',
    isa => 'Connector::Types::Key',
    # build and store an array of the prefix in _prefix_path
    trigger => sub {
	my ($self, $prefix, $old_prefix) = @_;
	my @path = $self->_build_path($prefix);
	$self->__prefix_path(\@path);
    }
    );

has DELIMITER => (
    is => 'rw',
    isa => 'Connector::Types::Char',
    default => '.',
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

# this instance variable is set in the trigger function of PREFIX.
# it contains an array representation of PREFIX (assumed to be delimited
# by the DELIMITER character)
has _prefix_path => (
    is       => 'rw',
    init_arg => undef,
    writer   => '__prefix_path',
    );


# subclasses must implement this to initialize _config
sub _build_config { return undef };

# _build_path 
sub _build_path {
    my $self = shift;
    my $arg  = shift || '';

    my $prefix    = $self->PREFIX() || '';
    my $delimiter = $self->DELIMITER();

    my $path = '';
    if (length($prefix) && length($arg)) {
	$path = $prefix . $delimiter . $arg;
    } else {
	$path = $prefix . $arg;
    }

    if (wantarray) {
	return split(/[$delimiter]/, $path);
    } else {
	return $path;
    }
}

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
