package Clair::Network::Centrality::Closeness;
use Clair::Network::Centrality;
@ISA = ("Clair::Network::Centrality");

use strict;
use warnings;
use Clair::Network;

use vars qw($VERSION);

$VERSION = '0.01';

=head1 NAME

Clair::Network::Centrality::Closeness - Class for computing closeness
centrality

=cut

=head1 SYNOPSIS

my $closeness = Clair::Network::Centrality::Closeness->new($net);
my %b = $closeness->centrality();
my $node_closeness = $closeness->node_centrality($node);

=cut

=head1 DESCRIPTION

This class will compute closeness centrality.

=cut

# TODO: Could use some optimization
sub _centrality {
  my $self = shift;

  my %parameters = @_;

  my $net = $self->{net};

  my $directed = $net->{directed};
  if ((exists $parameters{directed} and $parameters{directed} == 0) ||
      (exists $parameters{undirected} and $parameters{undirected} == 1)) {
    $directed = 0;
  }

  my @b = ();
  my %paths = ();

  my @vertices = $net->get_vertices();

  my $sp = $net->get_shortest_path_matrix(directed => $directed);
  my $cnt = 0;
  foreach my $v (@vertices) {
    $cnt = 0;
    if (defined $sp->{$v}) {
      foreach my $v2 (keys %{$sp->{$v}}) {
        if ($v ne $v2) {
          $paths{$v} += $sp->{$v}{$v2};
          $cnt++;
        }
      }
      if (defined $paths{$v}) {
        $paths{$v} = 1 / $paths{$v};
      } else {
        $paths{$v} = 0;
      }
    } else {
      $paths{$v} = 0;
    }
  }

  return \%paths;
}

sub _normalized_centrality {
  my $self = shift;
  my %parameters = @_;

  my $net = $self->{net};

  my $directed = $net->{directed};
  if ((exists $parameters{directed} and $parameters{directed} == 0) ||
      (exists $parameters{undirected} and $parameters{undirected} == 1)) {
    $directed = 0;
  }

  my $value_hash = $self->centrality();
  my $max_degree = $net->num_nodes() - 1;
  if ($max_degree > 0) {
    foreach my $v (keys %{$value_hash}) {
      if ($value_hash->{$v} > 0) {
        if (!$directed) {
          $value_hash->{$v} = $value_hash->{$v} * $max_degree;
        } else {
          my $sp = $net->get_shortest_path_matrix(directed => $directed);
          my $cnt = scalar(keys %{$sp->{$v}}) - 1;
          $value_hash->{$v} = $value_hash->{$v} * $cnt;
        }
      }
    }
  }

  return $value_hash;
}

sub _node_centrality {
}

1;

