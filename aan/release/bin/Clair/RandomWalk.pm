package Clair::RandomWalk;

use Clair::Network;
use Carp;
use Clair::RandomDistribution::RandomDistributionFromWeights;

sub new{
      my $class = shift;
      my $net = shift;
      if(not defined $net){
         croak "You should pass a proper Clair::Network object\n";
      }
      $current_node = shift;
      if(not defined $current_node){
            my @nodes = $net->get_vertices();
            $current_node = $nodes[0];
      }
      my $self = bless{
                       network => $net,
                       current_node => $current_node
                       },$class;
      return $self;
}

sub load_transition_probabilities_from_file{
    my $self=shift;
    my $net = $self->{network};
    my $file = shift;
    $net->read_transition_probabilities_from_file($file);
    $net->make_transitions_stochastic();
}

sub load_initial_probability_distribution_from_file{
    my $self=shift;
    my $net = $self->{network};
    my $file = shift;
    $net->read_initial_probability_distribution($file);
}

sub compute_stationary_distribution{
    my $self=shift;
    my $net = $self->{network};
    return $net->compute_stationary_distribution();
}

sub wrtie_porbability_distribution_to_file{
    my $self=shift;
    my $net = $self->{network};
    my $file = shift;
    $net->save_current_probability_distribution($file);
}

sub set_uniform_transition_probabilities{
    my $self=shift;
    my $net = $self->{network};
    my %adj = $net->get_adjacency_matrix(directed=>0);
    foreach my $node (@nodes){
        my @neighbours = keys %{$adj{$node}};
        foreach my $neighbour (@neighbours){
                $net->set_edge_attribute($node, $neighbour, "transition_prob", $net->out_degree($node));
        }
    }
    $net->make_transitions_stochastic();
}

sub set_uniform_initial_probability_distribution{
    my $self=shift;
    my $net = $self->{network};
    my @nodes = $net->get_vertices();
    foreach my $node (@nodes){
        $net->set_vertex_attribute($node, "current_prob", 1/scalar(@nodes));
    }
}

sub walk_one_random_step{
    my $self=shift;
    my $net = $self->{network};
    my $current_node = $self->{current_node};
    my %adj = $net->get_adjacency_matrix(directed=>0);
    my @neighbours = keys %{$adj{$current_node}};
    my @weights=();
    unshift @weights, 0;
    foreach my $neighbour (@neighbours){
           push @weights, $net->get_edge_attribute($current_node,$neighbour,"transition_prob");
    }
    my $distribution = Clair::RandomDistribution::RandomDistributionFromWeights->new(weights => \@weights);

    my $rnd = $distribution->draw_rand_from_dist();
    $self->{current_node}= $neighbours[$rnd-1];
    return $neighbours[$rnd-1];
}

sub walk_random_steps{
    my $self = shift;
    my $steps = 1;
    $steps = shift;
    for (my $i=0; $i<$steps; $i++){
         $self->walk_one_random_step;
    }
    return $self->{current_node};
}

sub compute_porbability_distribution{
    my $self=shift;
    my $net = $self->{network};
    my $rounds = 1000;
    $rounds=shift;
    my $steps = 100;
    $steps = shift;
    my %stops=();
    my @nodes = $net->get_vertices();
    foreach my $node (@nodes){
        $stops{$node}=0;
     }
    foreach my $r (1..$rounds){
            $stops{$self->walk_random_steps($steps)}++;
    }
    foreach $node (@nodes){
            $net->set_vertex_attribute($node, "current_prob",$stops{$node}/$rounds);
    }
    return $net->get_current_probability_distribution();
}

sub print_current_probability_distribution{
    my $self=shift;
    my $net = $self->{network};
    $net->print_current_probability_distribution();
}

sub set_current_node{
    my $self = shift;
    my $node = shift;
    $self->{current_node} = $node;
}

1;

__END__

=pod

=head1 NAME

