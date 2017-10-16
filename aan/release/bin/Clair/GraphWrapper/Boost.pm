package Clair::GraphWrapper::Boost;
use Clair::GraphWrapper;
@ISA = ("Clair::GraphWrapper");

use strict;
use warnings;
use Boost::Graph;

use vars qw($VERSION);

$VERSION = '0.01';

=head1 NAME

Clair::GraphWrapper::Boost - Concrete class for Boost graphs

=head1 SYNOPSIS

my $graph = new Clair::GraphWrapper::Boost();
my $network = new Clair::Network(graph => $graph);

=cut

=head1 DESCRIPTION

This object is a class for Boost graph objects used by the Network class.

=cut

sub new {
  my $class = shift;
  my %parameters = @_;

  my $directed = 1;
  if ((exists $parameters{directed} and $parameters{directed} == 0) ||
      (exists $parameters{undirected} and $parameters{undirected} == 1)) {
    $directed = 0;
  }

  my $unionfind = 0;
  if (exists $parameters{unionfind} and $parameters{unionfind} == 1) {
    $unionfind = 1;
  }

  my $graph;
  if (exists $parameters{graph}) {
    # If user specified graph, use that
    $graph = $parameters{graph};
    if ($graph->is_directed()) {
      $directed = 1;
    } else {
      $directed = 0;
    }
  } else {
    # Otherwise, create a new graph object
    $graph = Boost::Graph->new(directed => $directed,
                               unionfind => $unionfind);
  }

  my $self = bless {
                    graph => $graph,
                    directed => $directed
                    }, $class;

  return $self;
}

sub add_vertex {
  my $self = shift;
  my $n = shift;

  $self->{graph}->add_node($n);
}

sub add_edge {
  my $self = shift;
  my $u = shift;
  my $v = shift;

  $self->{graph}->add_edge($u, $v);
}

sub delete_edge {
  my $self = shift;
  my $u = shift;
  my $v = shift;

  my $graph = $self->{graph};

  $graph->remove_edge($u, $v);
}

sub has_edge {
  my $self = shift;
  my $u = shift;
  my $v = shift;

  return $self->{graph}->has_edge($u, $v);
}

sub is_directed {
  my $self = shift;
  return $self->{directed};
}

sub edges {
  my $self = shift;
  my $edges = $self->{graph}->get_edges();

  return map { [$_->[0], $_->[1]] } @{$edges};
}

sub predecessors {
  my $self = shift;
  my $n = shift;

  return @{$self->{graph}->parents_of_directed($n)};
}

sub successors {
  my $self = shift;
  my $n = shift;

  return @{$self->{graph}->children_of_directed($n)};
}

sub vertices {
  my $self = shift;
  my $vertices = $self->{graph}->get_nodes();

  return @{$vertices};
}

sub degree {
  my $self = shift;
  my $v = shift;


  return scalar(@{$self->{graph}->neighbors($v)});
}

sub in_degree {
  my $self = shift;
  my $v = shift;


  return scalar(@{$self->{graph}->parents_of_directed($v)});
}

sub out_degree {
  my $self = shift;
  my $v = shift;


  return scalar(@{$self->{graph}->children_of_directed($v)});
}

sub all_pairs_shortest_paths_johnson {
  my $self = shift;

  return $self->{graph}->all_pairs_shortest_paths_johnson(@_);
}

sub breadth_first_search {
  my $self = shift;

  return $self->{graph}->breadth_first_search(@_);
}

sub connected_components {
  my $self = shift;
  my $graph = $self->{graph};

  my $c = $graph->connected_components();
#  use Data::Dumper;
#  print Dumper($c) . "\n";

  return @{$c};
}

1;
