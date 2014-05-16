# Connector
#
# A generic abstraction for accessing information.
#
# Written by Scott Hardin, Martin Bartosch and Oliver Welter for the OpenXPKI project 2012
#
package Connector;

use 5.008_008;  # This is the earliest version we've tested on

our $VERSION = '1.07';

use strict;
use warnings;
use English;
use Data::Dumper;

use Log::Log4perl;
    
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
    isa => 'Connector::Types::Key|ArrayRef|Undef',
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

has RECURSEPATH => (
    is => 'rw',
    isa => 'Bool',
    default => '0',
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

has log => (
    is       => 'rw',
    lazy     => 1,
    init_arg => undef,   # not settable via constructor
    builder  => '_build_logger',
    );


# this instance variable is set in the trigger function of PREFIX.
# it contains an array representation of PREFIX (assumed to be delimited
# by the DELIMITER character)
has _prefix_path => (
    is       => 'rw',
    isa      => 'ArrayRef',
    init_arg => undef,
    default  => sub { [] },
    writer   => '__prefix_path',
    lazy => 1
    );
    
# weather to die on undef or just fail silently
# implemented in _node_not_exists
has 'die_on_undef' => (
    is  => 'rw',
    isa => 'Bool',    
    default => 0,
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
        
        my @targ = $conn->_build_path( $args->{TARGET} );
        delete $args->{TARGET};
        
        my $meta = $class->meta;
        
        my $log = Log::Log4perl->get_logger("connector");        
        $log->trace( 'Wrapping connector - config at ' . join ".", @targ ) ;                        
                
        for my $attr ( $meta->get_all_attributes ) {
            my $attrname = $attr->name();            
            next if $attrname =~ m/^_/; # skip apparently internal params
            # allow caller to override params in CONNECTOR
            if ( not exists($args->{$attrname}) ) {                
                my $meta = $conn->get_meta( [ @targ , $attrname ] );
                $log->trace( ' Check for ' . $attrname . ' - meta is ' . Dumper $meta );                
                next unless($meta);
                if ($meta->{TYPE} eq 'scalar') {
                    $args->{$attrname} = $meta->{VALUE};                    
                } elsif ($meta->{TYPE} eq 'list') {
                my @tmp = $conn->get_list( [ @targ , $attrname ] );
                    $args->{$attrname} = \@tmp;
                } elsif ($meta->{TYPE} eq 'hash') {
                    $args->{$attrname} = $conn->get_hash( [ @targ , $attrname ] );                
                }
                                              
            }
        }
        
        $log->trace( 'Wrapping connector - arglist ' .Dumper @_ ) ;        
    }
    return $class->$orig(@_);
};


# subclasses must implement this to initialize _config
sub _build_config { return undef };

sub _build_logger { 

    return Log::Log4perl->get_logger("connector");

};


# helper function: build a path from the given input. does not take PREFIX
# into account
sub _build_path {
    
    my $self = shift;
    my @arg = @_;

    my @path;


    # Catch old call format
    if (scalar @arg > 1) {
        die "Sorry, we changed the API (pass scalar or array ref but not array)";
    }
    
    my $location = shift @arg;

    if (not $location) {
        @path = ();
    } elsif (ref $location eq '') {
        # String path - split at delimiter
        my $delimiter = $self->DELIMITER();
        @path = split(/[$delimiter]/, $location);    
    } elsif (ref $location ne "ARRAY") {
        # Nothing else than arrays allowed beyond this point
        die "Invalid data type passed in argument to _build_path";
    } elsif ($self->RECURSEPATH()) {
        foreach my $item (@{$location}) {
            push @path, $self->_build_path( $item );    
        }
    } else {    
        # Atomic path, the array is the result
        @path = @{$location};       
    }
    
    $self->log()->trace( Dumper @path );
    
    if (wantarray) {
        return @path;
    } elsif ($self->RECURSEPATH()) {
        return join $self->DELIMITER(), @path;
    } else {
        die "Sorry, we changed the API, request a list and join yourself or set RECURSEPATH in constructor";
    }    
    
}

# same as _build_config, but prepends PREFIX
sub _build_path_with_prefix {
    my $self = shift;
    my $location = shift;
    
    if (not $location) {
        return @{$self->_prefix_path()};
    } else {        
        return (@{$self->_prefix_path()}, ($self->_build_path( $location )));
    }
    
}

# This is a helper to handle non exisiting nodes
# By default we just return undef but you can configure the connector
# to die with an error  
sub _node_not_exists {    
    my $self = shift;
    my $path = shift;
        
    $path = join ("|", @{$path}) if (ref $path eq "ARRAY"); 
    
    $self->log()->debug('Node does not exist at  ' . $path );
    
    if ($self->die_on_undef()) {
        confess("Node does not exist at " . $path );
    }
    
    return undef;
}

# subclasses must implement get and/or set in order to do something useful
sub get { shift; die "No get() method defined at " . shift;  };
sub get_list { shift; die "No get_list() method defined at " . shift;  };
sub get_size { shift; die "No get_size() method defined at " . shift;  };
sub get_hash { shift; die "No get_hash() method defined at " . shift;  };
sub get_keys { shift; die "No get_keys() method defined at " . shift;  };
sub set { shift;  die "No set() method defined at " . shift;  };
sub get_meta { shift; die "No get_meta() method defined as " . shift;  };

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

