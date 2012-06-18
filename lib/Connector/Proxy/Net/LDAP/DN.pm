# Connector::Proxy::Net::LDAP::DN
#
# Proxy class for accessing LDAP directories
# The class is designed to find and return one to many matching records
# in an ldap repository and return their DNs.
# Using the set function you can create and delete entries.
#
# Written by Oliver Welter for the OpenXPKI project 2012
#
    
# FIXME - we need to find a syntax to pass multiple arguments in by 
# all possible allowed path specs which is a problematic with
# Search Strings having the delimiter as character.....
# For now we just take is as it comes and assume a string as 
# the one and only argument 

package Connector::Proxy::Net::LDAP::DN;

use strict;
use warnings;
use English;
use Net::LDAP;

use Moose;
extends 'Connector::Proxy::Net::LDAP';

sub get_list {
    
    my $self = shift;    
    my $args = shift;

    my $ldap = $self->ldap();
     
    my $mesg = $ldap->search(
        $self->_build_search_options( { ARG => $args } ),
    );
    
     if ($mesg->is_error()) {
        $self->log()->error("LDAP search failed error code " . $mesg->code() . " (error: " . $mesg->error_desc() .")" );
        return $self->_node_not_exists( $args );
    }
     
    my @list;  
       
    if ($mesg->count() == 0) {
        $self->_node_not_exists( $args );
        return @list;
    }
    
     foreach my $loop_entry ( $mesg->entries()) {
        push @list, $loop_entry->dn();
     }
     
     return @list;
     
}

sub get_size {

    my $self = shift;    
    my $args = shift;

    my $ldap = $self->ldap();
     
    my $mesg = $ldap->search(
        $self->_build_search_options( { ARG => $args } ),
    );     
    return $mesg->count();
}
    
sub set {
    
    my $self = shift;
    my $args = shift;
    my $value = shift;
    my $params = shift;
    
    my $ldap = $self->ldap();
    
    if (!$params->{pkey}) {
        $self->log()->error('You must pass the pkey as parameter to delete an entry.');            
        die 'You must pass the pkey as parameter to delete an entry.';                    
    }     
         
    my $mesg = $ldap->search(
        $self->_build_search_options( { ARG => $args }, { noattrs => 1} ),
    );
    
    if ($mesg->is_error()) {
        $self->log()->error("LDAP search failed error code " . $mesg->code() . " (error: " . $mesg->error_desc() .")" );
        return $self->_node_not_exists( $args );
    }
           
    if ($mesg->count() == 0) {
        $self->_node_not_exists( $args );
        return undef;
    }
    
    my $match_dn = lc($params->{pkey});
     foreach my $entry ( $mesg->entries()) {
        if (lc($entry->dn()) eq $match_dn) {
            $entry->delete();
            #$entry->update( $ldap ); # Looks like delete is effective immediately
            
            my $mesg = $entry->update( $ldap );
            if ($mesg->is_error()) {
                $self->log()->error("LDAP update failed error code " . $mesg->code() . " (error: " . $mesg->error_desc() . ")");
                return $self->_node_not_exists( $args );
            }
            $self->log()->debug('Delete LDAP entry by DN: '.$params->{pkey});
            return 1;
        }
    }        
         
    $self->log()->warn('DN to delete not found in result: '.$params->{pkey});            
    return $self->_node_not_exists($args);
           
}

1;
__END__

=head1 NAME

Connector::Proxy::Net::LDAP::DN

=head1 DESCRIPTION

The class is designed to find and return the dn of matching records.
It is possible to delete entries from the repository using the set method.
 
see Connector::Proxy::Net::LDAP for basic configuration options

=head1 accessor methods

=head2 get

Not supported.

=head2 get_list

Return the list of DNs, that match the filter (configuration + path value).

=head2 get_size

Return the number of entries in the list of I<get_list>.
 
=head2 get_hash / get_keys

Not supported.
 
=head2 set

This method can be used to remove entire nodes from the ldap repository.
For security reasons, you can remove only entries that are matched by the 
filter. To remove an entry, use the same path as used with I<get_list>,
pass I<undef> as value and pass the DN to delete with the pkey attribute.

    $conn->set('John*', undef, { pkey => 'cn=John Doe,ou=people...'}) 



