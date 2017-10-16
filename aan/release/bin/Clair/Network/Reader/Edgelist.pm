package Clair::Network::Reader::Edgelist;
use Clair::Network::Reader;
@ISA = ("Clair::Network::Reader");

use strict;
use warnings;
use Clair::Network;

use vars qw($VERSION);

$VERSION = '0.01';

=head1 NAME

Clair::Network::Reader::Edgelist - Class for reading in edgelist network files

=cut

=head1 SYNOPSIS

my $reader = Clair::Network::Reader::Edgelist->new();
my $net = $reader->read_network($filename);

=cut

=head1 DESCRIPTION

This class will read in an Edgelist format graph file into a Network object.

An edgelist format file is a list of edges from the graph, one per line.
It can optionally have a weight.
For example:

node1 node2
node2 node3
or
node1 node2 2
node2 node3 5

=cut

sub _read_network {
  my $self = shift;
  my $filename = shift;

  my %parameters = @_;

  my $property = '';
  if (exists $parameters{property}) {
    $property = $parameters{property};
  }

  my $edge_property = '';
  if (exists $parameters{edge_property}) {
    $edge_property = $parameters{edge_property};
  }

  my $sample_size = 0;
  if (exists $parameters{sample}) {
    $sample_size = $parameters{sample};
  }

  my $delim = "[ \t]+";
  if (exists $parameters{delim}) {
    $delim = $parameters{delim};
  }

  my $unionfind = 0;
  if (exists $parameters{unionfind}) {
    $unionfind = $parameters{unionfind};
  }

  my $directed = 1;
  if ( (exists $parameters{directed} and $parameters{directed} == 0) ||
       (exists $parameters{undirected} and $parameters{undirected} == 1) ) {
    $directed = 0;
  }
  
  my $multiedge = 0;
  if (exists $parameters{multiedge}) {
    $multiedge = $parameters{multiedge};
  } 

  my $graph_class = "";
  if (exists $parameters{graph}) {
    $graph_class = $parameters{graph};
  }

  my $filebased = 0;
  if (exists $parameters{filebased} and $parameters{filebased} == 1) {
    $filebased = 1;
  }

  my $net;
  if ($graph_class ne "") {
    $net = new Clair::Network(graph => $graph_class,
                              directed => $directed,
                              unionfind => $unionfind,
                              filebased => $filebased,
                              multiedge => $multiedge);
  } else {
    $net = new Clair::Network(directed => $directed,
                              unionfind => $unionfind,
                              filebased => $filebased,
                              multiedge => $multiedge);
  }
  open(FIN, $filename) or die "Couldn't open $filename: $!\n";

  while (<FIN>) {
    chomp;

    my @edge = split(/$delim/);

    my ($u_id, $v_id, $weight) = @edge;
    my $add_u = $u_id;
    my $add_v = $v_id;

    if ((defined $add_u) and (defined $add_v)) {
      $net->add_edge($add_u, $add_v);
      if ($property ne "") {
        $net->set_edge_attribute($add_u, $add_v, $property, 1);
      }

      # Add weight if needed
      if (defined $weight) {
        if ($net->{graph}->has_edge($add_u, $add_v)) {
          $net->set_edge_weight($add_u, $add_v, $weight);
          # Custom edge property
          if ($edge_property ne "") {
            $net->set_edge_attribute($add_u, $add_v, $edge_property, $weight);
          }
        }
      }
    }elsif ((defined $add_u) or (defined $add_v)) {
      if ( (defined $add_u) && ! $net->has_node($add_u)){
        $net->add_node($add_u);
      }elsif( (defined $add_v) && ! $net->has_node($add_u)){
         $net->add_node($add_v);
      }
    }
  }

  return $net;
}


sub _read_network_old {
  my $self = shift;
  my $filename = shift;

  my %parameters = @_;

  my $sample_size = 0;
  if (exists $parameters{sample}) {
    $sample_size = $parameters{sample};
  }

  my $delim = "[ \t]+";
  if (exists $parameters{delim}) {
    $delim = $parameters{delim};
  }

  my $directed = 1;
  if ( (exists $parameters{directed} and $parameters{directed} == 0) ||
       (exists $parameters{undirected} and $parameters{undirected} == 1) ) {
    $directed = 0;
  }

  open(FIN, $filename) or die "Couldn't open $filename: $!\n";

  my @edges = ();
  my $weight = 1;
  my @old = ();
  $old[0] = "";
  $old[1] = "";
  while (<FIN>) {
    chomp;
    my @edge = split(/$delim/);

    # deal with multiedges
    if (($edge[0] eq $old[0]) and ($edge[1] eq $old[1])) {
      $weight++;
    } else {
      if ($old[0] ne "") {
	$old[2] = $weight;
	my @test = @old;
	push(@edges, \@test);
      }
      if (defined $edge[2]) {
	$weight = $edge[2];
      } else {
	$weight = 1;
      }
    }
    $old[0] = $edge[0];
    $old[1] = $edge[1];
    if (defined $edge[2]) {
      $old[2] = $edge[2];
    }
  }
  # copy last edge
  my @test = @old;
  push(@edges, \@test);
  close(FIN);

  # Allow subset of edges to be used
  my $edge_cnt = scalar(@edges);
  my @sample_array = ();
  if ($sample_size > 0) {
    print "Warning, the sampling option for import_network is deprecated\n";
    print "Please use the new sampling classes.\n";
#    if ($verbose) { print "Getting subset of edges\n" }
    srand;
    for (my $i = 0; $i < $sample_size; $i++) {
      push @sample_array, $edges[int(rand($edge_cnt))];
    }
  } else {
    @sample_array = @edges;
  }

  # Free up the edges data structure
  undef @edges;

  print "Creating network with ", scalar(@sample_array), " edges\n";
  my $net = Clair::Network->create_network_from_array(\@sample_array,
                                                      directed => $directed);

  # set weights
  for my $e (@sample_array) {
    my $u = $e->[0];
    my $v = $e->[1];
    my $w = $e->[2];
    if ($net->{graph}->has_edge($u, $v)) {
      $net->set_edge_weight($u, $v, $w);
    }
  }

  return $net;
}

1;

