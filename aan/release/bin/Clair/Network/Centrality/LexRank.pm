package Clair::Network::Centrality::LexRank;
use Clair::Network::Centrality;
@ISA = ("Clair::Network::Centrality");

use strict;
use warnings;
use Clair::Network;

use vars qw($VERSION);

$VERSION = '0.01';

=head1 NAME

Clair::Network::Centrality::LexRank - Class for computing LexRank
centrality

=cut

=head1 SYNOPSIS

my $lexrank = Clair::Network::Centrality::LexRank->new($net);
my %b = $lexrank->centrality();
my $node_lexrank = $lexrank->node_centrality($node);

=cut

=head1 DESCRIPTION

This class will compute LexRank centrality.

=cut

=head2 centrality

centrality(lexrank_value => 'lexrank_value',
           lexrank_transition => 'lexrank_transition',
           lexrank_bias => 'lexrank_bias',
           jump => 0.15, tolerance => 0.0001, max_iterations => 200)

Computes the lexrank for the network.  The property given for
lexrank_value is used for the initial value, and for
lexrank_transition for the transition probabilities.  The lexrank_bias
property is used to set the bias.  If the network does not have any
values for that property (or they are all zero) then the unbiased
lexrank is computed.

All parameters are optional, the defaults for the properties are
given.  Passing zero for any numerical parameter (or not specifying
that parameter) will cause the default value to be used.

The result is saved as the lexrank_value property of each node.

=cut

sub centrality {
  my $self = shift;
  my %params = @_;

  my $net = $self->{net};

  my $directed = $net->{directed};
  if ((exists $params{directed} and $params{directed} == 0) ||
      (exists $params{undirected} and $params{undirected} == 1)) {
    $directed = 0;
  }

  my $lexrank_value = 'lexrank_value';
  if (exists $params{lexrank_value}) {
    $lexrank_value = $params{lexrank_value};
  }

  my $lexrank_transition = 'lexrank_transition';
  if (exists $params{lexrank_transition}) {
    $lexrank_transition = $params{lexrank_transition};
  }

  my $lexrank_bias = 'lexrank_bias';
  if (exists $params{lexrank_bias}) {
    $lexrank_bias = $params{lexrank_bias};
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

  $net->compute_rank_result($lexrank_value, $lexrank_transition, $jump, 
                            $lexrank_bias, tolerance => $tolerance, 
                            max_iterations => $max_iterations);

  my %value_hash = ();

  my $property = "lexrank_value";
  foreach my $v ($net->get_vertices) {
    if ($net->has_vertex_attribute($v, $property)) {
      my $vp = $net->get_vertex_attribute($v, $property);
      $value_hash{$v} = $vp;
    }
  }

  return \%value_hash;
}

=head2 _normalized_centrality

Normalized centrality for LexRank centrality.

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

  return $self->{net}->save_property_distribution($fn, 'lexrank_value');
}

=head2 read_lexrank_bias

read_lexrank_bias($filename)

Reads the lexrank bias values from the specified file.

=cut

sub read_lexrank_bias {
  my $self = shift;
  my $filename = shift;

  $self->{net}->read_property_from_file($filename, 'lexrank_bias');
}

=head2 read_lexrank_initial_distribution

read_lexrank_initial_distribution($filename)

Reads the initial lexrank values from the specified file.

=cut

sub read_lexrank_initial_distribution {
	my $self = shift;
	my $filename = shift;

	$self->{net}->read_property_from_file($filename, 'lexrank_value');
}

=head2 read_lexrank_probabilities_from_file

read_lexrank_probabilities_from_file($filename)

Reads the transition probabilities (similarity values) for lexrank from the specified file.

=cut

sub read_lexrank_probabilities_from_file {
  my $self = shift;
  my $filename = shift;

  $self->{net}->read_matrix_property_from_file($filename,'lexrank_transition');
}

=head2 save_lexrank_probabilities_to_file

save_lexrank_probabilities_to_file

Saves the transition probabilities used in lexrank to the specified file.

=cut

sub save_lexrank_probabilities_to_file {
	my $self = shift;
	my $filename = shift;

	$self->{net}->save_matrix_property_to_file($filename,
                                                   'lexrank_transition');
}

=head2 compute_lexrank_from_bias_sents

compute_lexrank_from_bias_sents( bias_sents => \@sents, %other_params)

Computes lexrank using the given list of sentences as a bias. This method
temporarily adds these sentences to the graph, runs lexrank, and then
removes them. %other_params are parameters that can be given to the 
regular compute_lexrank. 

=cut

sub compute_lexrank_from_bias_sents {
  my $self = shift;
  my %params = @_;

  my @sents = @{ $params{bias_sents} } or die "'bias_sents' is required";
  my $graph = $self->{net}->{graph};
  my @vertices = $graph->vertices();
    
  # Making a new cluster from the sentences on this graph
  my $cluster = Clair::Cluster->new();
  foreach my $vertex (@vertices) {
    my $doc = $graph->get_vertex_attribute($vertex, "document");
    $cluster->insert($vertex, $doc);
  }

  # Adding the bias sentences to the new cluster
  my $i = 0;
  foreach my $sentence (@sents) {
    my $id = "bias$i";
    my $doc = Clair::Document->new(type => "text",
                                   string => $sentence, id => $id);
    $doc->stem();
    $cluster->insert($id, $doc);
  }

  # Generating the sim. matrix from this new cluster
  my %matrix = $cluster->compute_cosine_matrix( text_type => "text" );
  my $network = $cluster->create_network(
                                         cosine_matrix => \%matrix,
                                         include_zeros => 1
                                        );
    
  # Swapping the graph in self with the graph from the new network
  $self->{net}->{graph} = $network->{graph};

  # Compute lexrank with the bias sentences part of the network
  $self->centrality(%params);

  # Remove the bias sentences from the network
  for (my $i = 0; $i < @sents; $i++) {
    $self->{net}->remove_node("bias$i");
  }

  # Normalize the scores
  my $rank_matrix = $self->{net}->get_property_vector(\@vertices,
                                                      "lexrank_value");
  $self->{net}->make_matrix_stochastic($rank_matrix);
  $self->{net}->set_property_matrix(\@vertices, $rank_matrix, "lexrank_value");

  return $rank_matrix;
}


1;