Clair::RandomNetwork - Random Walk on graphs

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

       use Clair::RandomWalk;
       use Calir::Network;

       $net = new Clair::Netowrk();
       $net->add_node("a");
       .....
       $net->add_edge("a","b");
       .....

       $rn = new Clair::RandomWalk($net,"a");
       $rn->load_transition_probabilities_from_file("trans");
       #trans is a file in the following format: src_node dest_node trasnition_prob.
       $rn->load_initial_probability_distribution_from_file("probs");
       #probs is a file in the following format: node prob
       $rn->walk_random_steps(100);
       $rn->print_current_probability_distribution();

=head1 METHODS

=head2 new

Function  : Creates a new instance of the Clair::RandomNetwork

Usage     : $rn = new Clair::RandomNetwork($net,$start_node);

Parameters: - $net: a Clair::Netowrk instance, $start_node: The node from which
the random walk should start.

returns   : Clair::RandomWalk obejct

=head2 load_transition_probabilities_from_file

Function  : Loads the transition probabilities between the nodes from a file

Usage     : $rn->load_transition_probabilities_from_file($file)

Parameters: The name of a file formated as : src_node dest_node trans_prob

returns   : nothing

=head2 load_initial_probability_distribution_from_file

Function  : Loads the initial probability distribution of the graph nodes from a file

Usage     : $rn->load_initial_probability_distribution_from_file($file)

Parameters: The name of a file formated as : node prob

returns   : Nothing

=head2 compute_stationary_distribution

Function  : Computes the stationary probability distribution (The probability after
walking too many steps). This uses the values from the probability distribution
and the transition probabilities

Usage     : %sd = $rn->compute_stationary_distribution()

Parameters: Nothing

returns   : A hash of node probabilities (key: node, value: probability)

=head2 wrtie_porbability_distribution_to_file

Function  : Write the current probability distribution of the nodes to a file

Usage     : $rn->wrtie_porbability_distribution_to_file($file)

Parameters: An output file name.

returns   : Nothing

=head2 print_current_probability_distribution

Function  : Print the current probability distribution of the nodes on the screen

Usage     : $rn->print_current_probability_distribution()

Parameters: Nothing

returns   : Nothing

=head2 set_uniform_transition_probabilities

Function  : Set the transition probability of each edge (src_node dest_node) to
1/(out degree of src_node)

Usage     : $rn->set_uniform_transition_probabilities()

Parameters: Nothing

returns   : Nothing

=head2 set_uniform_initial_probability_distribution

Function  : Set the initial probability of each node to 1/(number of nodes)

Usage     : $rn->set_uniform_initial_probability_distribution()

Parameters: Nothing

returns   : Nothing

=head2 set_uniform_initial_probability_distribution

Function  : Set the initial probability of each node to 1/(number of nodes)

Usage     : $rn->set_uniform_initial_probability_distribution()

Parameters: Nothing

returns   : Nothing

=head2 walk_one_random_step

Function  : Walk one random step

Usage     : $rn->walk_one_random_step()

Parameters: Nothing

returns   : The node at which the walk ends after its random step.

=head2 walk_random_steps

Function  : Walk multiple random steps

Usage     : $rn->walk_random_steps($steps)

Parameters: The number of random steps to walk

returns   : The node at which the walk ends after walking the specified random steps.

=head2 compute_porbability_distribution

Function  : Compute the probability distribution after walking randomly a specified
number of steps

Usage     : $rn->compute_porbability_distribution($steps)

Parameters: The number of random steps to walk

returns   : The node at which the walk ends after walking the specified random steps.

=head2 set_current_node

Function  : Set the cursor of the random walk to a specific node.

Usage     : $rn->set_current_node($node)

Parameters: A graph node.

returns   : Nothing.

=head1 AUTHOR

Amjad Abu Jbara << <clair at umich.edu> >>

=head1 See Also

Clair::Network

=cut