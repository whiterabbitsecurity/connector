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
    is => 'rw',
    isa => 'Bool',
    default => 0,
    );

# By default the SOAP call uses positional parameters. If this flag is set,
# the argument list to the call is interpreted as a Hash
has use_named_parameters => (
    is => 'rw',
    # FIXME
    # isa => 'Bool',
    isa => 'Str',
    default => 0,
    );

has certificate_file => (
    is => 'rw',
    isa => 'Str',
    );

has certificate_key_file => (
    is => 'rw',
    isa => 'Str',
    );

has certificate_p12_file => (
    is => 'rw',
    isa => 'Str',
    );

has certificate_p12_password => (
    is => 'rw',
    isa => 'Str',
    );


has ca_certificate_path => (
    is => 'rw',
    isa => 'Str',
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

#    my $arg = shift;

    my $proxy = $self->LOCATION();

    my %ENV_BACKUP = %ENV;

    if ($self->certificate_file) {
	if ($self->certificate_p12_file) {
	    die "Options certificate_file and certificate_p12_file are mutually exclusive";
	}
	$ENV{HTTPS_CERT_FILE} = $self->certificate_file;
    }

    if ($self->certificate_key_file) {
	$ENV{HTTPS_KEY_FILE}  = $self->certificate_key_file;
    }

    if ($self->certificate_p12_file) {
	$ENV{HTTPS_PKCS12_FILE}  = $self->certificate_p12_file;
    }
    if ($self->certificate_p12_password) {
	$ENV{HTTPS_PKCS12_PASSWORD}  = $self->certificate_p12_password;
    }

    if ($self->ca_certificate_path) {
	$ENV{HTTPS_CA_DIR}    = $self->ca_certificate_path;
    }

    my $client = SOAP::Lite
	-> uri($self->uri)
	-> proxy($proxy);

    if ($self->use_microsoft_dot_net_compatible_separator) {
	$client->on_action( sub { join('/', @_) } );
    }

    $self->log()->debug('Performing SOAP call to method ' . $self->method . ' on service ' . $self->uri . ' via ' . $proxy);
    my @params;
    if ($self->use_named_parameters) {
	# names parameters
	# FIXME: this is what we really want:
# 	my %args = @_;

	# FIXME: only support one single named parameter, named in
	# "use_named_parameters" for now
	my %args = (
		    $self->use_named_parameters => shift,
		    );

 	foreach my $key (keys %args) {
 	    push @params, SOAP::Data->new(name => $key, value => $args{$key});
	    $self->log()->debug('Named parameter: ' . $key . ' => ' . $args{$key});
 	}
    } else {
	@params = @_;
	$self->log()->debug('Parameters: ' . join(', ', @params));
    }


    my $som;
    eval {
        $som = $client->call($self->method,
			    @params);
    };
    if ($@) {
	$self->log()->error('SOAP call died: ' . $@);
	die 'Fatal SOAP Error: ' . $@ . " [method=" . $self->method . ", params=(" . join(', ', @params) . ")]";
    }


    # restore environment
    %ENV = %ENV_BACKUP;

    if ($som->fault) {
	$self->log()->error('SOAP call returned error: ' . $som->fault->{faultstring});
	die $som->fault->{faultstring};
    }

    return $som->result;
}


sub get {
    my $self = shift;

    my $result = $self->_soap_call(@_);
    return if (! defined $result);

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

    return if (! defined $result);

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

    return if (! defined $result);

    if (ref $result ne 'HASH' ) {
        die "SOAP call result is not a hash";
    }

    return $result;
}

sub get_meta {
    my $self = shift;
    # FIXME
    die "Sorry that is not supported, yet";
}

sub exists {

    my $self = shift;

    # FIXME
    die "Sorry that is not supported, yet";

}
no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head 1 NAME

Connector::Proxy::SOAP::Lite

=head 1 DESCRIPTION


