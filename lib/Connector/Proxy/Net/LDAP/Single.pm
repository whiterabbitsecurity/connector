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
    
    if ($mesg->is_error()) {
        $self->log()->error("LDAP search failed error code " . $mesg->code() . " (error: " . $mesg->error_desc() .")" );
        return $self->_node_not_exists( $args );
    }
       
    if ($mesg->count() == 0) {
        return $self->_node_not_exists($args);
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

sub set {
    
    my $self = shift;
    my $args = shift;
    my $value = shift;
    my $params = shift;
    
    my $ldap = $self->ldap();
    my $entry; 
    
    $self->log()->debug('Set called on ' . $args);
    
    # Check if a pkey/dn is passed
    if ($params->{pkey}) {        
        $entry = $self->_getbyDN( $params->{pkey} );
        if (!defined $entry) {
            $self->log()->warn('Set by dn had no result: '.$params->{pkey});            
            return $self->_node_not_exists($args);
        }
    } else {
        # Try to find the entry
        
        my $template_vars = { ARG => $args };
    
        my $mesg = $ldap->search(
            $self->_build_search_options($template_vars, { noattrs => 1}),
        );
        
        if ($mesg->is_error()) {
            $self->log()->error("LDAP search failed error code " . $mesg->code() . " (error: " . $mesg->error_desc() .")" );
            return $self->_node_not_exists( $args );
        }
    
        if ($mesg->count() > 1) {
            $self->log()->error('Set by filter had multiple results: '.$args);
            die "More than one entry found - result is not unique."
        }
        
        # Check if autocreate is configured   
        if ($mesg->count() == 1) {
            $entry = $mesg->entry(0);        
            $self->log()->debug('Entry found ' . $entry->dn());
        } else {                                 
            $entry = $self->_triggerAutoCreate( $args );
            return $self->_node_not_exists($args) if (!$entry);
        } 
    }

    my $action = $self->action();
    $self->log()->debug('Action is '.$action);
    
    # We accept only a hash as value
    if (ref $value ne 'HASH') {                
        $self->log()->error('The value must be a hash reference.');       
        die "The value must be a hash reference"
    }
    
    while (my ($source, $attribute) = each %{$self->attrmap()}) {      
        if (!$attribute) {
            $self->log()->error('Attribute for '.$source.' is undef.');       
            die "Attribute for '.$source.' is undef.";
        }
        if (exists $value->{$source}) {
            my $value = $value->{$source};
            if ($action eq "append") {
                $self->log()->debug('Append '.$value.' to Attribute '.$attribute);
                $entry->add( $attribute => $value );    
            } elsif($action eq "delete") {
                $self->log()->debug('Delete '.$value.' from Attribute '.$attribute);        
                $entry->delete( $attribute => $value ) if ($value);
            } elsif (defined $value) {
                $self->log()->debug('Replace Attribute '.$attribute.' with '.$value);        
                $entry->replace( $attribute => $value );
            } else { # Implicit delete - replace with an undef value
                $self->log()->debug('Remove Attribute '.$attribute);      
                $entry->delete( $attribute => undef );
            }
        }
    }

    my $mesg = $entry->update( $ldap );
    if ($mesg->is_error()) {
        $self->log()->error("LDAP update failed error code " . $mesg->code() . " (error: " . $mesg->error_desc() . ")" );
        return $self->_node_not_exists( $args );
    }
    
    return 1;
}

1;
__END__

=head1 NAME

Connector::Proxy::Net::LDAP::Single

=head1 DESCRIPTION

Search and return a single item from the repository. Attributes from the ldap 
entry can be mapped to the returned structure using a map.

The connector will die if multiple entries are found.

=head1 configuration options

See Connector::Proxy::Net::LDAP for basic configuration options

The class needs a map of attribute names to map between the returned hash
and the names of the ldap attributes.

 connector:
    LOCATION:...
    ....
    attrmap:
      certificate:usercertificate
      department:ou
        
B<Warning: Do not set the attr property>

=head1 accessor methods

=head2 get

Not supported.

=head2 get_hash

You need to define a map to assign the resulting ldap attributes to the 
returned hash structure. The maps keys remain keys whereas the value is 
set to the value of the ldap attribute with that name. Multivalued attributes 
are truncated to the first entry by default. To get them as array ref, set
the deep parameter to true C<{ deep => 1}>. 
      
Note: the special name I<pkey> is reserved and contains the dn of the entry.

=head2 get_keys

Return the keys which are set in the resulting hash.
Keys that do not have a matching attribute value are not set.

=head2 get_list / get_size  

Not supported.
  
=head2 set

Set attributes of a node, if configured will create a non-exisiting node.
The set method requires a hash as value parameter.

You can control how existing attributes in the node are treated and if missing
nodes are created on the fly. See I<Connector::Proxy::Net::LDAP> for details.

=head3 Set multiple attributes on an existing node

The connector first does a search similar to its C<get> method based on the 
passed filter arguments. If exactly one entry is found, it works like the 
inverse of the I<get_hash> method. It needs an attributemap and 
maps all values from the input hash to the ldap attributes. Only keys which
are present in the input array are handled.

=head3 Set operation when the dn is known

If you used another ldap operation before and already know the dn, you can pass
this dn as parameter I<pkey> to the set method. 

    $conn->set('John Doe', { mail => <new mail address>}, { pkey => $dn });
    
The dn is returned by example by the C<get_hash> method.
    
=head3 Set operation with node autocreation

To enable the automated creation of missing nodes, look for the corresponding 
section in the base class I<Connector::Proxy::Net::LDAP>.
