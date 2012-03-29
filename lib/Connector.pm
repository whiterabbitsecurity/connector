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
use Data::Dumper;

use Moose;
use Connector::Types;

has LOCATION => (
    is => 'ro',
    isa => 'Connector::Types::Location',
    required => 1,
    );

# In order to clear the prefix, call the accessor with undef as argument
has PREFIX => (
    is => 'rw',
    isa => 'Connector::Types::Key|Undef',
    # build and store an array of the prefix in _prefix_path
    trigger => sub {
	my ($self, $prefix, $old_prefix) = @_;
	if (defined $prefix) {
	    my @path = $self->_build_path($prefix);
	    $self->__prefix_path(\@path);
	} else {
	    $self->__prefix_path([]);
	}
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
    default  => sub { [] },
    writer   => '__prefix_path',
    );

# This is the foo that allows us to just milk the connector config from
# the settings fetched from another connector.

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    my $args = $_[0];

    if (    ref($args) eq 'HASH'
            && defined($args->{CONNECTOR})
            && defined($args->{TARGET}) ) {

        my $conn = $args->{CONNECTOR};
        delete $args->{CONNECTOR};
        my $targ = $args->{TARGET};
        delete $args->{TARGET};
        my $meta = $class->meta;
        
        for my $attr ( $meta->get_all_attributes ) {
            my $attrname = $attr->name();            
            next if $attrname =~ m/^_/; # skip apparently internal params
            # allow caller to override params in CONNECTOR
            if ( not exists($args->{$attrname}) ) {                
                my $val = $conn->get($targ . $conn->DELIMITER() . $attrname);
                if ( defined $val ) {
                    $args->{$attrname} = $val;
                }
            }
        }        
    }
    return $class->$orig(@_);
};


# subclasses must implement this to initialize _config
sub _build_config { return undef };

# helper function: build a path from the given input. does not take PREFIX
# into account
sub _build_path {
    my $self = shift;
    my @arg = @_;

    my @path;

    my $delimiter = $self->DELIMITER();
    foreach my $item (@arg) {
 	if (ref $item eq '') {
	    push @path, split(/[$delimiter]/, $item);
 	} elsif (ref $item eq 'ARRAY') {
 	    push @path, @{$item};
 	} else {
 	    die "Invalid data type passed in argument to _build_path";
 	}
    }

    if (wantarray) {
	return @path;
    } else {
	return join($self->DELIMITER(), @path);
    }
}

# same as _build_config, but prepends PREFIX
sub _build_path_with_prefix {
    my $self = shift;

    return $self->_build_path(@{$self->_prefix_path()}, @_);
}

# Transparently add support for arrayref pathspec
around get => sub {
    my $orig = shift;
    my $class = shift;
     
    my $path = shift;
      
    # TODO - might be possible to have different delimiters
    if (ref $path) {
        $path = join( $class->DELIMITER() , @{$path} );
    }
     
    return $class->$orig($path);
    
};

# subclasses must implement get and/or set in order to do something useful
sub get { die "No get() method defined.";  };
sub set { shift; my $loc = shift;  die "No set() method defined (Path $loc).";  };

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
