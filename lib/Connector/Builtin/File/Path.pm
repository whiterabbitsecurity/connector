# Connector::Builtin::File::Path
#
# Proxy class for accessing files
#
# Written by Oliver Welter for the OpenXPKI project 2012
#
package Connector::Builtin::File::Path;

use strict;
use warnings;
use English;
use File::Spec;
use Data::Dumper;
use Template;

use Moose;
extends 'Connector::Builtin';


has file => (
    is  => 'rw',
    isa => 'Str',
);

has content => (
    is  => 'rw',
    isa => 'Str',
);

has ifexists => (
    is  => 'rw',
    isa => 'Str',
    default => 'replace'
);

sub _build_config {
    my $self = shift;

    if (! -d $self->{LOCATION}) {
	   confess("Cannot open directory " . $self->{LOCATION} );
    }
    
    return 1;
}

# return the content of the file
sub get {
    
    my $self = shift;
    my $file = shift;
   
    my $filename = $self->_sanitize_path( $file );

    my $content;
    if (-r $filename) {
	  $content = do {
	  local $INPUT_RECORD_SEPARATOR;
	  open my $fh, '<', $filename;
	  <$fh>;
      };
    }

    return $content;
}

# return the content of the file
sub set {
    
    my $self = shift;
    my $file = shift;
    my $data = shift;
   
    my $filename = $self->_sanitize_path( $file, $data );

    my $content;
    if ($self->content()) {
        $self->log()->debug('Process template for content ' . $self->content());
        my $template = Template->new({});        
        
        $data = { DATA => $data } if (ref $data eq '');
                
        $template->process( \$self->content(), $data, \$content) || die "Error processing content template.";
    } else {
        if (ref $data ne '') {
            die "You need to define a content template if data is not a scalar";
        }
        $content = $data;
    }

    my $mode = $self->ifexists();
    if ($mode eq 'fail' && -f $filename) {
        die "File $filename exists";
    }
    
    if ($mode eq 'silent' && -f $filename) {
        return;
    }
    
    if ($mode eq 'append' && -f $filename) {
        open FILE, ">>$filename" || die "Unable to open file for appending";
    } else {
        open FILE, ">$filename" || die "Unable to open file for writing";
    }
    
    print FILE $content;
    close FILE;
    
    #FIXME - some error handling might not hurt
    
    return 1;    
}


sub _sanitize_path {

    my $self = shift;
    my $arg = shift;
    my $data = shift;

    my $file;
    if ($self->file()) {
        my $pattern = $self->file();
        my $template = Template->new({});
        $self->log()->debug('Process template ' . $pattern);  
        $template->process( \$pattern, { ARGS => $arg, DATA => $data }, \$file) || die "Error processing argument template.";
    } else {
        $file = $arg;
    }

    $file =~ s/[^\s\w\.]//g;
    my $filename = $self->{LOCATION}.'/'.$file;

    $self->log()->debug('Filename evaluated to ' . $filename);
        
    return $filename;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 Name

Connector::Builtin::File::Path

=head1 Description

Highly configurable file writter/reader.

=head1 Parameters

=over
 
=item LOCATION

The base directory where the files are located. This parameter is mandatory.

=item file

Pattern for Template Toolkit to build the filename. 
The path components are available in the key ARGS. In set mode the unfiltered
data is available in key DATA.

=item content

Pattern for Template Toolkit to build the content. The data is passed 
"as is". If data is a scalar, it is wrapped into a hash using DATA as key.

=item ifexists

=over 2

=item * append: opens the file for appending write.

=item * fail: call C<die>

=item * silent: fail silently.

=item * replace: replace the file with the new content.

=back

=head1 Supported Methods

=head2 set

Write data to a file.  

    $conn->set('filename', { NAME => 'Oliver', 'ROLE' => 'Administrator' });

See the file parameter how to control the filename. 
By default, files are silently overwritten if they exist. See the I<ifexists> 
parameter for an alternative behaviour. 

=head2 get

Fetch data from a file. See the file parameter how to control the filename.

    my $data = $conn->set('filename');

=head1 Example

    my $conn = Connector::Builtin::File::Path->new({
       LOCATION: /var/data/
       file: [% ARGS %].txt
       content: Hello [% NAME %]
    });

    $conn->set('test', { NAME => 'Oliver' });
    
Results in a file I</var/data/test.txt> with the content I<Hello Oliver>.    

