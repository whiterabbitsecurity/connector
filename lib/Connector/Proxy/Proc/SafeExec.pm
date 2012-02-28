# Connector::Proxy::Proc::SafeExec
#
# Connector class for running system commands
#
# Written by Martin Bartosch for the OpenXPKI project 2012
#
package Connector::Proxy::Proc::SafeExec;

use strict;
use warnings;
use English;
use Proc::SafeExec;
use File::Temp;
use Try::Tiny;
use Template;

use Data::Dumper;

use Moose;
extends 'Connector::Proxy';

has args => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    default => sub { [] },
    );

has timeout => (
    is => 'rw',
    isa => 'Int',
    default => 5,
    );

has chomp_output => (
    is => 'rw',
    isa => 'Bool',
    default => 1,
    );


sub _build_config {
    my $self = shift;

    if (! -x $self->LOCATION()) {
	die("Specified system command is not executable: " . $self->LOCATION());
    }
    
    return 1;
}

# this method always returns the file contents, regardless of the specified
# key
sub get {
    my $self = shift;

    my $template = Template->new(
	{
	});

    # compose a list of command arguments
    my $template_vars = {
	ARG => \@_,
    };

    # process configured system command arguments and replace templates
    # in it with the passed arguments, accessible via [% ARG.0 %]
    my @cmd_args;
    foreach my $item (@{$self->args()}) {
	my $value;
	$template->process(\$item, $template_vars, \$value) || die "Error processing argument template.";
	push @cmd_args, $value;
    }
    
    
    my $stdout = File::Temp->new();
    my $stderr = File::Temp->new();

    # compose the system command to execute
    my @cmd;
    push @cmd, $self->{LOCATION};
    push @cmd, @cmd_args;
    
    my $command = Proc::SafeExec->new(
	{
	    exec => \@cmd,
#	    stdin  => 'new',
	    stdout => \*$stdout,
	    stderr => \*$stderr,
	});

    try {
	local $SIG{ALRM} = sub { die "alarm\n" };
	alarm $self->timeout();
	$command->wait();
    } catch {
	if ($_ eq "alarm\n") {
	    die "System command timed out after " . $self->timeout() . " seconds";
	}
	if ($_ ne "Child was already waited on without calling the wait method\n") {
	    die $_;
	}
    } finally {
	alarm 0;
    };
    
    my $stderr_content = do {
	open my $fh, '<', $stderr->filename;
	local $INPUT_RECORD_SEPARATOR;
	<$fh>;
    };

    if ($command->exit_status() != 0) {
 	die "System command exited with return code " . ($command->exit_status() >> 8) . ". STDERR: $stderr";
    }

    my $stdout_content = do {
	open my $fh, '<', $stdout->filename;
	local $INPUT_RECORD_SEPARATOR;
	<$fh>;
    };

    if ($self->chomp_output()) {
	chomp $stdout_content;
    }
    
    return $stdout_content;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head 1 Name

Connector::Builtin::System::Exec

=head 1 Description