Connector - a generic connection to a hierarchical-structured data set

=head1 DESCRIPTION

The Connector is generic connection to a data set, typically configuration
data in a hierarchical structure. Each connector object accepts the get(KEY)
method, which, when given a key, returns the associated value from the
connector's data source.

Typically, a connector acts as a proxy to a simple data source like
YAML, Config::Std, Config::Versioned, or to a more complex data source
like an LDAP server or Proc::SafeExec. The standard calling convention
via get(KEY) makes the connectors interchangeable.

In addition, a set of meta-connectors may be used to combine multiple
connectors into more complex chains. The Connector::Multi, for example,
allows for redirection to delegate connectors via symbolic links. If
you have a list of connectors and want to use them in a load-balancing,
round-robin fashion or have the list iterated until a value is found,
use Connector::List and choose the algorithm to perform.

=head1 SYNOPSIS

    use Connector::MODULENAME;

    my $conn = Connector::MODULENAME->new( {
        LOCATION => $path_to_config_for_module,
    });

    my $val = $conn->get('full.name.of.key');

=head2 Connector Class

This is the base class for all Connector implementations. It provides
common helper methods and performs common sanity checking.

Usually this class should not be instantiated directly.

=head1 CONFIGURATION

=head2 die_on_undef

Set to true if you want the connector to die when a query reaches a non-exisiting 
node. This will affect only calls to get/get_list/get_hash and will not affect
values that are explicitly set to undef (if supported by the connector!). 

=head 1 Accessor Methods

Each accessor method is valid only special types of nodes. If you call them 
on a wrong type of node, the connector dies.

=head2 get

Basic method to obtain a scalar value at the leaf of the config tree.

  my $value = $connector->get('smartcard.owners.tokenid.bob');
  
Each implementation must also accept an arrayref as path. The path is 
contructed from the elements. The default behaviour allows strings using 
the delimiter character inside an array element. If you want each array
element to be parsed, you need to pass "RECURSEPATH => 1" to the constructor.   

  my $value = $connector->get( [ 'smartcard','owners','tokenid','bob.builder' ] );
  
Some implementations accept control parameters, which can be passed by
I<params>, which is a hash ref of key => value pairs.
  
  my $value = $connector->get( 'smartcard.owners.tokenid.bob' , { version => 1 } );
 
=head2 get_list

This method is only valid if it is called on a "n-1" depth node representing 
an ordered list of items (array). The return value is an array with all 
values present below the node.
  
  my @items = $connector->get_list( 'smartcard.owners.tokenid'  );
 

=head2 get_size

This method is only valid if it is called on a "n-1" depth node representing 
an ordered list of items (array). The return value is the number of elements
in this array (including undef elements if they are explicitly given).
  
  my $count = $connector->get_size( 'smartcard.owners.tokens.bob' );
  
If the node does not exist, 0 is returned.
 
=head2 get_hash

This method is only valid if it is called on a "n-1" depth node representing 
a key => value list (hash). The return value is a hash ref. 
  
  my %data = %{$connector->get_hash( 'smartcard.owners.tokens.bob' )};
 
 
=head2 get_keys

This method is only valid if it is called on a "n-1" depth node representing 
a key => value list (hash). The return value is an array holding the
values of all keys (including undef elements if they are explicitly given).
  
  my @keys = $connector->get_keys( 'smartcard.owners.tokens.bob' );

If the node does not exist, an empty list is returned.

=head2 set

The set method is a "all in one" implementation, that is used for either type
of value. If the value is not a scalar, it must be passed by reference.

  $connector->set('smartcard.owners.tokenid.bob', $value, $params);

The I<value> parameter holds a scalar or ref to an array/hash with the data to 
be written. I<params> is a hash ref which holds additional parameters for the 
operation and can be undef if not needed.

=head1 STRUCTURAL METHODS
 
=head2 get_meta

This method returns some structural information about the current node as  
hash ref. At minimum it must return the type of node at the current path.

Valid values are I<scalar, list, hash, reference>. Reference is a scalar
reference which is used e.g. in Connector::Multi. The others correspond 
to the accessor methods given above.    

    my $meta = $connector->get_meta( 'smartcard.owners' );
    my $type = $meta->{TYPE};  

=head1 IMPLEMENTATION GUIDELINES

If the node does not exist, undef is returned. C<get_meta> will B<NOT> die
even if C<die_on_undef> is set, therefore you can use it to probe for a node. 

=head2 path building

You should always pass the first parameter to the private C<_build_path> 
method. This method converts any valid path spec representation to a valid
path. It takes care of the RECURSEPATH setting and returns the path 
elements as list.  

=head2 Supported methods

The methods get, get_list, get_size, get_hash, get_keys, set, meta are routed 
to the appropriate connector. 

=head1 AUTHORS

Scott Hardin <mrscotty@cpan.org>

Martin Bartosch

Oliver Welter

=head1 COPYRIGHT

Copyright 2013 OpenXPKI Foundation

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

