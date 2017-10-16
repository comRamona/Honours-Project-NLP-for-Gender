package Clair::Debug;

=head1 NAME

 B<package> Clair::Debug
 A simple class that Exports debugmsg and errmsg subs.

=head1 AUTHOR

 JB Kim
 jbremnant@gmail.com
 20070407

=head1 SYNOPSIS

 This module Exports simple functions to all other classes for debug
 message printing.

 In other modules that need debug or informational message printing, do
  
  use vars qw/$DEBUG/;
  use Clair::Debug;

 And call one of these two functions after instantiating the object:
  
  $self->debugmsg("test msg", 1); # only prints if $DEBUG is set > 1.
  $self->errmsg("test msg", 1); # dies after printing msg.


=head1 DESCRIPTION

 Other perl objects will use this module for printing debug messages
 according to the debug level. Designed to standardize the debug printing
 as well as other useful messages out to STDOUT. Other instantiated objects
 can access these methods simply from its own namespace (symbol table).

=cut


use strict;

=head1 EXPORTS

 exports &debugmsg($msg, $debuglevel) and &errmsg($msg, $die)

=cut


BEGIN {
	use Exporter();
	@Clair::Debug::ISA       = qw(Exporter);
	@Clair::Debug::EXPORT    = qw(&debugmsg &errmsg &_process_msg $DEBUG);
	# @Clair::Debug::EXPORT_OK = qw($DEBUG);
}

use vars qw/$DEBUG/;
use Data::Dumper;


=head1 METHODS

=cut

# --- Methods --- #

=head2 debugmsg

 Takes in a message and prints according to the current global
 debug level. The caller object and subroutine is specified within
 the brakets [].

=cut


sub debugmsg
{
	my ($self, $msg, $debuglevel) = @_;

	# caller routine contains the blessed object name and its subroutine
	my @caller_meta = caller(1);
	my $caller_tok = $caller_meta[3] || $0;
	my $returnmsg = $self->_process_msg($msg);	
	$msg = "[$caller_tok] $returnmsg\n";

	if($debuglevel <= $DEBUG)
	{
		print $msg;
		return $msg;
	}
}


=head2 errmsg

 Similar to the $self->debugmsg() subroutine above. Instead of merely 
 printing the debug message, this function will issue a 'die' call at
 the end of the second argument is true.

=cut

sub errmsg
{
	my ($self, $msg, $die) = @_;

	my @caller_meta = caller(1);
	my $caller_tok = $caller_meta[3] || $0;
	my $returnmsg = $self->_process_msg($msg);	
	$msg = "[FATAL $caller_tok] $returnmsg\n";

	if($die)
	{
		die $msg;
	}
	return $msg;
}

=head2 _process_msg

 Private subroutine that determines the datatype of $msg (type of reference)
 and returns it in scalar format. This function, too, needs to be exported
 so that other classes can fully use $self->debugmsg() and $self->errmsg() functions.

=cut

sub _process_msg
{
	my ($self, $msg) = @_;

	my $type = ref $msg;
	my $returnmsg = (! $type || $type eq "SCALAR") ? $msg : Dumper($msg);

	return $returnmsg;
}


1;
