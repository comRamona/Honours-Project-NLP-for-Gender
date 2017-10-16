package Clair::Network::Sample::ForestFire;
use Clair::Network::Sample::SampleBase;

use strict;
use warnings;
use Clair::Statistics::Distributions::Geometric;

use vars qw($VERSION @ISA);

@ISA = qw(Clair::Network::Sample::SampleBase);

$VERSION = '0.01';

=head1 NAME

Clair::Network::Sample::ForestFire - Random sampling using Forest Fire model

=cut

=head1 SYNOPSIS

my $sample = Clair::Network::Sample::ForestFire->new($net);
my $new_net = $sample->sample(3, 0.9);

=cut

=head1 DESCRIPTION

Samples from the network using the Forest Fire algorithm.  Nodes are
"burned" with probability p starting from an initial random node.  If
the fire goes out a new random node is selected.

=cut


=head2 sample

Call to sample the current network.  Returns a new network.

=cut

sub sample {
  my $self = shift;
  my $n = shift;
  my $pf = shift;

  my $net = $self->{oldnet};
  $self->{net} = new Clair::Network(directed =>
                                    $self->get_old_net()->{directed});
  $self->{n} = $n;
  $self->{num_nodes} = 0;
  $self->{vertices} = ();

#  my $mean = $pf / (1 - $pf);
#  my $p = 1 / $mean;
  my $p = 1 - $pf;
#  print "p: $p\n";

  while ($self->{num_nodes} < $self->{n}) {
    my @nodes = $self->get_random_nodes();
    my $node = $nodes[0];
    if (not defined $self->{vertices}{$node}) {
      $self->burn_node($node, $p);
    }
  }

  my @sample_vertices = keys %{$self->{vertices}};
  $net = $self->{oldnet}->create_subset_network(\@sample_vertices);

  return $net;
}


sub burn_node {
  my $self = shift;
  my $node = shift;
  my $p = shift;

  # If we've already burned enough nodes, return
  if ($self->{num_nodes} >= $self->{n}) {
    return;
  }

  $self->{vertices}{$node} = 1;

  my $dist = new Clair::Statistics::Distributions::Geometric;
  my $net = $self->{net};
  my $oldgraph = $self->{oldnet}->{graph};

  # First, add the node to the network
  $self->{num_nodes}++;

  my $num_out_links = $dist->get_random_value($p);
  my @successors = $oldgraph->successors($node);
  my @nodes = $self->get_random_nodes($num_out_links, subset => \@successors);
  foreach my $new_node (@nodes) {
    if (not defined $self->{vertices}{$new_node}) {
      $self->burn_node($new_node, $p);
    }
  }
}

1;

