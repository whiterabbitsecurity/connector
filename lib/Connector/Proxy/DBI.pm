# Connector::Proxy::DBI
#
# Proxy class for fetching a value from using DBI
#
# Written by Oliver Welter and Martin Bartosch for the OpenXPKI project 2013

package Connector::Proxy::DBI;

use strict;
use warnings;
use English;
use DBI;
use Data::Dumper;
use Data::Dumper;

use Moose;
extends 'Connector::Proxy';


has dbuser => (
    is  => 'rw',
    isa => 'Str',
);

has password => (
    is  => 'rw',
    isa => 'Str',
);

has table => (
    is  => 'rw',
    isa => 'Str',
);

has column => (
    is  => 'rw',
    isa => 'Str',
);

has condition => (
    is  => 'rw',
    isa => 'Str',
);
 
has _dbi => (
    is  => 'ro',
    isa => 'Object',
    lazy => 1,
    builder => '_dbi_handle'
);


sub _dbi_handle {
    
    my $self = shift;

    my $dsn = $self->LOCATION();
    
    my $dbh = DBI->connect($dsn, $self->dbuser(), $self->password(), 
        { RaiseError => 1, LongReadLen => 1024 });

    if (!$dbh) {
        $self->log()->error('DBI connect failed. DSN: '.$dsn. ' - Error: ' . $! );
        die "DBI connect failed: $!"
    }    
    return $dbh;    

}

sub get { 

    my $self = shift;    
    my @path = $self->_build_path( shift );
    
    
    my $query = sprintf "SELECT %s FROM %s WHERE %s", 
        $self->column(), $self->table(), $self->condition();
    
    $self->log()->debug('Query is ' . $query);
        
    my $sth = $self->_dbi()->prepare($query);
    $sth->execute( @path );

    my $rows = $sth->fetchall_arrayref();
    
    # hmpf
    unless (ref $rows eq 'ARRAY') {
       $self->log()->error('DBI did not return an arrayref');
       die "DBI did not return an arrayref.";
    }

    $self->log()->trace('result is ' . Dumper $rows );
       
    if (scalar @{$rows} == 0) {
        return $self->_node_not_exists( @path );
    } elsif (scalar @{$rows} > 1) {
        $self->log()->error('Ambiguous (multi-valued) result');
        return $self->_node_not_exists( @path );
    }
    
    $self->log()->debug('Valid return: ' . $rows->[0]->[0]);
    return $rows->[0]->[0];
    
}
     
sub get_list { 

    my $self = shift;    
    my @path = $self->_build_path( shift );
    
    my $query = sprintf "SELECT %s FROM %s WHERE %s", 
        $self->column(), $self->table(), $self->condition();
    
    $self->log()->debug('Query is ' . $query);
        
    my $sth = $self->_dbi()->prepare($query);
    $sth->execute( @path );

    my $rows = $sth->fetchall_arrayref();
    
    # hmpf
    unless (ref $rows eq 'ARRAY') {
       $self->log()->error('DBI did not return an arrayref');
       die "DBI did not return an arrayref.";
    }
       
    if (scalar @{$rows} == 0) {
        return $self->_node_not_exists( @path );
    }
    my @result;
    foreach my $row (@{$rows}) {        
       push @result, $row->[0];  
    }
       
    $self->log()->trace('result ' . Dumper \@result);
       
    $self->log()->debug('Valid return, '. scalar @result .' lines');
    return @result;
    
}
  
no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__


=head 1 Name

Connector::Proxy::DBI

=head 1 Description

Use DBI to make a query to a database, supports calls to a single column only.

=head1 Usage

=head2 Configuration 
    
    my $con = Connector::Proxy::DBI->new({
        LOCATION => 'DBI:mysql:database=openxpki;host=localhost',
        dbuser => 'queryuser',
        password => 'verysecret',    
        table => 'mytable',    
        column => 1,
        condition => 'id = ?',         
    });

=head2 get

Will return the value of the requested column of the matching row. If no row or
more than one row is found, undef is returned (dies if die_on_undef is set).

=head2 get_list

Will return the selected column of all matching lines as a list. If no match is
found undef is returned (dies if die_on_undef is set).

=head2 get_size/get_meta/get_hash 

not supported, yet




