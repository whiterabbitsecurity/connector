# Connector::Proxy::Net::LDAP
#
# Proxy class for accessing LDAP directories
#
# Written by Scott Hardin,  Martin Bartosch and Oliver Welter for the OpenXPKI project 2012
#
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
    isa => 'ArrayRef|Str',    
    trigger => \&_convert_attrs
    );

has scope => (
    is  => 'rw',
    isa => 'Str',
    );

has timeout => (
    is  => 'rw',
    isa => 'Int',
    );

has timelimit => (
    is  => 'rw',
    isa => 'Int',
    );

has sizelimit => (
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


has bind => (
	is  => 'ro',
    isa => 'Net::LDAP',
    reader => '_bind',  
    builder => '_init_bind',
    lazy => 1,  
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
    my $value;
    if (ref $filter eq '') {
	my $template = Template->new(
	    {
	    });	
	
	$template->process(\$filter, $arg, \$value) || die "Error processing argument template.";
	$options{filter} = $value;
    } else {
    $options{filter} = $filter;
    }
    
    # Add the attributes to the query to return only the ones we are aksed for
    # Will not work if we allow Filters
    $options{attrs} = $self->attrs;
     
    return %options;
}

# If the attr property is set using a string (necessary atm for Config::Std)
# its converted to an arrayref. Might be removed if Config::* improves 
# This might create indefinite loops if something goes wrong on the conversion! 
sub _convert_attrs {
    my ( $self, $new, $old ) = @_; 

    # Test if the given value is a non empty scalar
    if ($new && !ref $new && (!$old || $new ne $old)) {
        my @attrs = split(" ", $new);
        $self->attrs( \@attrs ) 
    }    
    
}

sub _init_bind {
    
    my $self = shift;
    my $ldap = Net::LDAP->new(    
        $self->LOCATION(),
        onerror => undef,
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
    return $ldap;    
}

sub ldap {
    # ToDo - check if still bound
    my $self = shift;    
    return $self->_bind;
}

sub get {
    my $self = shift;    
    my @args = @_;

    my $ldap = $self->ldap();
    
    # Look for Sub-Queries / Delimiter 
    # The current delimiter is sometimes part of the query, 
    # so we protect our subqueries using & as a prefix
    my $delimiter = $self->DELIMITER();            
    my $subquery;

    # We have subqueries   
    if ( $args[0] =~  /$delimiter&/) {        
        my @path = split /$delimiter&/, $args[0];
        $args[0] = shift @path;
        $subquery = shift @path;
    } 

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
    
    # The Connector Spec requires that only one scalar is returned
    # If there are multiple entries, we need to return the "keys" of them
    # As this would result in ugly dns, we use a hash value    
            
    # Case 1 - search for DN
    if (!$self->attrs) {
        
        if( $mesg->count() == 1 ) {
            my $found = $mesg->entry(0)->dn();
            #$ldap->unbind();  
            return $found;
        }
        
        # More than one Entry 
        # We are in the first query - create Hash List 
        if (!$subquery) {
            my @keylist;       
            foreach my $loop_entry ( $mesg->entries()) {        
                push @keylist, '&'.sha1_hex( $loop_entry->dn() );           
            }
            #$ldap->unbind();        
            return @keylist;
        }    
        
        # We are in a subquery - so look for the right entry
        foreach my $loop_entry ( $mesg->entries()) {
            if ($subquery eq sha1_hex( $loop_entry->dn() ) ) {            
                my $found = $loop_entry->dn();
                #$ldap->unbind();  
                return $found;                
            };           
        }        
        # Nothing found
        #$ldap->unbind();
        return;        
    } # This If returns in any sub case, so we go here only if we are in attrs search mode 
    
        
    # There might be more than one object and more than one attribute type and more than one entry 
    # in each type. We assume them all as alternatives (like certificate and certificate;binary)
    # and therefor load them all in one list. We use the hash on the value as lookup key
    # This has the next advantage that duplicate values disappear

    my %attribs;
    foreach my $loop_entry ( $mesg->entries() ) {            
        foreach my $attr (@{$self->attrs}) {
             my $ref = $loop_entry->get_value ( $attr, asref => 1 );
             next unless ($ref);
             foreach my $val ( @{$ref} ) {                            
                $attribs{'&'.sha1_hex($val)} = $val;    
             }
        }
    }    

    #$ldap->unbind();
        

    if (!%attribs) {
        return undef;
    }
        
    # Case 1 - Subquery - look for hash  
    if ($subquery) {
        return $attribs{ '&'.$subquery }; # Will be undef if not set, so thats ok
    }
    
    # Case 2 - Mainquery and only one attribute found
    if ( keys %attribs == 1 ) {
        return $attribs{ (keys %attribs)[0] };
    }
    
    # Case 3 - Multiple results in main query - return key list
    return keys %attribs;     
    
}

sub set {
    
    my $self = shift;
    my $path = shift;
    my $value = shift;
    
    my $basedn = $self->conn()->get('create.basedn');       
    my $rdnkey = $self->conn()->get('create.rdnkey');
    
    my $nodeDN = sprintf '%s=%s,%s', $rdnkey, $path, $basedn;    
    
    #print "LDAP Path $path\nValue $value \nDN $nodeDN\n";  
          
    $self->_checkNodeExists( $nodeDN );
        
    my $ldap = $self->ldap();
    
    # TODO Improve - try if value is already there, implement replace/add/unset
    
    my $attribute = $self->conn()->get('create.attribute');
    my $action = $self->conn()->get('create.action');
    $action = "replace" unless($action);
    
    # Different Action modes 
    
    if ($action eq "append") {
        $ldap->modify( $nodeDN , add => { $attribute => $value } );    
    } elsif($action eq "delete") {        
        $ldap->modify( $nodeDN , delete => { $attribute => $value } ) if ($value);
    } elsif (defined $value) {        
        $ldap->modify( $nodeDN , replace => { $attribute => $value } );
    } else {        
        $ldap->modify( $nodeDN , delete => [ $attribute ] );
    }
                    
    return 1;
       
}

sub _checkNodeExists {
        
    my $self = shift;
    my $uppath = shift;
    
    
    my $ldap = $self->ldap();
    
    # Search if the node we want to modify exists
    my $mesg = $ldap->search( base => $uppath, scope  => 'base', filter => '(objectclass=*)');
    
    #print Dumper( $mesg );
    
    
    if ( $mesg->count() == 1) {
        return 1;
    }
    
    # Query is ambigous - can this happen ?
    if ( $mesg->count() > 1) {
        die "There is more than one matching node.";
    }
    
    # No match, so split up the DN and walk upwards
    my $base_dn = $self->base;

    # Strip the base from the uppath and tokenize the rest    
    my $path = $uppath;
    $path =~ s/\,?$base_dn$//;  
    
    my $dn_parser = OpenXPKI::DN->new($path);
    my @dn_attributes = $dn_parser->get_parsed();
        
    #print Dumper( @dn_attributes );    
           
    my $currentPath = $base_dn;
    my @nextComponent;
    my $i;
    for ($i = scalar(@dn_attributes)-1; $i >= 0; $i--) {
        
        # For the moment we just implement single value components
        my $nextComponentKey = lc $dn_attributes[$i][0][0];
        my $nextComponentValue = $dn_attributes[$i][0][1];
        
        my $nextComponent = $nextComponentKey.'='.$nextComponentValue;
        
        # Search for the next node
        #print "Probe $currentPath - $nextComponent: ";                 
        $mesg = $ldap->search( base => $currentPath, scope  => 'one', filter => '('.$nextComponent.')' );
     
        # found, push to path and test next  
        if ( $mesg->count() == 1) {
            #print "Found\n";
            $currentPath = $nextComponent.','.$currentPath; 
            next;
        }

        #print Dumper( $mesg );        
        #print "not Found - i: $i\n\n";
                    
        # Reuse counter and list to build the missing nodes
        while ($i >= 0) {            
            $nextComponentKey = lc $dn_attributes[$i][0][0];
            $nextComponentValue = $dn_attributes[$i][0][1];            
            $currentPath = $self->_createNode($currentPath, $nextComponentKey, $nextComponentValue);
            $i--;    
        }
    }    
}

sub _createNode {
    
    my $self = shift;    
    my ($currentPath, $nextComponentKey, $nextComponentValue) = @_;
        
    my @objectclass = split " ", $self->conn()->get([ 'schema', $nextComponentKey , 'objectclass']);
            
    my $attrib = [
        objectclass => \@objectclass,
        $nextComponentKey => $nextComponentValue,
    ];
    
    # Default Values to push 
    my $values = $self->conn()->get_hash( [ 'schema', $nextComponentKey , 'values'] );
    
    foreach my $key ( keys %{$values}) {        
        push @{$attrib}, $key;
        my $val = $values->{$key};
        $val = $nextComponentValue if ($val eq 'copy:self');
        push @{$attrib}, $val;
    }
    
    my $newDN = sprintf '%s=%s,%s', $nextComponentKey, $nextComponentValue, $currentPath;
    
    #print "Create Node $newDN \n";
    #print Dumper( $attrib );
    
    my $result = $self->ldap()->add( $newDN, attr => $attrib );
    if ($result->is_error()) {
        die $result->error_desc;
    }
    
    return $newDN;
    
    
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

Connector::Proxy::Net::LDAP

=head1 DESCRIPTION

=head1 USAGE

=head2 minimal setup

    my $conn = Connector::Proxy::Net::LDAP->new({ 
	   LOCATION  => 'ldap://localhost:389', 
	   base      => 'dc=example,dc=org', 
	   filter  => '(cn=[% ARG.0 %])',	
    });    

    $conn->get('test@example.org');

Above code will run a query of C<cn=test@example.org against the server> 
using an anonymous bind. It will return

=over

=item The complete DN of the entry found with the query 

=item undef, if there is no matching entry

=item If there is more than one match, a list of artifical keys that must be appended
to the query to select one of them.   

=back

=head2 attribute search

    my $conn = Connector::Proxy::Net::LDAP->new( {
    	LOCATION  => 'ldap://localhost:389',
    	base      => 'dc=example,dc=org',
    	filter  => '(cn=[% ARG.0 %])',
    	attrs =>  ['usercertificate;binary','usercertificate'],
    	binddn    => 'cn=admin,dc=openxpki,dc=org',
    	password  => 'admin'
    });

    $conn->get('test@example.org');

Uses bind credentials and queries for entries having (at least) one of the 
mentioned attributes. Result is the same as above, besides that you get the 
content of the attribute field. 
  
=head2 setting values

If you run this connector "standalone", you need to provide the config via your
own connector instance in the "LOOPBACK" parameter.

If you run this inside Connector::Multi, just put the config on the level of the "class" attribute.

    [create]
    basedn: ou=Webservers,ou=Server CA3,dc=openxpki,dc=org
    rdnkey: cn
    attribute: userCertificate;binary
    action: replace   
    
If you now call C<$conn->set('www.example.org', <blob of certificate>);>, the given 
data is put into the C<userCertificate;binary> attribute field of 
C<cn=www.example.org,ou=Webservers,ou=Server CA3,dc=openxpki,dc=org>      

The action parameter determines if an attribute value is replaced or added to an entry 

=head3 append

The given value is appended to exisiting attributes. If undef is passed, the request is ignored. 

=head3 delete

The given value is deleted from the attribute entry. If there are more items in the attribute, 
the remaining values are left untouched. If the value is not present or undef is passed, 
the request is ignored.

=head3 replace

This is the default (the action parameter may be omitted). The passed value is set as the only 
value in the attribute. Any values (even if there are more than one) are removed. If undef is passed,
the whole attribute is removed from the node. 

=head2 autocreation of missing nodes

If you want the connector to autocreate missing nodes, you need to provide the
ldap properties of each node-class.

    [schema.cn] 
    objectclass: inetOrgPerson pkiUser

    [schema.cn.values]
    sn: copy:self
    ou: IT Department

You can specify multiple objectclass entries seperated by space.

The objects attribute is always set, you can use the special word C<copy:self>
to copy the attribute value within the object. The values section is optional.

=head2 Full example using Connector::Multi
    
    [ca1]
    myrepo@ = connector:connectors.ldap
    
    [connectors]
    
    [connectors.ldap]
    class = Connector::Proxy::Net::LDAP
    LOCATION = ldap://ldaphost:389
    base     = dc=openxpki,dc=org
    filter   = (cn=[% ARG.0 %])
    attrs    = userCertificate;binary
    binddn   = cn=admin,dc=openxpki,dc=org
    password = admin
    
    [connectors.ldap.create]
    basedn: ou=Webservers,ou=Server CA3,dc=openxpki,dc=org
    rdnkey: cn
    attribute: userCertificate;binary
    action: replace
    
    [connectors.ldap.schema.cn] 
    objectclass: inetOrgPerson
    [connectors.ldap.schema.cn.values]
    sn: copy:self
    
    [connectors.ldap.schema.ou] 
    objectclass: organizationalUnit


=head1 internal methods

=head2 _checkNodeExists

Check if a node exists. Missing nodes can be created if you have configured
the autocreate feature.

=head2 _createNode

Called by _checkPath to create a single node in the path. See above how to
configure this.
