# Connector::Proxy::Net::LDAP::Single
#
# Proxy class for accessing LDAP directories
# The class is designed to find and return a single entry
#
# Written by Oliver Welter for the OpenXPKI project 2012
#
    
# FIXME - we need to find a syntax to pass multiple arguments in by 
# all possible allowed path specs which is a problematic with
# Search Strings having the delimiter as character.....
# For now we just take is as it comes and assume a string as 
# the one and only argument 

package Connector::Proxy::Net::LDAP::Single;

use strict;
use warnings;
use English;
use Net::LDAP;
use Try::Tiny;
use Template;
use Data::Dumper;
use Digest::SHA1  qw(sha1_hex);
use OpenXPKI::DN;

use Connector::Multi;
use Connector::Proxy::YAML;

use Moose;
extends 'Connector::Proxy::Net::LDAP';

has attrmap => (
    is  => 'rw',
    isa => 'HashRef',    
    trigger => \&_map_attrs
);


sub _map_attrs {
    
    my ( $self, $new, $old ) = @_; 

    # Write the attrs property from the keys of the map
    if (ref $new eq "HASH") {
        my @attrs = values %{$new};        
        $self->attrs( \@attrs ) 
    }    
}

sub get {
    my $self = shift;    
    my $args = shift;

    my $ldap = $self->ldap();
    
    if (!$self->attrs || @{$self->attrs} != 1) {       
        die "The attribute map must contain exactly one entry"
    }
    
    # compose a list of command arguments
    my $template_vars = {
       ARG => $args,
    };
    
    my $mesg = $ldap->search(
        $self->_build_search_options($template_vars),
    );
       
    if ($mesg->count() == 0) {
        return $self->_node_not_exists('');
    }
    
    if ($mesg->count() > 1) {
        die "More than one entry found - result is not unique."
    }
    
      
    my $entry = $mesg->entry(0);
        
    my $ref = $entry->get_value ( $self->attrs->[0], asref => 1 );
    
    # Attribute does not exist
    $self->_node_not_exists('') unless ($ref);
        
    return $ref->[0];                    
    
}

sub get_hash {
    my $self = shift;    
    my $args = shift;
    my $params = shift;

    my $ldap = $self->ldap();
        
    # compose a list of command arguments
    my $template_vars = {
       ARG => $args,
    };
    
    my $mesg = $ldap->search(
        $self->_build_search_options($template_vars),
    );
       
    if ($mesg->count() == 0) {
        return $self->_node_not_exists('');
    }
    
    if ($mesg->count() > 1) {
        die "More than one entry found - result is not unique."
    }
    
    my $entry = $mesg->entry(0);    
    my $dn = $entry->dn();
    my %attribs = ( pkey => $dn );
    my ($target, $source);      
    
    while (($target, $source) = each %{$self->attrmap()}) {        
        my $ref = $entry->get_value ( $source, asref => 1 );
        next unless ($ref);            
        
        # return multivalued attributes as array ref if "deep" is set 
        if (@{$ref} > 1 && $params->{deep}) {
            $attribs{$target} = $ref;    
        } else {
            $attribs{$target} = $ref->[0];
        }                                        
    }    
    return \%attribs;     
    
}

sub get_keys {
    my $self = shift;    
    
    my $hash = $self->get_hash( @_ );
    return undef unless($hash); 
    return keys %{ $hash };
}

1;
__END__

=head1 NAME

Connector::Proxy::Net::LDAP::Single

=head1 DESCRIPTION

Search and return a single item from the repository. Attributes from the ldap 
entry can be mapped to the returned structure using a map.

The connector will die if multiple entries are found.

see Connector::Proxy::Net::LDAP for basic configuration options

B<Warning: Do not set the attr property>

=head1 accessor methods

=head2 get

The attribute map must contain exactly one argument. Its value is the 
name of the ldap attribute which will be returned. If the attribute is 
multivalued, only the first value is returned.
  
=head2 get_hash

You need to define a map to assign the resulting ldap attributes to the 
returned hash structure. The maps keys remain keys whereas the value is 
set to the value of the ldap attribute with that name. Multivalued attributes 
are truncated to the first entry by default. To get them as array ref, set
the deep parameter to true C<{ deep => 1}>. 

    attrmap:
      certificate:usercertificate
      department:ou 
      
Note: the special name I<pkey> is reserved and contains the dn of the entry.

=head2 get_keys

Return the keys which are set in the resulting hash.
Keys that do not have a matching attribute value are not set.

=head2 get_list / get_size  

Not supported.
  
