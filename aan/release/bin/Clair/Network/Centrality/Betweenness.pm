package Clair::Network::Centrality::Betweenness;
use Clair::Network::Centrality;
@ISA = ("Clair::Network::Centrality");

use strict;
use warnings;
use Clair::Network;

use vars qw($VERSION);

$VERSION = '0.01';

=head1 NAME

Clair::Network::Centrality::Betweenness - Class for computing betweenness
centrality

=cut

=head1 SYNOPSIS

my $betweenness = Clair::Network::Centrality::Betweenness->new($net);
my %b = $betweenness->centrality();
my $node_betweenness = $betweenness->node_centrality($node);

=cut

=head1 DESCRIPTION

This class will compute betweenness centrality.

=cut

=head2 _centrality

Centrality for betweenness centrality.

Uses the Brandes algorithm:
Brandes, Ulrik.  A Faster Algorithm for Betweenness Centrality.  Journal of Mathematical Sociology.  2001.  25(2).  pp. 163-177

=cut

sub _centrality {
  my $self = shift;
  my $net = $self->{net};
  my %parameters = @_;

  #my %adj_matrix = $net->get_adjacency_matrix();
  # Now find the betweenness centrality.  This is equal to
  # The number of shortest paths the vertex is on, divided by the number of
  # shortest paths
  my @vertices = $net->get_vertices();

  my %numsps = ();
  my %distance = ();

  my %predecessors = ();
  my %centrality = ();
  @centrality{@vertices} = map{0} @vertices;

  my %dependency = ();

  foreach my $s (@vertices) {
    foreach my $v (@vertices) {
      $numsps{$v} = 0;
      $distance{$v} = -1;
      $dependency{$v} = 0;
      $predecessors{$v} = ();
    }
    $numsps{$s} = 1;
    $distance{$s} = 0;
    @{$predecessors{$s}} = ();
    my @stack = ();
    my @queue = ($s);

    while (@queue) {
      my $v = pop @queue;
      push(@stack, $v);
      foreach my $w ($net->{graph}->predecessors($v)) {
        # w found for the first time?
        if ($distance{$w} < 0) {
          unshift(@queue, $w);
          $distance{$w} = $distance{$v} + 1;
        }
        # shortest path to w via v?
        if ($distance{$w} == $distance{$v} + 1) {
          $numsps{$w} += $numsps{$v};
          push @{$predecessors{$w}}, $v;
        }
      }
    }

    while (@stack) {
      my $w = pop @stack;

      foreach my $v (@{$predecessors{$w}}) {
        $dependency{$v} += ($numsps{$v} / $numsps{$w}) *
          (1.0 + $dependency{$w});
      }

      if ($w ne $s) {
        $centrality{$w} += $dependency{$w};
      }
    }
  }

  return \%centrality;
}

=head2 _normalized_centrality

Normalized centrality for betweenness centrality.
This is normalized by dividing by (g - 1)(g - 2), which is the number of
possible pairs.

=cut

sub _normalized_centrality {
  my $self = shift;
  my %parameters = @_;

  my $net = $self->{net};

  my $value_hash = $self->centrality();
  my $num_nodes = $net->num_nodes();
  my $max;
  $max = (($num_nodes - 1) * ($num_nodes - 2));

  foreach my $v (keys %{$value_hash}) {
	  if ($max == 0) {
	  	$value_hash->{$v} = 0;
	  
	  } else {
		  $value_hash->{$v} = $value_hash->{$v} / $max;
	  }
  }

  return $value_hash;
}

sub _node_centrality {
}

1;

