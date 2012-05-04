# Connector::Proxy::SOAP::Lite
#
# Proxy class for accessing SOAP servers
#
# Written by Martin Bartosch for the OpenXPKI project 2012
#
package Connector::Proxy::SOAP::Lite;

use strict;
use warnings;
use English;
use SOAP::Lite;
use Try::Tiny;
use Data::Dumper;

use Moose;
extends 'Connector::Proxy';

has uri => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    );

has method => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    );

has do_not_use_charset => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
    );

has use_microsoft_dot_net_compatible_separator => (
    is => 'ro'
    isa => 'Bool',
    default => 0,
    );

# By default the SOAP call uses positional parameters. If this flag is set,
# the argument list to the call is interpreted as a Hash
has use_named_parameters => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
    );

sub BUILD {
    my $self = shift;
    if ($self->do_not_use_charset) {
	$SOAP::Constants::DO_NOT_USE_CHARSET = 1;
    }
}

sub _build_config {
    my $self = shift;
}


sub _soap_call {
    my $self = shift;

    my $arg = shift;

    my $proxy = $self->LOCATION();

    my $client = SOAP::Lite
	-> uri($self->uri)
	-> proxy($proxy);

    if ($self->use_microsoft_dot_net_compatible_separator) {
	$client->on_action( sub { join('/', @_) } );
    }

    my @params;
    if ($self->use_named_parameters) {
	# names parameters
	my %args = @_;
	foreach my $key (keys %args) {
	    push @params, SOAP::Data->new(name => $key, value => $args{$key});
	}
    } else {
	@params = @_;
    }

    my $som = $client->call($arg,
			    @params);

    if ($som->fault) {
	die $som->fault->{faultstring};
    }

    return $som->result;
}


sub get {
    my $self = shift;
    
    my $result = $self->_soap_call(@_);
    return undef if (! defined $result);

    if (ref $result ne '') {
	die "SOAP call result is not a scalar";
    }
    return $result;
}

sub get_size {
    my $self = shift;
    
    my $result = $self->get_list(@_);
    return scalar @{$result};
}

sub get_list {
    my $self = shift;    

    my $result = $self->_soap_call(@_);
    
    return undef if (! defined $result);
    
    if (ref $result ne 'ARRAY' ) {
        die "SOAP call result is not a list";
    }
    
    return @{$result};    
}

sub get_keys {
    my $self = shift;

    my $result = $self->get_hash(@_);
    return keys %{$result};
}

sub get_hash {
    my $self = shift;    

    my $result = $self->_soap_call(@_);
    
    return undef if (! defined $result);
    
    if (ref $result ne 'HASH' ) {
        die "SOAP call result is not a hash";
    }
    
    return $result;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head 1 NAME

Connector::Proxy::SOAP::Lite

=head 1 DESCRIPTION

