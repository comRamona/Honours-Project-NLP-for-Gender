package Clair::Network::Sample::RandomEdge;
use Clair::Network::Sample::SampleBase;
use vars qw($VERSION @ISA);

@ISA = ("Clair::Network::Sample::SampleBase");

use strict;
use warnings;


$VERSION = '0.01';

=head1 NAME

Clair::Network::Sample::RandomEdge - Random edge sampling

=cut

=head1 SYNOPSIS

my $sample = Clair::Network::Sample::RandomEdge->new($net);
$sample->number_of_edges(2);
my $new_net = $sample->sample();

=cut

=head1 DESCRIPTION

Uniformly samples a number of edges from the network.

=cut


sub number_of_edges {
  my $self = shift;
  my $num_edges = shift;

  $self->{num_edges} = $num_edges;
}

=head2 create_subset_network_from_edges

Create a subset network from a set of edges

=cut

sub create_subset_network_from_edges {
  my $self = shift;
  my $graph = $self->get_old_net()->{graph};
  my $sub_edges_ref = shift;
  my @sub_edges = @$sub_edges_ref;

  my $new_network = new Clair::Network(directed =>
                                       $self->get_old_net()->{directed});
  my $new_graph = $new_network->{graph};

  # Add the edges
  foreach my $edge (@sub_edges) {
    my ($u, $v) = @$edge;

    if ($graph->has_edge($u, $v)) {
      # Add nodes
      $new_network->add_node($u);
      $new_network->add_node($v);
      my $attr = $graph->get_vertex_attributes($u);
      $new_graph->set_vertex_attributes($u, $attr);
      $attr = $graph->get_vertex_attributes($v);
      $new_graph->set_vertex_attributes($v, $attr);

      # Add edge
      $new_graph->add_edge($u, $v);
      $attr = $graph->get_edge_attributes($u, $v);
      if (defined $attr) {
        $new_graph->set_edge_attributes($u, $v, $attr);
      }
      if ($graph->has_edge_weight($u, $v)) {
        my $w = $graph->get_edge_weight($u, $v);
        $new_graph->set_edge_weight($u, $v, $w);
      }
    }
  }


  return $new_network;
}


sub sample {
  my $self = shift;
  my $num_edges = shift;

  my $net;
  if (defined $self->{num_edges}) {
    my $num_edges = $self->{num_edges};
  } elsif (not defined $num_edges) {
    die "Must call number_of_edges first or pass in number of edges\n";
  }

  my @sample_edges = $self->get_random_edges($num_edges);
  $net = $self->create_subset_network_from_edges(\@sample_edges);

  return $net;
}

1;
