package Clair::Harmonic;

use Clair::Network;
use Clair::RandomWalk;
use Carp;

sub new{
      my $class = shift;
      my $net = shift;
      if(not defined $net) {
         croak "You should pass a proper Clair::Network object\n";
      }
      my $labels = shift;
      my $split = shift;
      my $self = bless{
                       network => $net
                       },$class;
      if(defined $labels){
          $self->load_labels($labels);
      }

      if(defined $split){
          $self->load_split($split);
      }
      return $self;
}

sub load_labels{
   my $self = shift;
   my $net = $self->{network};
   my $labels_file = shift;
   open(FILE,$labels_file) or die "Can't open labels file $1\n";
   while(<FILE>){
          $line=$_;
          chomp($line);
          my @labels = split(/\s+/,$line);
                   $node = @labels[0];
          $label = @labels[1];
          if(!$net->has_node($node)){
             croak "Node '$node' desn't exist in the network";
          }else{
             if(defined $label){
                $net->set_vertex_attribute($node,"label",$label);
             }else{
                croak "All nodes should be labeled\n";
             }
       }
   }
}

sub load_split{
   my $self = shift;
   my $net = $self->{network};
   my $split_file = shift;

   open FILE,$split_file or die "Can't open split file $1";
   while (<FILE>){
        my $line=$_;
        chomp($line);
        my @all=split(/\s+/,$line);
        my $node=$all[0];
        if($net->has_node($node)){
            $label=$net->get_vertex_attribute($node,"label");
            $net->set_vertex_attribute($node,"computed_label",$label);
            $net->set_vertex_attribute($node,"fixed",1);
        }
   }
   my @nodes=$net->get_vertices();
   foreach my $n (@nodes){
      if(not $net->get_vertex_attribute($n,"fixed")==1){
            $net->set_vertex_attribute($n,"computed_label",0.5);
            $net->set_vertex_attribute($n,"fixed",0);
      }
   }
}

sub relaxation{
    my $self = shift;
    my $net = $self->{network};
    my $output_file = shift;
    my @nodes = $net->get_vertices();
    my %link_hash = $net->get_adjacency_matrix(directed=>0);
    my $diff;
    my $iteration=0;
    open OUT,">$output_file" unless (not defined $output_file);
    do{
        $iteration++;
        print "$iteration\t";
        my %temp_labels=();
        $diff=0;
        my $accuracy=0;
        foreach $node (@nodes){
             my @neighbors = keys %{$link_hash{$node}};
             my $val = $net->get_vertex_attribute($node,"computed_label");
             if($val == 0 || $val==1){
                  $temp_labels{$node} = $net->get_vertex_attribute($node,"computed_label");
             }else{
                foreach my $n (@neighbors){
                    $temp_labels{$node}+= $net->get_vertex_attribute($n,"computed_label")/scalar(@neighbors);
                }
             }
             my $dif = $temp_labels{$node} - $net->get_vertex_attribute($node,"label");
             $accuracy += $dif*$dif;
             $diff += abs($temp_labels{$node} - $net->get_vertex_attribute($node,"computed_label"));
             foreach $n (keys %temp_labels){
                 $net->set_vertex_attribute($n,"computed_label", $temp_labels{$n});
             }
             printf  "$node: %6.4f\t",$temp_labels{$node};
             #printf OUT "$node: %6.4f\t",$temp_labels{$node} unless (not defined $output_file);
        }
        printf "A: $accuracy\n";
        #printf OUT "A: $accuracy\n" unless (not defined $output_file);
    }while($diff>0.00001);
    foreach $node (@nodes){
             printf OUT "$node %6.4f\n",$net->get_vertex_attribute($node,"computed_label");
    }

}

