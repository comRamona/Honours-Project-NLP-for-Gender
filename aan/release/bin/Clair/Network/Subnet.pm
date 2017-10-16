#class Subnet
package Clair::Network::Subnet;

#
# This class extracts the subgraph centered around a specified node from
# an original large network.
# The node is represented in the same form as in the original network. 
# For example, if it is a query network, then the center node
# should be be specified as queries (strings). 
# 
# Author: Xiaodong Shi
# Date: 11-09-2007
#

use strict;

use Clair::Network;


#constructor that accepts the original network as input
sub new {
    my ($class, $network) = @_;
 
    my $self = {
        _net => $network
	};
    
    bless($self, $class);
    return($self);
}


sub BFS_extract_from {
    my $self = shift;
    my $network = $self->{_net};
    my $center_node = shift;

    my %parameters = @_;

    my $depth = 3;
    if (defined $parameters{depth}) {
	$depth = $parameters{depth};
	if ($depth < 1) {
	    $depth = 1;
	}
    }

    my $threshold = 0;
    if (defined $parameters{threshold}) {
	$threshold = $parameters{threshold};
    }

    my $directed = 0;
    if (defined $parameters{directed}) {
	$directed = $parameters{directed};
    }

    my $predefined_query = 0;
    if (defined $parameters{predefined_query}) {
	$predefined_query = $parameters{predefined_query};
    } 

    my %predefined_query_hash = ();
    if ($predefined_query) {
	my $predefined_query_hash_ref;
	if (defined $parameters{predefined_query_hash}) {
	    $predefined_query_hash_ref = $parameters{predefined_query_hash};
	}
	
	if (defined $predefined_query_hash_ref) {
	    %predefined_query_hash = %{$predefined_query_hash_ref};
	}
    }
    

    # get the vertices of the whole network
    my @vertices = $network->get_vertices();
    
    printf "Size of the entire network: \n";
    printf "\tNum. Vertices = " . scalar(@vertices) . "\n";
    printf "\tNum. Edges =    " . scalar($network->num_links()) . "\n";

    
    # first check if the specified center node exists in the network. 
    # if not, prompt the error and quit the program
    unless ($network->has_node($center_node)) {
	printf "ERROR: the specified center node does not exist in the retrieved network! Quited!\n";
	return;
    }
    
    
    # run the Breadth First Search (BFS) starting from the center node
    my @queue = ();  # working queue
    my %nodes = ();  # extracted nodes 
    push (@queue, $center_node);
    $nodes{$center_node} = 1;
    
    
    # Breath First Search (BFS) with the specified maximum depth
    print "Running BFS with starting node $center_node and max. depth $depth ... \n";
    my $cur_depth = 1;
    for (my $d=1; $d<=$depth; $d++) {
	my @list = ();
	printf "\tDepth=" . ($d-1) . ": ";
	for (my $i=0; $i<scalar(@queue); $i++) {
	    printf $queue[$i];
	    if ($i ne (scalar(@queue)-1)) {
		printf " | ";
	    }
	    
	    for (my $j=0; $j<scalar(@vertices); $j++) {	    
		if (not exists $nodes{$vertices[$j]}) {
		    if ($predefined_query eq 0 || (($predefined_query eq 1) and \
						   (exists $predefined_query_hash{$vertices[$j]}))) {
			my $eij = -1;
			my $eji = -1;
			
			if ($network->has_edge($queue[$i], $vertices[$j])) {
			    $eij = $network->get_edge_weight($queue[$i], $vertices[$j]);
			}
			elsif ($network->has_edge($vertices[$j], $queue[$i])) {
			    $eji = $network->get_edge_weight($vertices[$j], $queue[$i]);
			}
			
			if ($eij > $threshold || $eji > $threshold) {
			    push (@list, $vertices[$j]);
			    $nodes{$vertices[$j]} = 1;
			}
		    }
		}
	    }
	}
	print "\n";
	@queue = @list;
    }
    
    my @vs = keys %nodes;
    print "Finished! Num. neighbors retrieved = " . scalar(@vs) . "\n";
    
    
    # construct the subgraph with the extracted nodes
    print "Now constructing extracted subgraph ... ";
    my $subnet = Clair::Network->new(directed => $directed);

    # add nodes into the empty sub network
    foreach my $v (@vs) {
	$subnet->add_node($v, text => $v);
    }
    
    # Connect the nodes in the network if they are connected in the original network
    foreach my $v1 (@vs) {
	foreach my $v2 (@vs) {
	    if ($v1 ne $v2) {
		if (not $directed) {
		    if ((($network->has_edge($v1, $v2) and $network->get_edge_weight($v1, $v2) > $threshold) || 
			 ($network->has_edge($v2, $v1) and $network->get_edge_weight($v2, $v1) > $threshold)) and 
			(not ($subnet->has_edge($v1, $v2) || $subnet->has_edge($v2, $v1)))) {
			$subnet->add_edge($v1, $v2);
			$subnet->set_edge_weight($v1, $v2, $network->get_edge_weight($v1, $v2));
		    }
		}
		else {
		    if (($network->has_edge($v1, $v2)) and ($network->get_edge_weight($v1, $v2) > $threshold)) {
			$subnet->add_edge($v1, $v2); 
			$subnet->set_edge_weight($v1, $v2, $network->get_edge_weight($v1, $v2));
		    }
		    
		    if (($network->has_edge($v2, $v1)) and ($network->get_edge_weight($v2, $v1) > $threshold)) {
			$subnet->add_edge($v2, $v1);
			$subnet->set_edge_weight($v2, $v1, $network->get_edge_weight($v2, $v1));
		    }
		}
	    }
	}
    }

    return $subnet;
}


return (1);
