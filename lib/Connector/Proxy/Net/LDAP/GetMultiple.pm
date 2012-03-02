# Connector::Proxy::Net::LDAP::GetHash
#
# Proxy class for accessing LDAP directories
# SubClass to return multiple entries/multiple attributes at once
# using one request
#
# Written by Oliver Welter for the OpenXPKI project 2012
#

# THIS CODE UNTESTED AND MIGHT NOT WORK AT ALL!

package Connector::Proxy::Net::LDAP;

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
    my @args = @_;

    my $ldap = $self->ldap();
    
    # compose a list of command arguments
    my $template_vars = {
       ARG => \@args,
    };
    
    my $mesg = $ldap->search(
        $self->_build_search_options($template_vars),
    );
       
    if ($mesg->count() == 0) {
        return;
    }
    
    my %result;
    # Case 1 - search for DN
    if (!$self->attrs) {       
        # Do the same artifical ids (sha1 on dn) to allow the keys to be used with the base connector
        foreach my $loop_entry ( $mesg->entries()) {
            my $dn = $loop_entry->dn();
            $result{ '&'.sha1_hex( $dn) } = $dn;         
        }
        $ldap->unbind();        
        return %result;
    } # This If returns in any sub case, so we go here only if we are in attrs search mode 
    
    # We create a two level hash, first level holds the artifical key, 
    # second level has the mapped attribtues. if the attribute is multi-valued
    # we return an array ref, otherwise a scalar
    
    foreach my $loop_entry ( $mesg->entries() ) {
        my $dn = $loop_entry->dn();
        my %attribs = ( pkey => $dn );        
        while (($target, $source) = each %{$this->attrmap()}) {
        
            my $ref = $loop_entry->get_value ( $source, asref => 1 );
            next unless ($ref);
            
            if (@{$ref} == 1) {
                $attribs{$target} = $ref->[0];                
            } else {
                $attribs{$target} = $ref;    
            }
        }        
        $result{ '&'.sha1_hex( $dn) } = \%attribs;        
    }    
    $ldap->unbind();
         
    
    # Case 3 - Multiple results in main query - return key list
    return $result;     
    
}


1;
__END__

=head1 NAME

Connector::Proxy::Net::LDAP::GetMultiple

=head1 DESCRIPTION

Return multiple datasets as hash on a request. Attributes from the ldap entry
are mapped to attributes of the returned hash using a specified map.

=head1 USAGE

see Connector::Proxy::Net::LDAP for basic configuration options

=head2 DN search

If called without an attribute map, this will return a hash of DNs found on 
the specified query. The value is the full DN as returned from the LDAP server, 
the key of each entry is the artifical key as used in the basic ldap connector.

B<Do not set the attr property as this results in unexpected behaviour>

=head2 attribute map search

You will get a two dimensional hash as a result. The keys on the first level
are as above, the value is a hash ref. The values in the hash are determined
by the attribute map. The maps keys remain keys whereas the value is set to 
the value of the ldap attribute with that name. Multivalued attributes are 
returned as an arrayref. 

    attrmap:
      certificate:usercertificate
      department:ou 

TODO: Configurierbar mit "force uniq"
