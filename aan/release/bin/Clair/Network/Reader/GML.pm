package Clair::Network::Reader::GML;
use Clair::Network::Reader;
@ISA = ("Clair::Network::Reader");

use strict;
use warnings;
use Clair::Network;

our @EXPORT_OK   = qw($verbose);

use vars qw($verbose $VERSION);

$VERSION = '0.01';


=head1 NAME

Clair::Network::Reader::GML - Class for reading in GML network files

=cut

=head1 SYNOPSIS

my $reader = Clair::Network::Reader::GML->new();
my $net = $reader->read_network($filename);

=cut

=head1 DESCRIPTION

This class will read in a GML format graph file into a Network object.

$cfn->readGMLFile($filename,$ignoreweights)

This routine will read GML formatted file and add those edges/nodes to
the existing graph. Not every GML term is utilized; this function only
considers the terms node, edge, label, value, source and target.

If a node[] in the file includes a "label XXXX" term, XXXX is used as
the new node label attribute. node[] expressions without label terms
will be cause the node to be given a default label "N$id". If the
node[] in the file includes a "value XXXX", value is added as an
attribute for that node, with XXXX as its value. All node[] in the
file must include an "id X" term; those that do not will be ignored.

If a edge[] in the file includes a "value XXXX" term, XXXX is
considered to be the edge weight. If the edge previously existed in
the graph, the new weight is added to the old one. All edge[] in the
file must include both a "source X" and a "target X" term; those that
do not will be ignored. If the nodes specified by the source and
target terms do not exist in the graph, they will be added, with
default labels.

If $ignoreweights is set to true, than the actual added weight for
every edge will be 1, regardless of the value listed in the edge[]
block. This allows the construction of an idential graph with uniform
(1) weights.

For more information:
http://www.infosun.fim.uni-passau.de/Graphlet/GML/

=cut

sub _read_network {
  my $self = shift;
  my $file = shift;
  my %parameters = @_;

  my $ignoreweights = $parameters{ignoreweights};

  my $net = Clair::Network->new(directed => 1);

  # Will try to build a graph from a GML formatted file. Any nodes or edges
  # in that file will be added to the existing graph. If the GML file
  # specifies numeric weights with and edge 'value' identifier, those
  # edge weights will be used. Otherwise, an edge weight of 1 is the default.

  # If the gml file includes weights and $ignoreweights is set to 1, then all those
  # weights will be discarded; the edges will have a weight equal to their previous
  # weight + 1.

  # Since Matlab, Pajek can't handle nodes with an id label of 0, if the .gml file
  # has a node with a 0 id, all the ids in the file will be incremented by 1 to
  # avoid a problem.

  if ($verbose) { print STDERR "\n****    READING GML FILE $file    ****\n"; }
  open(GML, "<", $file);

  my @lines;
  my $l;
  my $id0Flag = 0;
  while ( $l = <GML> ) {
    $l =~ s/^\s+|\s+$//g;
    $l =~ s/\[|\]//g;
    $l =~ s/^\s+|\s+$//g;
    chomp $l;
    if ( $l =~ /^node|edge|id|label|source|target|value/ ) {
      if ( $l =~ /id 0/ ) {
        $id0Flag = 1;
      }
      push @lines, $l;
    }
  }
  close GML;

  my $i;
  my ($id, $label,$value,$source,$target);
  for ($i = 0; $i<=$#lines; $i++) {
    if ( $lines[$i] eq "node" && $i < $#lines ) {
      $id = "undef";
      $label = "undef";
      $value = "undef";
      if ( $lines[$i+1] =~ /^id\s*(.*)/ ) {
        $id = $1;
        if ( $id0Flag ) {
          $id++;
        }               # Matlab,Pajek can't handle nodes id'ed with 0
        $i++;
      }
      if ( $i + 1 < $#lines ) {
        if ( $lines[$i+1] =~ /^label\s*(.*)/ ) {
          $label = $1;
          $label =~ s/^\"+|\"+$//g;
          $i++;
        }
        if ( $lines[$i+1] =~ /^value\s*(.*)/ ) {
          $value = $1;
          $value =~ s/^\"+|\"+$//g;
          $i++;
        }
      }
      if ( $id ne "undef") {

        #print "Found node in File: id = $id";
        if ( $net->has_node($id) ) {
          #print "  node already exists.\n";
        } else {
          $net->add_node($id);
          if ( $label ne "undef") {
            #print "  Label = $label";
          } else {
            $label = "N$id";
          }
          $net->set_vertex_attribute($id,"label",$label);

          if ( $value ne "undef") {
            #print "  Value = $value";
            $net->set_vertex_attribute($id,"value",$value);
          }
          #print "\n";
        }
      }
    }

    if ( $lines[$i] eq "edge" && $i < $#lines - 1 ) {
      $source = "undef";
      $target = "undef";
      $value = "undef";
      if ( $lines[$i+1] =~ /^source\s*(.*)/ ) {
        $source = $1;
        if ( $id0Flag ) {
          $source++;
        }
        $i++;
      }
      if ( $lines[$i+1] =~ /^target\s*(.*)/ ) {
        $target = $1;
        if ( $id0Flag ) {
          $target++;
        }
        $i++;
      }
      if ( $i + 1 <= $#lines ) {

        if ( $lines[$i+1] =~ /^value\s*(.*)/ ) {
          $value = $1;
          $i++;
        }
      }

      if ( $ignoreweights ) {
        $value = 1;
      }
      if ( $source ne "undef" && $target ne "undef" ) {

        #print "Found edge from $source to $target";
        if ( ! $net->has_node($source) ) {
          #print "   Added node $source.";
          $net->add_node($source, label => "N$source");
        }
        if ( ! $net->has_node($target) ) {
          #print "   Added node $target.";
          $net->add_node($target, label => "N$target");
        }
        if ( ! $net->has_edge($source, $target) ) {

          if ( $value ne "undef" ) {
            #print "  Value $value";
            $net->add_weighted_edge($source,$target,$value);
          } else {
            $net->add_weighted_edge($source,$target,1);
          }
        } else {
          if ( $value ne "undef" ) {
            #print "  Value = $value.  Added new weight to existing weight.";
            $net->add_weighted_edge($source,$target,$value);
          }
        }
        #print "\n";
      }

    }

  }

  if ($verbose) { print STDERR "****  DONE READING GML FILE $file ****\n\n";}

  return $net;
}

1;
