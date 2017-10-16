package Clair::Network::Sample::SampleBase;

use strict;
use warnings;
use Math::Random;	# used for drawing rand numbers
use Carp;

use vars qw($VERSION);

$VERSION = '0.01';

=head1 NAME

Clair::Network::Sample::SampleBase - Abstract class for network sampling

=cut

=head1 SYNOPSIS

Clair::Network::Sample::SampleBase should not be called directly, but instead
inherited from a concrete SampleBase class.

=cut

=head1 DESCRIPTION

This object is for sampling networks.

=cut


sub new {
  my $class = shift;
  my $net = shift;

  my $self = {};

  if (defined $net) {
    $self->{oldnet} = $net;
  }

  bless($self, $class);

  return $self;
}

=head2 get_old_net

Return the original network

=cut

sub get_old_net {
  my $self = shift;

  return $self->{oldnet};
}

=head2 sample

Return a new random network sampled from the original network

=cut

sub sample {
  croak "dist_function has not been implemented\n";
  return;
}

=head2 get_unique_integers

Return a list of random integers from a uniform distribution with no
duplicates.

=cut

sub get_unique_integers {
  my $self = shift;
  my $num = shift;
  my $low = shift;
  my $high = shift;

  my %hash = ();

  my $i = 0;
  while ($i < $num) {
    my $x = random_uniform_integer(1, $low, $high);
    if (not defined $hash{$x}) {
      $hash{$x} = 1;
      $i++;
    }
  }

  return keys %hash;
}

=over

=item get_random_nodes

get_random_nodes($num_nodes)

Picks a set of nodes randomly with a uniform distribution
from the original network

$num_nodes is the number of nodes to pick.  With no argument, return one node.

=back

=cut

sub get_random_nodes {
  my $self = shift;
  my $num_nodes = shift;

  my %parameters = @_;

  my @vertices = ();
  # Allow choosing from a limited set of vertices
  if (defined $parameters{subset})  {
    my $s = $parameters{subset};
    @vertices = @{$s};
  } else {
    @vertices = $self->{oldnet}->get_vertices();
  }

  if (not defined $num_nodes) {
    $num_nodes = 1;
  }

  if ($num_nodes > 2147483561) {
    die "Network too large\n";
  }

  if ($num_nodes > scalar(@vertices)) {
#    print STDERR "Warning, wanted $num_nodes vertices but only returning " .
#      scalar(@vertices) . "\n";
    $num_nodes = scalar(@vertices);
  }

  my $max = scalar @vertices;
  my @sample_vertices = $self->get_unique_integers($num_nodes, 0, $max - 1);
  map {$_ = $vertices[$_]} @sample_vertices;

  return @sample_vertices;
}

=item get_random_edges

get_random_edges($num_edges)

Picks a set of edges randomly with a uniform distribution
from the original network

$num_edges is the number of edges to pick.  With no argument, return one edge.

=cut

sub get_random_edges {
  my $self = shift;
  my $num_edges = shift;

  my %parameters = @_;

  my @edges = ();
  # Allow choosing from a limited set of edges
  if (defined $parameters{subset})  {
    my $s = $parameters{subset};
    @edges = @{$s};
  } else {
    @edges = $self->{oldnet}->get_edges();
  }

  if (not defined $num_edges) {
    $num_edges = 1;
  }

  if ($num_edges > 2147483561) {
    die "Network too large\n";
  }

  if ($num_edges > scalar(@edges)) {
#    print STDERR "Warning, wanted $num_edges edges but only returning " .
#      scalar(@edges) . "\n";
    $num_edges = scalar(@edges);
  }


  my $max = scalar @edges;
  my @sample_edges = $self->get_unique_integers($num_edges, 0, $max - 1);
  map {$_ = $edges[$_]} @sample_edges;

  return @sample_edges;
}

1;
