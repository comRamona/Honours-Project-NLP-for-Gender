package Clair::Network::Centrality::CPPLexRank;
use Clair::Network::Centrality::LexRank;
@ISA = ("Clair::Network::Centrality::LexRank");

use strict;
use warnings;
use Clair::Network;

use vars qw($VERSION);

$VERSION = '0.01';

=head1 NAME

Clair::Network::Centrality::CPPLexRank - Class for computing LexRank
centrality using C++ code


=cut

=head1 SYNOPSIS

my $lexrank = Clair::Network::Centrality::CPPLexRank->new($net);
my %b = $lexrank->centrality();
my $node_lexrank = $lexrank->node_centrality($node);

=cut

=head1 DESCRIPTION

This class will compute CPPLexRank centrality.

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

  my $graph = $self->{net}->{graph};
  my @vertices = $graph->vertices();

  my %user_params = @_;
  my %params = (
                random_jump => 0.15,
               );
  foreach my $key (keys %user_params) {
    $params{$key} = $user_params{$key};
  }

  # These are temp files that are needed by the prmain program
  my $cos_file = "cos.temp";
  my $bias_file = "bias.temp";
  my $out_file = "out.temp";

  # The transition matrix
  my $rank_matrix = $self->{net}->get_property_matrix(\@vertices, 
                                                      "lexrank_transition");

  #die "Lexrank matrix should be symmetric" 
  #    unless $rank_matrix->is_symmetric;

  #for (my $i = 0; $i < ($rank_matrix->dim())[0]; $i++) {
  #    die "Lexrank matrix should have 1's along the diagonal"
  #        unless ($rank_matrix->element($i + 1, $i + 1) == 1);
  #}

  # The bias vector
  my $v_matrix = $self->{net}->get_property_vector(\@vertices, "personalization");

  $self->{net}->make_matrix_stochastic($rank_matrix);
  $self->{net}->make_matrix_stochastic($v_matrix);

  # $m should equal $n
  my ($m, $n) = $rank_matrix->dim();

  # Writes the cosine file
  open COS, "> $cos_file" or die "Could not open cos.temp for writing: $!";
  for (my $i = 0; $i < $n; $i++) {
    for (my $j = 0; $j < $i; $j++) {
      my $value = $rank_matrix->element($i + 1, $j + 1);
      print COS "$i\t$j\t$value\n";
      print COS "$j\t$i\t$value\n";
    }
  }
  close COS;

  # Writes the bias file
  open BIAS, "> $bias_file" or die "Could not open bias.temp for writing: $!";
  for (my $i = 0; $i < $n; $i++) {
    my $value = $v_matrix->element($i + 1, 1);
    print BIAS "$i\t$value\n";
  }
  close BIAS;

  # Build the command for running lexrank
  my $prmain = $self->{net}->{prmain};
  my $max_id = $n - 1;
  my $jump = $params{random_jump};
  my $command = "$prmain -link $cos_file -maxid $max_id -jump $jump "
    . "-out $out_file -bias $bias_file 2>/dev/null";

  # Runs lexrank
  my @scores;
  if ( system($command) == 0 ) {
    open OUT, "< $out_file" or die "Could not read $out_file: $!";
    while (<OUT>) {
      chomp;
      my ($node, $value) = split /\s+/, $_;
      push @scores, $value;
    }
    close OUT;
  } else {
    die "There was an error running $prmain";
  }

  # Setting the vertex attributes
  for (my $i = 0; $i < $n; $i++) {
    $graph->set_vertex_attribute(
                                 $vertices[$i], "lexrank_value", $scores[$i]);
  }

  # Cleaning up
  if ($self->{net}->{clean}) {
    unlink($cos_file) or warn "Couldn't unlink $cos_file: $!";
    unlink($bias_file) or warn "Couldn't unlink $bias_file: $!";
    unlink($out_file) or warn "Couldn't unlink $out_file: $!";
  }

  return $self->{net}->get_property_hash("lexrank_value");
}

=head2 _normalized_centrality

Normalized centrality for CPPLexRank centrality.

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

=head2 compute_lexrank_from_bias_sents

compute_lexrank_from_bias_sents( bias_sents => \@sents, %other_params)

Computes lexrank using the given list of sentences as a bias. This
method temporarily adds these sentences to the graph, runs lexrank,
and then removes them. %other_params are parameters that can be given
to the regular compute_lexrank.

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
  $self->{net}->set_property_matrix(\@vertices, $rank_matrix,
                                    "lexrank_value");

  return $rank_matrix;
}


1;
