package Clair::Network::Centrality::Degree;
use Clair::Network::Centrality;
@ISA = ("Clair::Network::Centrality");

use strict;
use warnings;
use Clair::Network;

use vars qw($VERSION);

$VERSION = '0.01';

=head1 NAME

Clair::Network::Centrality::Degree - Class for computing degree
centrality

=cut

=head1 SYNOPSIS

my $degree = Clair::Network::Centrality::Degree->new($net);
my %b = $degree->centrality();
my $node_degree = $degree->node_centrality($node);

=cut

=head1 DESCRIPTION

This class will compute degree centrality.
IMPORTANT: Degree centrality is calculated for the undirected network

=cut

sub _centrality {
  my $self = shift;
  my %parameters = @_;

  my $net = $self->{net};

  my $directed = $net->{directed};
  if ((exists $parameters{directed} and $parameters{directed} == 0) ||
      (exists $parameters{undirected} and $parameters{undirected} == 1)) {
    $directed = 0;
  }

  my %value_hash = ();

  my @vertices = $net->get_vertices();
  foreach my $v (@vertices) {
    if ($directed) {
      $value_hash{$v} = $net->total_degree($v) / 2;
    } else {
      $value_hash{$v} = $net->degree($v);
    }
  }

  return \%value_hash;
}

=head2 _normalized_centrality

Normalized centrality for degree centrality.  Maximum degree possible is N-1.
http://www.analytictech.com/networks/centrali.htm

=cut

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
  my $max_degree;
  $max_degree = $net->num_nodes() - 1;
  foreach my $v (keys %{$value_hash}) {
    $value_hash->{$v} = $value_hash->{$v} / $max_degree;
  }

  return $value_hash;
}

sub _node_centrality {
}

1;
