package Clair::Network::Writer::PajekProject;
use Clair::Network::Writer;
@ISA = ("Clair::Network::Writer");

use strict;
use warnings;
use Graph;

use vars qw($VERSION);

$VERSION = '0.01';


=head1 NAME

Clair::Network::Writer::PajekProject - Class for writing Pajek project files

=cut

=head1 SYNOPSIS

my $export = Clair::Network::Writer::PajekProject->new();
$export->set_name("name");
$export->write_network($net, "name", partition => 'best', dirname => 'dir');

=cut

=head1 DESCRIPTION

This class will write a network object into a set of Pajek project files.

    $self->export2PajekProject(partition => $partition)
    $self->export2PajekProject(partition => $partition, dirname => $dirname)

Creates a Pajek-formatted file representing the network. $partition
can either be "best", in which case the Pajek file will include a
partition that labels vertices according to the .bestComm file, or a
number. If $partition is a number, the Pajek file will include a
partition that divides the network into that many communities.

$dirname is the location of the .bestComm and .join files, as well as
the location to which the output file will be written. If $dirname
isn't given, the location to read and write from is the location the
current working directory.

=cut


sub _write_network {
  my $self = shift;
  my $net = shift;
  my $filename = shift;
  my %parameters = @_;

  my $partition = $parameters{partition};

  my $networkName = "";
  if (not defined $self->{name}) {
    $networkName = "network";
  } else {
    $networkName = $self->{name};
  }

  # Creates Pajek project file from this network.
  # The partition variable can be 'best', in which case the function will
  #  read the .bestComm file produced by communityFind() to determine the
  #  partition to place in the project file. Alternatively, partition can
  #  be the number of communities to break the network into; the function
  #  will read the .joins file produced by the communityFind() algorithm
  #  to determine the correct partition.

  my $dirname = "";

  if (exists $parameters{dirname}) {
    if ( -d $parameters{dirname}) {
      $dirname = $parameters{dirname}."/";
    } else {
      print STDERR "\n**Directory does not exist: $parameters{dirname}\n";
      print STDERR "**Printing to local directory.\n\n";
      $dirname = "./";
    }
  } else {
    $dirname = "./";
  }

  my $name = $self->{name};
  my $pajfile = $dirname . $name . "_" . $partition . ".paj";

  open(PAJ,">", $pajfile) or die "Clair::Network::export2PajekProject: Cannot open Pajek project file $pajfile for writing.\n";

  print PAJ "*Network $name\n";
  my $nodeNum = $net->num_nodes;
  print PAJ "*Vertices $nodeNum\n";
  my @nodes = $net->{graph}->vertices;
  my $label;
  foreach ( sort {$a <=> $b} @nodes ) {
    $label = $net->get_vertex_attribute($_,"label");
    print PAJ "$_ \"$label\"\n";
  }
  print PAJ "*Edges\n";
  my $weight;
  foreach ( sort {${$a}[0] <=> ${$b}[0] } $net->{graph}->edges ) {
    print PAJ "${$_}[0] ${$_}[1] ";
    print PAJ $net->get_edge_weight(${$_}[0],${$_}[1]), "\n";
  }


  my $lines = "";
  if ( $partition eq "best" ) { # use the partition with the greatest Q rating
    my $partfile = $dirname . $name . ".bestComm";
    open(PART, "<", $partfile) or die "Clair::Network::export2PajekProject: Cannot open $partfile for reading.";
    while ( <PART> ) {
      $lines .= $_;
    }
    close(PART);

    if ($lines ne "") {
      print PAJ "*Partition $name" . "_" . "best\n";
      print PAJ "*Vertices $nodeNum\n";
      foreach ( split(/\n/,$lines) ) {
        my $l = $_;
        $l =~ s/^\s+|\s+$//g;
        $l =~ s/\d+\s+(\d+)$/$1/;
        print PAJ "$l\n";
      }
    }
  } else {

    if ( $partition < $nodeNum && $partition > 0 ) {
      ## Use the partition that creates $partition communities
      my $joins = $dirname . $name . ".joins";
      open(PART, "<", $joins) or die "Clair::Network::export2PajekProject: Cannot open $joins for reading.";
      while ( <PART> ) {
        $lines .= $_;
      }
      close(PART);
      if ($lines ne "") {
        print PAJ "*Partition $name" . "_" . "$partition\n";
        print PAJ "*Vertices $nodeNum\n";
        my %comLab;
        foreach ( @nodes ) {
          $comLab{$_} = $_;
        }
        my $j;
        my $i;
        my $cnum;
        my $oldLab;
        foreach ( split(/\n/,$lines) ) {
          my $l = $_;
          $l =~ /^(\d+)\s+(\d+)\s+(\d+).*/;
          $j = $1;
          $i = $2;
          $cnum = $3;

          $oldLab = $comLab{$i};
          foreach ( keys %comLab ) {
            if ( $comLab{$_} eq $oldLab ) {
              $comLab{$_} = $comLab{$j};
            }
          }
          if ($cnum == $partition) {
            last;
          }
        }

        foreach ( sort {$a <=> $b} keys %comLab ) {
          print PAJ $comLab{$_}, "\n";
        }

      }
    }
  }

  close(PAJ);
}

1;

