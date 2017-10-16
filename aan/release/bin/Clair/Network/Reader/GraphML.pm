package Clair::Network::Reader::GraphML;
use Clair::Network::Reader;
@ISA = ("Clair::Network::Reader");

use strict;
use warnings;
use XML::Parser;
use Clair::Network;

use vars qw($VERSION);

$VERSION = '0.01';

=head1 NAME

Clair::Network::Reader::GraphML - Class for reading in GraphML network files

=cut

=head1 SYNOPSIS

my $reader = Clair::Network::Reader::GraphML->new();
my $net = $reader->read_network($filename);

=cut

=head1 DESCRIPTION

This class will read in a GraphML format graph file into a Network object.

=cut


sub _read_network {
  my $self = shift;
  my $filename = shift;

  my $parser = new XML::Parser(Style => 'Tree');
  my $tree = $parser->parsefile($filename);

  my $net = undef;

  my $in_graph = 0;
  foreach my $elem (@{$tree->[1]}) {
    if ($in_graph) {
      my $type = $elem->[0]{"edgedefault"};
      # Create the type of network specified in the GraphML file
      if ($type eq "directed") {
        $net = Clair::Network->new(directed => 1);
      } else {
        $net = Clair::Network->new(directed => 0);
      }
      $net = $self->parse_graph($net, $elem);
      $in_graph = 0;
    }

    if ($elem eq "graph") {
      $in_graph = 1;
    }
  }

   return $net;
}

sub parse_graph {
  my $self = shift;
  my $net = shift;
  my $graph = shift;

  my $in_node = 0;
  my $in_edge = 0;
  foreach my $elem (@{$graph}) {
    if ($in_node) {
      $in_node = 0;
      my $id = $elem->[0]{"id"};
      $net->add_node($id);
    }

    # Add the edges
    if ($in_edge) {
      $in_edge = 0;
      my $source = $elem->[0]{"source"};
      my $target = $elem->[0]{"target"};
      $net->add_edge($source, $target);
    }

    if ($elem eq "node") {
      $in_node = 1;
    }

    if ($elem eq "edge") {
      $in_edge = 1;
    }
  }

  return $net;
}

1;
