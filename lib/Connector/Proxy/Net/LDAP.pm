# Connector::Proxy::Net::LDAP
#
# Proxy class for accessing LDAP directories
#
# Written by Scott Hardin and Martin Bartosch for the OpenXPKI project 2012
#
package Connector::Proxy::Net::LDAP;

use strict;
use warnings;
use English;
use Net::LDAP;
use Try::Tiny;
use Template;
use Data::Dumper;

use Moose;
extends 'Connector::Proxy';

has base => (
    is  => 'rw',
    isa => 'Str',
    required => 1,
    );

has binddn => (
    is  => 'rw',
    isa => 'Str',
    );

has password => (
    is  => 'rw',
    isa => 'Str',
    );

has filter => (
    is  => 'rw',
    # TODO: this does not work (currently); NB: do we need that?
#    isa => 'Str|Net::LDAP::Filter',
    isa => 'Str',
    required => 1,
    );

has attrs => (
    is  => 'rw',
    isa => 'ArrayRef',
    );

has scope => (
    is  => 'rw',
    isa => 'Str',
    );

has timeout => (
    is  => 'rw',
    isa => 'Int',
    );

# ssl options
has verify => (
    is  => 'rw',
    isa => 'Str',
    );

has capath => (
    is  => 'rw',
    isa => 'Str',
    );


sub _build_config {
    my $self = shift;
    
}


sub _build_options {
    my $self = shift;
    
    my %options;
    foreach my $key (@_) {
	if (defined $self->$key()) {
	    $options{$key} = $self->$key();
	}
    }
    return %options;
}

sub _build_new_options {
    my $self = shift;
    return $self->_build_options(qw( timeout verify capath ));
}

sub _build_bind_options {
    my $self = shift;
    return $self->_build_options(qw( password ));
}

# the argument passed to this method will be used as template parameters
# in the expansion of the filter attribute
sub _build_search_options {
    my $self = shift;
    my $arg = shift;

    my %options = $self->_build_options(qw( base scope sizelimit timelimit ));

    my $filter = $self->filter();

    # template expansion is performed on filter strings only, not
    # on Net::LDAP::Filter objects
    if (ref $filter eq '') {
	my $template = Template->new(
	    {
	    });
	
	my $value;
	$template->process(\$filter, $arg, \$value) || die "Error processing argument template.";
    }
    $options{filter} = $filter;
    
    return %options;
}


sub get {
    my $self = shift;

    # compose a list of command arguments
    my $template_vars = {
	ARG => \@_,
    };
    
    my $uri = $self->LOCATION();

    my $ldap;
    $ldap = Net::LDAP->new($uri,
			   onerror => 'die',
			   $self->_build_new_options(),
	);

    if (! $ldap) {
	die "Could not instantiate ldap object.";
    }

    my $mesg;
    if (defined $self->binddn()) {
	$mesg = $ldap->bind(
	    $self->binddn(),
	    $self->_build_bind_options(),
	    );
    } else {
	# anonymous bind
	$mesg = $ldap->bind(
	    $self->_build_bind_options(),
	    );
    }

    if ($mesg->is_error()) {
	die "LDAP bind failed with error code " . $mesg->code() . " (error: " . $mesg->error_desc() . ")";
    }

    $mesg = $ldap->search(
	$self->_build_search_options($template_vars),
	);
    
    # TODO: get results from ldap search and return them...
    
    $mesg->unbind();
    return;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head 1 NAME

Connector::Proxy::Net::LDAP

=head 1 DESCRIPTION

