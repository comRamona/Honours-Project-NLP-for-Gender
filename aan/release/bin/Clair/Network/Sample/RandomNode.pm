package Clair::Network::Sample::RandomNode;
use Clair::Network::Sample::SampleBase;
@ISA = ("Clair::Network::Sample::SampleBase");

use strict;
use warnings;

#$VERSION = '0.01';

=head1 NAME

Clair::Network::Sample::RandomNode - Random node sampling

=cut

=head1 SYNOPSIS

my $sample = Clair::Network::Sample::RandomNode->new($net);
$sample->number_of_nodes(2);
my $new_net = $sample->sample();

=cut

=head1 DESCRIPTION

Uniformly samples a number of nodes from the network.

=cut


sub number_of_nodes {
  my $self = shift;
  my $num_nodes = shift;

  $self->{num_nodes} = $num_nodes;
}

sub sample {
  my $self = shift;

  my $net;
  if (defined $self->{num_nodes}) {
    my $num_nodes = $self->{num_nodes};
    my @sample_vertices = $self->get_random_nodes($num_nodes);
    $net = $self->{oldnet}->create_subset_network(\@sample_vertices);
  } else {
    die "Must call number_of_nodes first\n";
  }

  return $net;
}

1;
