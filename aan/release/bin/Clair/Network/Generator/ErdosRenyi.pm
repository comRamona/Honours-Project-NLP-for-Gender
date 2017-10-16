package Clair::Network::Generator::ErdosRenyi;
use Clair::Network::Generator::GeneratorBase;
@ISA = ("Clair::Network::Generator::GeneratorBase");

use strict;
use warnings;
use Carp;

use vars qw($VERSION);

$VERSION = '0.01';

=head1 NAME

Clair::Network::Generator::ErdosRenyi - ErdosRenyi network generator abstract class

=cut

=head1 SYNOPSIS

my $generator = Clair::Network::Generator::ErdosRenyi->new();
$generator->generate($n, $m, type => "gnm");

or

$net = $generator->generate($n, $p, type => "gnp");

Where n is the number of nodes, m is the number of edges, and p is the
probability of an edge between two nodes.

=cut

=head1 DESCRIPTION

This module generates Erdos-Renyi random graphs.  Two different models
can be generated.  The gnm module consists of a set number of nodes
and edges, with random attachment.  The gnp module consists of a set
number of nodes with an edge existing between two nodes with
probability p.

=cut

sub new {
  my $class = shift;

  # Call superclass constructor
  my $self = $class->SUPER::new();

  $self->{type} = "";

  return $self;
}

=head2 set_type

Set the model type generated.  Can be "gnm" or "gnp"

gnm creates a set number of nodes and edges.  gnp creates a network
with a set number of nodes and edges with probability p.

=cut

sub set_type {
  my $self = shift;
  my $type = shift;

  if (($type eq "gnp") or ($type eq "gnm")) {
    $self->{type} = $type;
  } else {
    croak "Unsupported Erdos-Renyi graph type, must be gnp or gnm\n";
  }
}

=head2 generate

  Generate a new Erdos-Renyi random graph, returning a new
  Clair::Network object

=cut

sub generate {
  my $self = shift;
  my $n = shift;
  my $p = shift;

  my %parameters = @_;

  my $type = "";
  if (defined $parameters{type}) {
    $type = $parameters{type};
  } else {
    $type = $self->{type};
  }

  my $directed = 1;
  if (defined $parameters{directed}) {
    $directed = $parameters{directed};
  }

  my $weights = 0;
  if (defined $parameters{weights}) {
    $weights = $parameters{weights};
  }

  if ($type eq "") {
    croak "Must set Erdos-Renyi graph type before calling generate\n";
    return;
  }

  my $net = Clair::Network->new(directed => $directed);

  # Add nodes
  for(my $i = 0; $i < $n; $i++) {
    $net->add_node($i);
  }

  # Add edges
  if ($type eq "gnm") {
    # set number of edges
    my $i = 0;
    while ($i < $p) {
      my $v1 = $self->get_random_uniform_integer(1, 0, $n - 1);
      my $v2 = $self->get_random_uniform_integer(1, 0, $n - 1);

      # No self-loops (perhaps later?)
      # No multi-edges
      if (($v1 ne $v2) and (not $net->has_edge($v1, $v2))) {
        $net->add_edge($v1, $v2);
        $i++;
      }
    }
  } else {
    # random number of edges
    for(my $i = 0; $i < $n; $i++) {
      for(my $j = 0; $j < $n; $j++) {
        if (($i != $j) and ($self->get_random_uniform() < $p)) {
          $net->add_edge($i, $j);
          if ($weights) {
            my $w = $self->get_random_uniform();
            $net->set_edge_weight($i, $j, $w);
          }
        }
      }
    }
  }

  return $net;
}
