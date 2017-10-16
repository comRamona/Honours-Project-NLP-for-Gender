package Clair::Network::Centrality::PageRank;
use Clair::Network::Centrality;
@ISA = ("Clair::Network::Centrality");

use strict;
use warnings;
use Clair::Network;

use vars qw($VERSION);

$VERSION = '0.01';

=head1 NAME

Clair::Network::Centrality::PageRank - Class for computing PageRank
centrality

=cut

=head1 SYNOPSIS

my $lexrank = Clair::Network::Centrality::PageRank->new($net);
my %b = $lexrank->centrality();
my $node_lexrank = $lexrank->node_centrality($node);

=cut

=head1 DESCRIPTION

This class will compute PageRank centrality.

=cut


=head2 centrality

centrality(pagerank_value => 'pagerank_value',
           pagerank_transition => 'pagerank_transition',
           pagerank_bias => 'pagerank_bias', jump => 0.15,
           tolerance => 0.0001, max_iterations => 200)

Computes the pagerank for the network.  The property given for
pagerank_value is used for the initial value, and for
pagerank_transition for the transition probabilities.  The
pagerank_bias property is used to set the bias.  If the network does
not have any values for that property (or they are all zero) then the
unbiased pagerank is computed.

All parameters are optional, the defaults for the properties are
given.  Passig zero for any numerical parameter (or not specifying
that parameter) will cause the default value to be used.

The result is saved as the pagerank_value property of each node.

=cut

sub centrality {
  my $self = shift;
  my %params = @_;

  my $net = $self->{net};

  my $pagerank_value = 'pagerank_value';
  if (exists $params{pagerank_value}) {
    $pagerank_value = $params{pagerank_value};
  }

  my $pagerank_transition = 'pagerank_transition';
  if (exists $params{pagerank_transition}) {
    $pagerank_transition = $params{pagerank_transition};
  }

  my $pagerank_bias = 'pagerank_bias';
  if (exists $params{pagerank_bias}) {
    $pagerank_bias = $params{pagerank_bias};
  }

  my $jump = 0;
  if (exists $params{jump}) {
    $jump = $params{jump};
  }

  my $tolerance = 0;
  if (exists $params{tolerance}) {
    $tolerance = $params{tolerance};
  }

  my $max_iterations = 0;
  if (exists $params{max_iterations}) {
    $max_iterations = $params{max_iterations};
  }
  return $net->compute_rank_result($pagerank_value, $pagerank_transition,
                                    $jump, $pagerank_bias,
                                    tolerance => $tolerance,
                                    max_iterations => $max_iterations);

  my %value_hash = ();

  my $property = "pagerank_value";
  foreach my $v ($net->get_vertices) {
    if ($net->has_vertex_attribute($v, $property)) {
      my $vp = $net->get_vertex_attribute($v, $property);
      $value_hash{$v} = $vp;
    }
  }

  return \%value_hash;
}

=head2 _normalized_centrality

Normalized centrality for PageRank centrality.

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
  foreach my $v (keys %{$value_hash}) {
    $value_hash->{$v} = $value_hash->{$v};
  }

  return $value_hash;
}

sub _node_centrality {
}

=head2 save

Saves the current lexrank values to a file.  If lexrank has been
calculated, then these are the results, otherwise these could be the
initial or intermediate values

=cut

sub save {
  my $self = shift;
  my $fn = shift;

  return $self->{net}->save_property_distribution($fn, 'pagerank_value');
}

=head2 print_current_distribution

print_current_distribution

Prints the current pagerank values.  If the pagerank has been
calculated, these are the results, otherwise this may be the initial
or intermediate values.

=cut

sub print_current_distribution {
  my $self = shift;

  $self->{net}->print_property_distribution('pagerank_value');
}


1;
