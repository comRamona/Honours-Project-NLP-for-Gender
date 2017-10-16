# Module to control mxterminator
# 
# Usage:
#
# use Clair::Utils::MxTerminator;
# Clair::Utils::MxTerminator::init;
# my @sentences = Clair::Utils::MxTerminator::do_document($document_text);
#
# There's an internal "send document chunk" interface but it's not too useful
# since either way the whole document really has to be sent before you should try
# reading sentences - get_next_sentence will block if there's no next sentence.
# If you really want to live dangerously, take a look at the do_document method.
#
#
# $Id: MxTerminator.pm,v 1.1 2005/09/29 14:51:32 aelkiss Exp $

package Clair::Utils::MxTerminator;
#use lib '/data0/projects/nih/biomead/src/perllib';
use IO::Handle qw(_IONBF);
use IO::File;
use IPC::Open2;
use IO::Select;
use Clair::Config;
#use IO::Tee;
use Carp;
use bytes;

my $config;
if (defined $JMX_HOME) {
    $config = {
        mxtools => {
    	#modelpath => '/data0/projects/nih/biomead/data/biomed_eos.project',
	#modelpath => '/data2/tools/jmx_new/eos.project',
	modelpath => "$JMX_MODEL_PATH",
	mxtoolspath => $JMX_HOME,
	mxtoolsjava => 'java'
        }
    };
}

our($in,$out,$pid,@linebuffer,$s_error,$s_read,$s_write);

sub reinit {

  kill 9, $pid;
  wait();
  init($config);
}

sub init {

  # Start up MxTerminator

  my $modelpath = $config->{mxtools}{modelpath};
  my $mxpath = $config->{mxtools}{mxtoolspath};
  $ENV{CLASSPATH} = '$mxpath/mxpost.jar:$mxpath';

  my $java = $config->{mxtools}{mxtoolsjava};
  $java = '/usr/um/bin/java' if `which java` =~ /^no java/;
    

  # Send stderr to /dev/null to avoid get inundated with unnecessary messages
  $pid = open2($in,$out,'$java eos.TestEOS $modelpath 2> /dev/null') or die("Couldn't start MxTerminator: $!\n");

  # Set to unbuffered IO

  binmode $out, ":utf8";
  binmode $in, ":utf8";

  $out->autoflush(1);
  $in->autoflush(1);

  $out->blocking(0);

  $s_error = new IO::Select;

  $s_error->add($out);
  $s_error->add($in);

  $s_read = new IO::Select;
  $s_read->add($in);

  $s_write = new IO::Select;
  $s_write->add($out);


}

sub do_document {

  my ($txt) = @_;

  # Ensure text ends with a newline - otherwise get_next_sentence might block
  chomp $txt;
  $txt .= "\n";
  
  send_document($txt);


  my @sentences = ();

  while (my $sentence = get_next_sentence()) {
    push(@sentences,$sentence);
  }

  return @sentences;
}

# methods for sending parts of a document at a time

sub mxterm_start_document {

  # turn on nonblocking IO & clear buffer

  @linebuffer = ();

  $in->blocking(0);
  $out->blocking(0);

}

sub send_document_chunk {

  my $chunk = shift;

  while (defined (my $line = $in->getline())) {
    push(@linebuffer,$line);
  }

  # if it would block, wait up to 5 seconds until either we can read
  # or write and then try again.

  my $written = 0;

  # Only exit out of this when the write filehandle is ready
  while (1) {

    my @ready = IO::Select::select($s_read,$s_write,$s_error,10);

    foreach my $error (@{$ready[2]}) {
      die("Error waiting for MxTerminator to be ready: $!");
    }

    foreach my $write_ready (@{$ready[1]}) {
      $written = $write_ready->syswrite($chunk);
      die("Error writing: $!") if not defined $written;
#      print STEDRR "MXTERMINATOR WRITE: '", substr($chunk,0,$written), "'\n";

      # return if we managed to write the whole thing
      return if($written == length($chunk));
      # otherwise shrink the chunk and go back into the select
      $chunk = substr($chunk,$written);

    }

    # if we can read (there should only be one filehandle in the array)
    # read stuff, then redo the select

    foreach my $read_ready (@{$ready[0]}) {
      while (defined (my $line = $in->getline())) {
#	print STDERR 'MXTERMINATOR READ: ', "'$line'\n";
	push(@linebuffer,$line);
      }
    }
  }

  die("MxTerminator blocked for more than 10 seconds: $!");
}

sub mxterm_end_document {

  send_document_chunk(".\n<DOCEND>.\n.\n\n");

  # turn off nonblocking IO

  $in->blocking(1);
}

# send entire document

sub send_document {

  my $document = shift;

  mxterm_start_document();
  send_document_chunk($document);
  mxterm_end_document();

}

# gets next sentence from mxterminator. returns undef if
# nothing available on stdin (i.e. reading would block)

sub get_next_sentence {

  # break out of loop when we find a sentence
  # to keep instead of just junk

  while (1) {

    my $sentence;

    if (@linebuffer) {
      $sentence = shift(@linebuffer);
#      print STDERR "MXTERMINATOR GETSENTENCE (BUFFERED): '$sentence'\n";
    } else {
      $sentence = $in->getline;
#      print STDERR "MXTERMINATOR GETSENTENCE (BLOCKING): '$sentence'\n";

    }

 #   next if ($sentence eq '');
    chomp($sentence);

   
    if ($sentence eq "<DOCEND>. ") {
#      print STDERR "MXTERMINATOR GETSENTENCE RETURNING UNDEF\n";
      return undef;
    }
    if ($sentence eq ". <DOCEND>. ") {
#      print STDERR "MXTERMINATOR GETSENTENCE RETURNING UNDEF\n";
      return undef;
    }

    # ignore forced sentence breaks and return the next sentence
    next if ($sentence eq "<IGNORE>. ");
    next if ($sentence eq ". <IGNORE>. ");
    next if ($sentence eq ". ");
    next if (!$sentence);

#    print STDERR "MXTERMINATOR GETSENTENCE RETURNING '$sentence'\n";
    return $sentence;
  }
}


1;
