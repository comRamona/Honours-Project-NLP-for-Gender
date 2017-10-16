package Clair::Network::Writer::Graclus;
use Clair::Network::Writer;
@ISA = ("Clair::Network::Writer");

use strict;
use warnings;
use Graph;

use vars qw($VERSION);

$VERSION = '0.01';

=head1 NAME

Clair::Network::Writer::Graclus - Class for writing graclus matrix files

=cut

=head1 SYNOPSIS

my $export = Clair::Network::Writer::Graclus->new();
$export->set_name("graclus");
$export->write_network($net, "filename");

=cut

=head1 DESCRIPTION

This class will write a network object into a graclus-compatible matrix file.

=cut

sub _write_network {
  my $self = shift;
  my $net = shift;
  my $graph = $net->{graph};
  my $filename = shift;
  my %parameters = @_;
  my $output = "";

#  $output .= <<EOH
#TESTING OF THIS FORMAT IS STILL IN PROGRESS!
#DO NOT USE/TRUST/RELY ON IT AT THIS TIME!
#
#What this output should eventually resemble:
#UnWeighted:
#  5 6          	<--- number of nodes and edges
#  2 3	     	<--- nodes adjacent to 1
#  1 5		.
#  1 4 5		.
#  3 5		.
#  2 3 4	     	<--- nodes adjacent to 5
#Weighted
# 5 6 1		<--- number of nodes and edges and format
# 2 10 3 9	<--- nodes adjacent to 1 and corresponding edge weight
# 1 10 5 6	.
# 1 9 4 11 5 7	.
# 3 11 5 28	.
# 2 6 3 7 4 28	<--- nodes adjacent to 5 and corresponding edge weight
#EOH
#;

# parse data

  my $round = 0;
  if (exists $parameters{round}) {
    $round = $parameters{round};
  }

  my @vertices = $graph->vertices;
  my @edges = $graph->edges;

  my $numNodes = 0;
  my $numEdges = 0;
  my $is_weighted = 0;
  my $weightFormat = 1;
  my $weight = 0;
    
  # determine if graph is weighted
  if ($is_weighted eq 0){
    foreach my $v (sort @vertices) {
   	my @neighbors = $graph->successors($v);
      foreach my $neighbor (sort @neighbors) {
        if ($graph->has_edge_weight($v, $neighbor)) {
        	$is_weighted = 1;
        	last;
        }
      }
    }
  }
  
  foreach my $v (sort @vertices) {
    $numNodes = $numNodes + 1;
  }
  foreach my $e (sort @edges) {
    $numEdges = $numEdges + 1;
  }
  $output .= $numNodes;
  $output .= " " . $numEdges;
  if ($is_weighted) {
    $output .= " " . $weightFormat;  	
  }
  $output .= "\n";

  foreach my $v (sort @vertices) {
    # for testing
	# $output .= "$v";
	my @neighbors = $graph->neighbors($v);
    foreach my $neighbor (sort @neighbors) {
      if ($is_weighted) {
        $weight = $graph->get_edge_weight($v, $neighbor);
        $output .= "$neighbor $weight ";
      } else {
        $output .= "$neighbor ";
      }
    }
	$output .= "\n";
  }
 
# write to file

  open(FILE, "> $filename") or die "Couldn't open file: $filename\n";

  print (FILE $output);
  
  close(FILE);

  print ("Wrote to $filename:\n" . $output);
  
}

1;