sub MonteCarlo{
   my $self = shift;
   my $net = $self->{network};
   my %params = @_;
   my $starting;
   my $rounds = 10000;
   my $output;
   if(defined $params{"start_node"}){
       $starting = $params{"start_node"};
   }
   if(defined $params{"rounds"}){
        $rounds = $params{"rounds"};
   }
   if(defined $params{"output"}){
        $output = $params{"output"};
   }
   my $rn = new Clair::RandomWalk($net,$starting);
   $rn->set_uniform_initial_probability_distribution();
   $rn->set_uniform_transition_probabilities();
   my $current_node;
   my @nodes = $net->get_vertices();
   my %stops = ();
   foreach my $node (@nodes){
            $stops{$node}=0;
     }
   my %results = ();
   foreach my $node (@nodes){
        if($net->get_vertex_attribute($node,"fixed")==0){
               foreach my $node (@nodes){
                     $stops{$node}=0;
               }
               my $i=1;
               foreach my $r (1..$rounds){
                     $rn->set_current_node($node);
                     while(1){
                             $current_node =  $rn->walk_one_random_step();
                             last if($net->get_vertex_attribute($current_node,"fixed")==1);
                             $i++;
                     }
                     $stops{$current_node}++;
               }
               my $label;
               my $freq = -1;
               my $successes=0;
               foreach my $key (keys %stops){
                       if($net->get_vertex_attribute($key,"fixed")){
                             if($net->get_vertex_attribute($key,"computed_label")==1){
                                 $successes+=$stops{$key};
                             }
                             $results{$key}=$net->get_vertex_attribute($key,"computed_label");
                       }
               }
               $results{$node}= $successes/$rounds;
       }
   }
   if(defined $output){
      open OUT,">$output" or die "Can't open file $!";
   }
   foreach my $n (sort {$a<=>$b} keys %results){
           printf "%5d\t",$n;
           if(defined $output){
               printf OUT "%5d\t",$n;
               printf OUT "%1.4f\n",$results{$n};
           }
   }
   print "\n";
   foreach my $n (sort {$a<=>$b} keys %results){
               printf "%1.4f\t",$results{$n};
   }
   print "\n";
}
1;

__END__

=pod

=head1 NAME

Clair::Harmonic - Compute the harmonic function using the methods of relaxation and the MoteCarlo

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

       use Clair::Network;

       $net = new Clair::Netowrk();
       $net->add_node("a");
       .....
       $net->add_edge("a","b");
       .....
       $harmonic = new Clair::Harmonic($net,$labels_file,$split_file);
       # The labels_file takes the following format:
       #     node1  label1
       #     node2  label2
       #     .....  ......

       # The split_file takes the following format:
       #     node1
       #     node2
       #     .....
       # It's a list of the fixed nodes only.

       $harmonic->relaxation($output_file1);
       $harmonic->MonteCarlo($output_file2);

=head1 METHODS

=head2 new

Function  : Creates a new instance of the Clair::Harmonic

Usage     : $harmonic = new Clair::Harmonic($net[,$labels_file, $split_file]);

Parameters: - $net: a Clair::Netowrk instance, $labels_file: a list of the labels of all the nodes
$split_file: a list of the nodes whose labels should be fixed.

returns   : Clair::Harmonic obejct

=head2 load_labels

Function  : Loads the node labels from a file

Usage     : $harmonic->load_labels($file)

Parameters: A file containg a list of node labels (node label)

returns   : nothing

=head2 load_split

Function  : Load a list of the nodes to be fixed from a file.

Usage     : $harmonic->load_split($file)

Parameters: A file containg a list of fixed nodes.

returns   : Nothing

=head2 relaxation

Function  : Computes the labels of the unfixed nodes using the method of relaxation.

Usage     : $harmonic->relaxation($file)

Parameters: The name of a file to output the results to.

returns   : nothing

=head2 MonteCarlo

Function  : Computes the labels of the unfixed nodes using the MonteCarlo Method

Usage     : $harmonic->MonteCarlo($file

Parameters: The name of a file to output the results to.

returns   : Nothing

=head1 AUTHOR

Amjad Abu Jbara << <clair at umich.edu> >>

=head1 See Also

Clair::Network, Clair::RandomWalk

=cut