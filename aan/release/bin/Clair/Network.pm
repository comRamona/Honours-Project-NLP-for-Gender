package Clair::Network;


=head1 NAME

Clair::Network - Network Class for the CLAIR Library

head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

The Network Class is one of the core modules for the CLAIR library.  The Network described a structure
of relationships between nodes, and has operations for performing many typical graph functions, such as
finding the diameter of the graph, adding and removing normal and external nodes, and creating edges.

=head1 METHODS

=cut


=head2 new

$network = new Clair::Network();

Creates a new, empty network

=cut



=head2 add_node

add_node($id, $text)

Adds a vertex to the graph.  Vertex has attribute text set to $text

=cut



=head2 remove_node

remove_node($id)

Removes the vertex with id $id from the graph

=cut


=head2 add_edge

add_edge($id1, $id2);

Creates an edge between the two vertices specified.  If a vertex is not already part
of the graph, it is automatically added.

=cut


=head2 remove_edge

remove_edge($u, $v)

Removes the edge from $u to $v from the graph.

=cut


=head2 set_node_weight

set_node_weight($id, $weight)

Set the weight of node $id.

=cut


=head2 get_node_weight

get_node_weight($id)

Returns the weight of the specified vertex.

=cut


=head2 find_path

@path = find_path($s, $v)

Finds the shortest path from $s to $v using the Floyed Warshall algorithm.

=cut



=head2 compute_cohesion

compute_cohesion

Computes the cohesion of the documents in the network.

=cut



=head2 export_to_Pajek

export_to_Pajek($networkName, $filename)

Write the network to the file $filename in Pajek form, giving it the specified network name.

=cut


=head2 num_documents

num_documents

Returns the number of documents in the network

=cut



=head2 num_pairs

num_pairs

Returns the number of pairs of documents, defined as nd * (nd - 1) / 2 where nd is the number
of documents.

=cut



=head2 num_links

num_links

Returns the number of links (edges) in the network.  If the parameter external is specified
and set to 1 (or internal is specified and set to 0), the number of external links is returned,
otherwise the number of internal links is given.  If the parameter unique is specified and equal
to 1, only unique links will be counted.

=cut



=head2 compute_in_link_histogram

compute_in_link_histogram()

Returns a histogram of the number of inlinks per node in the network

=cut



=head2 avg_in_degree

avg_in_degree()

Returns the average number of inlinks per node in the network

=cut



=head2 compute_out_link_histogram

compute_out_link_histogram()

Returns a histogram of the number of outlinks per node in the network

=cut



=head2 avg_out_degree

avg_out_degree()

Returns the average number of outlinks per node in the network

=cut



=head2 compute_total_link_histogram

compute_total_link_histogram()

Returns a histogram of the number of links (both out and in) per node in the network

=cut



=head2 avg_total_degree

avg_total_degree()

Returns the average number of links (both out and in) per node in the network

=cut



=head2 power_law_exponent

power_law_exponent($histogram_reference)

Computes the power law coefficient on the histogram passed in by reference.
This uses linear regression on the logs of the data points to find both the
coefficient and the exponent.

Retun value is a string of the form "y = a x^b" where a is the coefficient and
b is the exponent.

=cut


=head2 newman_power_law_exponent

newman_power_law_exponent($histogram_reference, $x_cutoff)

Computes the power law exponent on the histogram passed in by reference.
This uses the method described in Newman\'s "Power laws, Pareto distributions
and Zipf's law", formula 5 and 6.

Return value is an array containing two items, the power law exponent, and a
measure of the statistical error

=cut



=head2 power_law_out_link_distribution

power_law_out_link_distribution()

Returns the power law formula from the out link distribution

=cut



=head2 power_law_in_link_distribution

power_law_in_link_distribution()

Returns the power law formula from the in link distribution

=cut



=head2 power_law_total_link_distribution

power_law_total_link_distribution()

Returns the power law formula from the total link distribution
(both in and out links)

=cut



=head2 diameter

diameter(filename => $filename, directed => 1, max => 0)

Returns the diameter of the network.  If the parameter 'directed' is 1
or not specified, this is the diameter of the directed network.  If it
is 0 or the parameter 'undirected' is 1, then this is the diameter of
the undirected network.  If max is 1 or not specified, then this is the
maximum diameter.  If max is 0 or avg is 1, then this is the average diameter.

A filename may also be specified to produce debugging information while
the diameter is being determined.

=cut


=head2 average_shortest_path

average_shortest_path()

Finds the average shortest path of a graph.  The average shortest path is the
average of all of the shortest paths between pairs of vertices.  To compute
this, we loop through each vertex, computing the shortest paths to all vertices
that vertex reaches.  The average of that vertex is then computed.  This is
repeated for all vertices with greater than zero out-degree in the graph, and
the average of that is returned.

=cut


=head2 write_links

write_links($filename, skip_duplicates => 1, transpose => 1, weights => 0)

Writes the network links to a file.  If the parameter skip_duplicates
is specified as 1, duplicate edges are skipped.  If the parameter
transpose is 1, the links are written transposed.


=cut



=head2 write_nodes

write_nodes($filename)

Writes the list of nodes in the network to a file.

=cut



=head2 Watts_Strogatz_clus_coeff

Watts_Strogatz_clus_coeff(filename => $filename)

Computes the Watts Strogatz clustering coefficient.  If a
filename is provided, intermediate output is written to
the file.

=cut



=head2 write_db

write_db($filename, transpose => 1)

Writes the graph's links to a db file.  Links are written
transposed if the parameter transpose is provided and
equal to 1.

=cut



=head2 dfs_visit_1

An internal function used by find_scc

=cut



=head2 iterative_dfs_visit_1

An internal function used by find_scc

=cut



=head2 iterative_dfs_visit_1_v2

An internal function used by find_scc

=cut



=head2 dfs_visit_2

An internal function used by find_scc

=cut



=head2 iterative_dfs_visit_2

An internal function used by find_scc

=cut



=head2 iterative_dfs_visit_2_v2

An internal function used by find_scc

=cut



=head2 find_scc

find_scc($dbfile, $xpfile, $finfile)
$dbfile should be the filename of a db file of the links
that will be used by find_scc (the file can be produced
with write_db)
$xpfile should be the filename of a db file of the links
tranposed
$finfile is the location where a temporary file should go
that will be used by find_scc and the helper functions

find_scc finds a strongly connected subgraph from the graph
of the network.  It needs to input files, a db file of the
links and a db file of the transposed links.

=cut

=head2 find_largest_component

find_largest_component($type)

type is the type of component, either "weakly" or "strongly"

Finds the largest component in a graph, returning a network made up of that
component.

=cut


=head2 write_link_matlab

write_link_matlab($histogram_reference, $filename, $dependency)

Writes a Matlab for the histogram.  $histogram_reference should
be a reference to the histogram that should be written to the
matlab file.  $dependency is the names of any dependencies that
the Matlab file should have

=cut



=head2 write_link_dist

write_link_dist($histogram_reference, $filename)

Writes a link distribution file for the histogram that is passed in
by reference

=cut



=head2 average_cosines

($linked_avg, $not_linked_avg) = average_cosines($cosine_matrix_reference)

Returns the average of the cosines between documents that are connected
in the matrix and between documents that are not connected.  The averages
are returned in an array.

=cut



=head2 get_index

An internal function used by cosine_histograms.  Used to determine
what bin a cosine value should go into.

=cut



=head2 cosine_histograms

cosine_histograms($cosine_matrix_reference)

Returns a histograms for cosines that are linked in the
graph and for cosines that are not.

=cut



=head2 write_histogram_matlab

write_histogram_matlab($linked_histogram_reference, $not_linked_histogram_reference, $filename_base)

Writes matlab files for linked, linked cumulative, and not linked
histograms based on the histogram distributions given.

=cut



=head2 get_histograms_as_string

get_histograms_as_string($linked_histogram_reference, $not_linked_histogram_reference)

Returns the histograms as a human-readable string that can be displayed
or saved to a file

=cut



=head2 create_cosine_dat_files

create_cosine_dat_files($domain, $cosine_matrix_reference, directory => $directory)

Creates dat files with information from the cosine matrix, based on
randomly selected cosines

=cut



=head2 get_dat_stats

get_dat_stats($domain, $links_file, $cosine_file)

Returns a string with statistics obtained from the analyzing the dat
files created by create_cosine_dat_files

=cut



=head2 get_undirected_graph

get_undirected_graph($graph)

Takes a graph and returns its undirected equivalent.  This maintains the weight
on each edge and vertex.

=cut


=head2 mmr_rerank_lexrank

mmr_rerank_lexrank($lambda)

Reranks the lexrank scores using maximal marginal relevance. The parameter
$lambda should be in [0,1]. $lambda = 1 implies that the score will be
unchanged. $lambda = 0 will make the scores the negative of their similarity
with the first sentence. After calling mmr_rerank_lexrank, the scores
will be scaled so the highest score is 1 and the lowest score is 0. This
method should only be called after lexrank has been computed.

=cut

=head2 compute_pagerank

compute_pagerank(pagerank_value => 'pagerank_value', pagerank_transition => 'pagerank_transition',
pagerank_bias => 'pagerank_bias', jump => 0.15, tolerance => 0.0001, max_iterations => 200)

Computes the pagerank for the network.  The property given for pagerank_value is used for the
initial value, and for pagerank_transition for the transition probabilities.  The pagerank_bias
property is used to set the bias.  If the network does not have any values for that property
(or they are all zero) then the unbiased pagerank is computed.

All parameters are optional, the defaults for the properties are given.  Passing zero for any
numerical parameter (or not specifying that parameter) will cause the default value to be used.

The result is saved as the pagerank_value property of each node.

=cut


=head2 compute_stationary_distribution

compute_stationary_distribution

Computes the stationary distribution from a random walk.  This uses the values from the
probability distribution and the transition probabilities.

=cut


=head2 create_cluster_from_lexrank

create_cluster_from_lexrank($threshold, attribute_name => 'document', parent_document => 0)

Creates a cluster with any documents that currently have a lexrank value above the threshold.
The optional attribute_name parameter specifies what attribute of the node contains the
document.  'document', the default, is the attribute that will be used if the network
was created from a cluster.  Setting the optional parent_document parameter to 1 will
create the cluster out of the parent document of each document, rather than the document
itself.



=cut


=head2 create_network_from_lexrank

create_network_from_lexrank

Creates a network with any nodes that currently have a lexrank value above the threshold.

=cut


=head2 create_subset_network

create_subset_network($@subset_vertices);

Creates a network with just the nodes in the array provided as the first parameter.  Edges
from the original network are carried across to the network if they are between two
nodes that are in the new network.

=cut


=head2 create_subset_network_from_file

create_subset_network_from_file($filename)

Creates a network with just the nodes listed in the file, one per each line.  Edges from
the original network are carried across to the new network if they are between two
nodes that are in the new network.

=cut


=head2 get_current_probability_distribution

get_current_probability_distribution

Returns a hash with the current probability values (the values used for the random walk)

=cut


=head2 get_edge_attribute

get_edge_attribute($u, $v, $attribute_name)

Returns the value of the attribute on the given edge

=cut


=head2 get_edge_weight

get_edge_weight($u, $v)

Returns the weight of the given edge.

=cut


=head2 get_edges

get_edges

Returns the edges of the network

=cut


=head2 get_vertex_attribute

get_vertex_attribute($u, $attribute_name)

Returns the value of the attribute on the given vertex

=cut


=head2 get_vertices

get_vertices

Returns the array of vertices (nodes) in the network

=cut


=head2 has_edge

has_edge($u, $v)

Returns true if an edge exists in the network, false otherwise

=cut


=head2 has_edge_attribute

has_edge_attribute($u, $v, $attribute_name)

Returns true if the attribute has been set on the given edge and false otherwise.

=cut


=head2 has_node

has_node($u)

Returns true if the node is in the network

=cut


=head2 has_vertex_attribute

has_vertex_attribute($u, $attribute_name)

Returns true if the attribute has been set on the given vertex and false otherwise.

=cut


=head2 num_nodes

num_nodes

Returns the number of nodes in the network

=cut


=head2 print_current_lexrank_distribution

print_current_lexrank_distribution

Prints the current lexrank values.  If the lexrank has been calculated, these are the
results, otherwise this may be the initial or intermediate values.

=cut


=head2 print_current_pagerank_distribution

print_current_pagerank_distribution

Prints the current pagerank values.  If the pagerank has been calculated, these are the
results, otherwise this may be the initial or intermediate values.

=cut


=head2 print_hyperlink_edges

print_hyperlink_edges

Prints all edges with the 'pagerank_transition' property set.  In the case of networks
built from hyperlinks from clusters, these edges are the edges that had a hyperlink
between them.

The edges are listed as source, then destination.

=cut


=head2 print_current_probability_distribution

print_current_probability_distribution

Prints the current probability values from the random walk.  If the stationary distribution
has been calculated, these are the results, otherwise these may be the initial or
intermediate values

=cut


=head2 read_initial_probability_distribution

read_initial_probability_distribution($filename)

Reads the initial probabilities for the random walk from the specified file.

=cut



=head2 read_pagerank_initial_distribution

read_pagerank_initial_distribution($filename)

Reads the initial pagerank values from the specified file

=cut


=head2 read_pagerank_personalization

read_pagerank_personalization($filename)

Reads the pagerank personalization values (bias) from the specified file

=cut


=head2 read_pagerank_probabilities_from_file

read_pagerank_probabilities_from_file($filename)

Read the pagerank transition probabilities from the specified file

=cut


=head2 save_current_pagerank_distribution

save_current_pagerank_distribution($filename)

Saves the current pagerank values to a file.  If pagerank has been calculated, then these
are the results, otherwise these could be initial or intermediate values.

=cut


=head2 save_hyperlink_edges_to_file

save_hyperlink_edges_to_file($filename)

Saves all edges with the 'pagerank_transition' property set to the specified file.
In the case of networks built from hyperlinks from clusters, these edges are the
edges that had a hyperlink between them.

The edges are listed as source, then destination.


=cut


=head2 save_pagerank_probabilities_to_file

save_pagerank_probabilities_to_file

Saves the transition probabilities used in pagerank to the specified file.

=cut


=head2 set_edge_attribute

set_edge_attribute($u, $v, $attribute_name, $value)

Sets the attribute for the given edge to the given value

=cut


=head2 set_edge_weight

set_edge_weight($u, $v, $weight)

Sets the weight of the given edge.

=cut


=head2 set_vertex_attribute

set_vertex_attribute($u, $attribute_name, $value)

Sets the attribute for the vertex to the given value

=cut


=head2 get_predecessor_matrix

$matrix = get_predecessor_matrix()

Get the shortest path matrix from the network, using BFS algorithm.

The content of the matrix is the predecessor of the current node in the shortest path matrix.

e.g. : $matrix->{$i}->{$j} notes the predecessor of node $j in the shortest path from $i to $j

to get the shortest path from $i to $j, you can use function get_shortest_path

=cut


=head2 get_shortest_path

$path = get_shortest_path($start, $end)

Get the shortest path from $start to $end.

=cut


=head2 func

func



=cut


=head2 func

func



=cut


=head1 AUTHOR

Hodges, Mark << <clair at umich.edu> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-clair-document at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=clairlib-dev>.
I will be notified, and then you will automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Clair::Network

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/clairlib-dev>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/clairlib-dev>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=clairlib-dev>

=item * Search CPAN

L<http://search.cpan.org/dist/clairlib-dev>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 The University of Michigan, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


use lib("../");

use Graph::Directed;
use Graph::Undirected;
use Clair::GraphWrapper;
use BerkeleyDB;
use MLDBM qw(DB_File Storable);
use Math::MatrixReal;
use Clair::Config;
use Clair::Document;
use Clair::Util;
use Clair::Utils::SimRoutines;
use Storable qw/dclone/;        # For component extraction code
use File::Temp qw/tempfile tempdir/;
# Temporary, remove when export_ and import_ functions are removed
use Clair::Network::Reader::Pajek;
use Clair::Network::Reader::Edgelist;
use Clair::Network::Writer::Pajek;
use Clair::Network::Writer::Edgelist;
use Clair::Statistics::Distributions::TDist;


our @EXPORT_OK   = qw($verbose);

use vars qw($verbose);

$verbose = 0;

sub new {
  my $class = shift;
  my %parameters = @_;

  my $directed = 1;
  if ((exists $parameters{directed} and $parameters{directed} == 0) ||
      (exists $parameters{undirected} and $parameters{undirected} == 1)) {
    $directed = 0;
  }

  my $unionfind = 0;
  if (exists $parameters{unionfind} and $parameters{unionfind} == 1) {
    $unionfind = 1;
  }

  my $filebased = 0;
  if (exists $parameters{filebased} and $parameters{filebased} == 1) {
    $filebased = 1;
  }

  my $graph;
  if (exists $parameters{graph}) {
    # If user specified graph, use that
    $graph = $parameters{graph};
    if ($graph->is_directed()) {
      $directed = 1;
    } else {
      $directed = 0;
    }
  } else {
    # Otherwise, create a new graph object
    if ($directed) {
      $graph = Graph::Directed->new(unionfind => $unionfind);
    } else {
      $graph = Graph::Undirected->new(unionfind => $unionfind);
    }
  }

  my $self = bless {
                    graph => $graph,
                    directed => $directed,
                    filebased => $filebased
                    }, $class;

  return $self;
}


sub get_predecessor_matrix {
        my $self = shift;

        my $graph = $self->{graph};
        my @nodes = $self->get_vertices();

        my %matrix;
        my @queue;
        my $currentNode;

        foreach $node(@nodes) {
                my %seen;
                $currentNode = $node;

                $seen{$node} = 1;
                push (@queue, $node);
                while ($#queue >= 0) {
                        $currentNode = shift(@queue);
                        @s = $graph->successors($currentNode);
                        foreach $s(@s) {
                                if ($seen{$s} != 1) {
                                        $matrix{$node}{$s} = $currentNode;
                                        $seen{$s} = 1;
                                        push(@queue, $s);
                                }
                        }
                }
        }
        $self->{predecessor_matrix} = \%matrix;

        return \%matrix;
}

sub get_shortest_path {
        my $self = shift;
        my $start = shift;
        my $end = shift;

        my $matrix;
        if (! exists $self->{predecessor_matrix}) {
                $matrix = $self->get_predecessor_matrix();
        } else {
                $matrix = $self->{predecessor_matrix};
        }

        my @path;
        my $node = $matrix->{$start}->{$end};
        unshift(@path, $end);
        while ($node ne $start) {
                unshift(@path, $node);
                $node = $matrix->{$start}->{$node};
        }
        unshift(@path, $node);

        return \@path;
}



sub DESTROY {
  my $self = shift;

  if (defined $self->{adjacency_matrix}) {
    untie %{$self->{adjacency_matrix}};
  }
  if (defined $self->{adjacency_matrix_file}) {
    unlink $self->{adjacency_matrix_file} or die "Couldn't delete " .
      $self->{adjacency_matrix_file} . ": $!\n";
  }

  if (defined $self->{path_length_matrix}) {
    untie %{$self->{path_length_matrix}};
  }
  if (defined $self->{path_length_matrix_filename}) {
    unlink $self->{path_length_matrix_filename} or die "Couldn't delete " .
      $self->{path_length_matrix_filename} . ": $!\n";
  }

}

sub new_hyperlink_network {
        my $class = shift;
        my $self = new($class);

        my $filename = shift;

        my %parameters = @_;

        my $property = ( defined $parameters{property} ?
                         $parameters{propery} : 'pagerank_transition' );

        my $ignore_EX = ( defined $parameters{ignore_EX} ?
                          $parameters{ignore_EX} : 1 );

        my $load_orig_files = 0;
        my %docid_to_file = ();

        if (defined $parameters{docid_to_file_dbm})  {
                my $docid_to_file_dbm_file = $parameters{docid_to_file_dbm};
    dbmopen %docid_to_file, $docid_to_file_dbm_file, 0666
    or die "Couldn't open db '$docid_to_file_dbm_file': $!\n";
                $load_orig_files = 1;
        }

        open HYPERLINKS, "< $filename" or die "Cannot open file: $filename";

        my %id_hash = ();

        while (<HYPERLINKS>) {
                next unless m/(.+) (.+)/;

                my $u_id = $1;
                my $v_id = $2;

                next if ($ignore_EX and (($u_id eq "EX") or ($v_id eq "EX")) );

                my $u = $u_id;
                my $v = $v_id;

                if ($load_orig_files == 1) {
                        foreach my $id (($u_id, $v_id)) {
                                if (not exists $id_hash{$id}) {
                                        if ($id eq "EX") {
                                                $id_hash{$id} = $id;
                                        } else {
                                                my $filename = $docid_to_file{"$id"};
                                                my $doc = Clair::Document->new(file => "$filename", id => "$id",
                                                                               type => 'html');
                                                $id_hash{$id} = $doc;
                                        }
                                }
                        }

                        $u = $id_hash{$u_id};
                        $v = $id_hash{$v_id};
                }

                if (not $self->has_node($u)) {
                        $self->add_node($u);
                }

                if ($u ne $v) {
                        if (not $self->has_node($v)) {
                                $self->add_node($v);
                        }

                        $self->add_edge($u, $v);
                        $self->set_edge_attribute($u, $v, $property, 1);
                } else {
                        $self->set_vertex_attribute($u, $property, 1);
                }
        }

        return $self;
}

sub read_transition_probabilities_from_file {
        my $self = shift;
        my $filename = shift;

        $self->read_matrix_property_from_file($filename, 'transition_prob');
}


sub read_pagerank_probabilities_from_file {
        my $self = shift;
        my $filename = shift;

        $self->read_matrix_property_from_file($filename, 'pagerank_transition');
}

sub read_matrix_property_from_file {
        my $self = shift;
        my $graph = $self->{graph};

        my $filename = shift;

        my $property = shift;

        open IN, "< $filename" or die "Unable to read: $filename\n";
        while (<IN>) {
                chomp;
                my @params = split(/ /);
                next if (scalar @params != 3);

                my $u = shift(@params);
                my $v = shift(@params);
                my $tp = shift (@params);

                if ($u ne $v) {
                        $graph->set_edge_attribute($u, $v, $property, $tp);
                } else {
                        $graph->set_vertex_attribute($u, $property, $tp);
                }
        }

        close IN;
}

sub create_subset_network_from_file {
        my $self = shift;
        my $filename = shift;

        my @vertex_list = ();

        open(IN, "< $filename");

        while (<IN>) {
                chomp;
                push(@vertex_list, $_);
        }

        return $self->create_subset_network(\@vertex_list);
}

sub create_subset_network {
        my $self = shift;
        my $graph = $self->{graph};
        my $sub_vertices_ref = shift;
        my @sub_vertices = @$sub_vertices_ref;

        my $new_network = new Clair::Network(directed => $self->{directed});
        my $new_graph = $new_network->{graph};

        #       Add the vertices
        foreach my $v (@sub_vertices) {
                $new_network->add_node($v);
                my $attr = $graph->get_vertex_attributes($v);
                $new_graph->set_vertex_attributes($v, $attr);
        }

        #       Add the edges
        foreach my $u ($new_graph->vertices) {
                foreach my $v ($new_graph->vertices) {
                        if ($graph->has_edge($u, $v)) {
                                $new_graph->add_edge($u, $v);
                                my $attr = $graph->get_edge_attributes($u, $v);
                                $new_graph->set_edge_attributes($u, $v, $attr);
                                if ($graph->has_edge_weight($u, $v)) {
                                  my $w = $graph->get_edge_weight($u, $v);
                                  $new_graph->set_edge_weight($u, $v, $w);
                                }

                        }
                }
        }

        return $new_network;
}


sub create_network_from_lexrank {
        my $self = shift;
        my $graph = $self->{graph};
        my $threshold = shift;

        my $new_network = new Clair::Network();
        my $new_graph = $new_network->{graph};

        #       Add the vertices
        foreach my $v ($graph->vertices) {
                if ($graph->has_vertex_attribute($v, 'lexrank_value')
                    and $graph->get_vertex_attribute($v, 'lexrank_value') >= $threshold) {
                        $new_network->add_node($v);
                        my $attr = $graph->get_vertex_attributes($v);
                        $new_graph->set_vertex_attributes($v, $attr);
                }
        }

        #       Add the edges
        foreach my $u ($new_graph->vertices) {
                foreach my $v ($new_graph->vertices) {
                        if ($graph->has_edge($u, $v)) {
                                $new_graph->add_edge($u, $v);
                                my $attr = $graph->get_edge_attributes($u, $v);
                                $new_graph->set_edge_attributes($u, $v, $attr);
                        }
                }
        }

        return $new_network;
}

sub create_cluster_from_lexrank {
        my $self = shift;
        my $graph = $self->{graph};
        my $threshold = shift;
        my %parameters = @_;

        my $attribute_name = "document";
        if (exists $parameters{attribute_name}) {
                $attribute_name = $parameters{attribute_name};
        }

        my $parent_document = 0;
        if (exists $parameters{parent_document} and $parameters{parent_document} == 1) {
                $parent_document = 1;
        }

        my $new_cluster = Clair::Cluster->new();
        my $count = 0;



        foreach my $v ($graph->vertices) {
                if ($graph->has_vertex_attribute($v, 'lexrank_value')
                    and $graph->get_vertex_attribute($v, 'lexrank_value') >= $threshold) {
                        ++$count;

                        # Find the document we are going to add by getting it from the attributes of the node
                        if (not $graph->has_vertex_attribute($v, $attribute_name) ) {
                                print "Node does not have attribute: ", $attribute_name, "\n";
                        }
                        my $doc = $graph->get_vertex_attribute($v, $attribute_name);

                        # If parent_document is 1, then we want the parent of the document at that node to be
                        # inserted into the cluster, not the document itself
                        if ($parent_document == 1) {
                                $doc = $doc->get_parent_document();
                        }

                        $new_cluster->insert($doc->get_id, $doc);
                }
        }

        return $new_cluster;
}

sub save_transition_probabilities_to_file {
        my $self = shift;
        my $filename = shift;

        $self->save_matrix_property_to_file($filename, 'transition_prob');
}

sub save_pagerank_probabilities_to_file {
        my $self = shift;
        my $filename = shift;

        $self->save_matrix_property_to_file($filename, 'pagerank_transition');
}

sub save_matrix_property_to_file {
        my $self = shift;
        my $graph = $self->{graph};

        my $filename = shift;

        my $property = shift;

        open OUT, "> $filename" or die "Unable to write to: $filename\n";
        foreach $e ($graph->edges) {
                my ($u, $v) = @$e;
                if ($graph->has_edge_attribute($u, $v, $property)) {
                        my $tp = $graph->get_edge_attribute($u, $v, $property);

                        print OUT "$u $v $tp\n";
                }
        }

        foreach my $u ($graph->vertices) {
                if ($graph->has_vertex_attribute($u, $property)) {
                        my $tp = $graph->get_vertex_attribute($u, $property);

                        print OUT "$u $u $tp\n";
                }
        }

        close OUT;
}

sub print_hyperlink_edges {
        my $self = shift;
        my $filename = shift;

        $self->print_edges_with_property('pagerank_transition');
}

sub print_edges_with_property {
        my $self = shift;
        my $graph = $self->{graph};

        my $property = shift;

        foreach $e ($graph->edges) {
                my ($u, $v) = @$e;
                if ( ($graph->has_edge_attribute($u, $v, $property)) and
                        ($graph->get_edge_attribute($u, $v, $property) != 0) ) {

                        print "$u $v\n";
                }
        }

        foreach my $u ($graph->vertices) {
                if ( ($graph->has_vertex_attribute($u, $property)) and
                        ($graph->get_vertex_attribute($u, $property) != 0) ) {

                        print "$u $u\n";
                }
        }
}


sub save_hyperlink_edges_to_file {
        my $self = shift;
        my $filename = shift;

        $self->save_edges_with_property_to_file($filename, 'pagerank_transition');
}

sub save_edges_with_property_to_file {
        my $self = shift;
        my $graph = $self->{graph};

        my $filename = shift;

        my $property = shift;

        open OUT, "> $filename" or die "Unable to write to: $filename\n";
        foreach $e ($graph->edges) {
                my ($u, $v) = @$e;
                if ( ($graph->has_edge_attribute($u, $v, $property)) and
                        ($graph->get_edge_attribute($u, $v, $property) != 0) ) {

                        print OUT "$u $v\n";
                }
        }

        foreach my $u ($graph->vertices) {
                if ( ($graph->has_vertex_attribute($u, $property)) and
                        ($graph->get_vertex_attribute($u, $property) != 0) ) {

                        print OUT "$u $u\n";
                }
        }

        close OUT;
}


sub read_initial_probability_distribution {
        my $self = shift;
        my $filename = shift;

        $self->read_property_from_file($filename, 'current_prob');
}


sub read_pagerank_initial_distribution {
        my $self = shift;
        my $filename = shift;

        $self->read_property_from_file($filename, 'pagerank_value');
}


sub read_pagerank_personalization {
        my $self = shift;
        my $filename = shift;

        $self->read_property_from_file($filename, 'pagerank_personalization');
}


sub read_property_from_file {
        my $self = shift;
        my $graph = $self->{graph};

        my $filename = shift;

        my $property = shift;

        open IN, "< $filename" or die "Unable to open: $filename\n";
        while (<IN>) {
                chomp;
                @params = split(/ /);
                next if (scalar @params != 2);

                my $v = shift(@params);
                my $ip = shift(@params);

                $graph->set_vertex_attribute($v, $property, $ip);
        }

        close IN;
}


sub print_current_probability_distribution {
        my $self = shift;
        $self->print_property_distribution('current_prob');
}


sub print_current_pagerank_distribution {
        my $self = shift;
        $self->print_property_distribution('pagerank_value');
}


sub print_current_lexrank_distribution {
        my $self = shift;
        $self->print_property_distribution('lexrank_value');
}

sub print_property_distribution {
        my $self = shift;
        my $graph = $self->{graph};

        my $property = shift;

        foreach my $v ($graph->vertices) {
                if ($graph->has_vertex_attribute($v, $property)) {
                        my $vp = $graph->get_vertex_attribute($v, $property);
                        print "$v $vp\n";
                }
        }
}

sub save_current_probability_distribution {
        my $self = shift;
        my $filename = shift;

        return $self->save_property_distribution($filename, 'current_prob');
}

sub save_current_pagerank_distribution {
        my $self = shift;
        my $filename = shift;

        return $self->save_property_distribution($filename, 'pagerank_value');
}

sub save_property_distribution {
        my $self = shift;
        my $graph = $self->{graph};

        my $filename = shift;

        my $property = shift;

        open OUT, "> $filename" or die "Unable to write to: $filename\n";

        foreach my $v ($graph->vertices) {
                if ($graph->has_vertex_attribute($v, $property)) {
                        my $vp = $graph->get_vertex_attribute($v, $property);
                        print OUT "$v $vp\n";
                }
        }

        close OUT;
}


sub get_current_probability_distribution {
        my $self = shift;
        return $self->get_property_hash('current_prob');
}

sub get_property_hash {
        my $self = shift;
        my $graph = $self->{graph};
        my $property = shift;

        my %ret_hash = ();

        foreach my $v ($graph->vertices) {
                if ($graph->has_vertex_attribute($v, $property)) {
                        $ret_hash{$v} = $graph->get_vertex_attribute($v, $property);
                } else {
                        $ret_hash{$v} = 0;
                }
        }

        return %ret_hash;
}

sub get_current_probability_matrix {
        my $self = shift;
        my $verts_ref = shift;
        return $self->get_property_vector($verts_ref, 'current_prob');
}

sub get_property_vector {
        my $self = shift;
        my $graph = $self->{graph};

        my $verts = shift;
        my @vertices = @$verts;

        my $property = shift;

        my $matrix = new Math::MatrixReal(scalar @vertices, 1);

        # Assign the probability for each vertex (0 is default, so anything
        # that doesn't have a current_prob can be left as 0.
        my $row = 1;
        foreach $v (@vertices) {
                if ($graph->has_vertex_attribute($v, $property)) {
                        $matrix->assign($row, 1, $graph->get_vertex_attribute($v, $property));
                }
                ++$row;
        }

        return $matrix;
}


sub set_current_probability_matrix {
        my $self = shift;
        my $verts_ref = shift;
        my $matrix = shift;

        $self->set_property_matrix($verts_ref, $matrix, 'current_prob');
}

sub set_property_matrix {
        my $self = shift;
        my $graph = $self->{graph};

        my $verts = shift;
        my @vertices = @$verts;

        my $matrix = shift;

        my $property = shift;

        # Assign the probability for each vertex (0 is default, so anything
        # that doesn't have a current_prob can be left as 0.
        my $row = 1;
        foreach $v (@vertices) {
                $graph->set_vertex_attribute($v, $property, $matrix->element($row, 1));
                ++$row;
        }
}



sub get_transition_probability_matrix {
        my $self = shift;
        my $verts_ref = shift;

        return $self->get_property_matrix($verts_ref, 'transition_prob');
}

sub get_property_matrix {
        my $self = shift;
        my $graph = $self->{graph};

        my $verts = shift;
        my @vertices = @$verts;

        my $property = shift;

        my $matrix = new Math::MatrixReal(scalar @vertices, scalar @vertices);

        # Assign the transition probability for each edge (0 is default
        # so any edge that doesn't exist or doesn't have a probability
        # can be left at 0)
        my $col = 1;
        foreach my $u (@vertices) {
                my $row = 1;
                foreach my $v (@vertices) {
                        if ($u ne $v) {
                                if ($graph->has_edge($u, $v) and
                                    $graph->has_edge_attribute($u, $v, $property) ) {
                                        $matrix->assign($row, $col, $graph->get_edge_attribute($u, $v, $property));
                                }
                        } else {
                                if ($graph->has_vertex_attribute($u, $property) ) {
                                        $matrix->assign($row, $col, $graph->get_vertex_attribute($u, $property));
                                }
                        }

                        ++$row;
                }
                ++$col;
        }

        return $matrix;
}


sub set_transition_probability_from_matrix {
        my $self = shift;
        my $verts_ref = shift;
        my $matrix = shift;

        $self->set_properties_from_matrix($verts_ref, $matrix, 'transition_prob');
}

sub set_properties_from_matrix {
        my $self = shift;
        my $graph = $self->{graph};

        my $verts = shift;
        my @vertices = @$verts;

        my $matrix = shift;

        my $property = shift;

        for (my $i = 1; $i <= scalar @vertices; $i++) {
                for (my $j = 1; $j <= scalar @vertices; $j++) {
                        if ($i == $j) {
                                # Vertices are the same
                                my $u = $vertices[$i - 1];

                                if ($matrix->element($j, $i) != 0 or $graph->has_vertex_attribute($u, $property)) {
                                        # Set the attribute if it's not zero or if it already existed
                                        # (Don't create it just to put zero)
                                        $graph->set_vertex_attribute($u, $property, $matrix->element($j, $i));
                                }
                        } else {
                                # Vertices are different
                                my $u = $vertices[$i - 1];
                                my $v = $vertices[$j - 1];

                                if ($matrix->element($j, $i) != 0 or
                                   ($graph->has_edge($u, $v) and $graph->has_edge_attribute($u, $v, $property)) ) {
                                        # Set the attribute if the values not zero or if it already existed
                                        # (to make sure it gets zeroed out)
                                        # Edge will be created if it does not already exist
                                        $graph->set_edge_attribute($u, $v, $property, $matrix->element($j, $i));
                                }
                        }
                }
        }
}

sub create_uniform_vector {
        my $self = shift;
        my $num_rows = shift;

        if ($num_rows == 0) {
                die "Must have a positive number of rows.";
        }

        my $value = 1 / $num_rows;

        my $matrix = new Math::MatrixReal($num_rows, 1);

        for (my $i = 1; $i <= $num_rows; ++$i) {
                $matrix->assign($i, 1, $value);
        }

        return $matrix;
}


sub make_transitions_stochastic {
        my $self = shift;
        my $graph = $self->{graph};

        my @vertices = $graph->vertices;

        my $matrix = $self->get_transition_probability_matrix(\@vertices);

        $self->make_matrix_stochastic($matrix);

        $self->set_transition_probability_from_matrix(\@vertices, $matrix);
}

sub make_matrix_stochastic {
        my $self = shift;
        my $matrix = shift;

        my ($num_rows, $num_cols) = $matrix->dim();

        for (my $i = 1; $i <= $num_cols; ++$i) {
                my $sum = 0;
                for (my $j = 1; $j <= $num_rows; ++$j) {
                        # Make sure that no values are negative
                        if ($matrix->element($j, $i) < 0) {
                                $matrix->assign($j, $i, 0);
                        }

                        $sum += $matrix->element($j, $i);
                }

                if ($sum != 0) {
                        for (my $j = 1; $j <= $num_rows; ++$j) {
                                $matrix->assign($j, $i, $matrix->element($j, $i) / $sum);
                        }
                } else {
                        for (my $j = 1; $j <= $num_rows; ++$j) {
                                $matrix->assign($j, $i, 1 / $num_rows);
                        }
                }
        }

        return $matrix;
}


sub perform_next_random_walk_step {
        my $self = shift;
        my $graph = $self->{graph};

        my @vertices = $graph->vertices;

        # Get the current probability matrix
        # We pass the list of vertices along to guarantee that they go through
        # the vertices in the same order (the same ordering is not guaranteed
        # by graph->vertices, although it is probably the case)
        my $cur_prob = $self->get_current_probability_matrix(\@vertices);
        my $trans_matrix = $self->get_transition_probability_matrix(\@vertices);

        my $new_prob = $self->compute_random_walk_step($cur_prob, $trans_matrix);

        $self->set_current_probability_matrix(\@vertices, $new_prob);

        return $self->get_current_probability_distribution();
}


sub compute_random_walk_step {
        my $self = shift;
        my $graph = $self->{graph};

        my $cur_prob = shift;
        my $trans_matrix = shift;

        my $result = $trans_matrix->multiply($cur_prob);

        return $result;
}


sub perform_next_rank_step {
        my $self = shift;
        my $graph = $self->{graph};
        my $property = shift;

        my @vertices = $graph->vertices;

        my $cur_value = $self->get_property_vector(\@vertices, $property);
        my $matrix = $self->get_property_matrix(\@vertices, $property);

        my $new_value = $self->compute_rank_step($matrix, $c, $v, $cur_value);

        $self->set_property_matrix(\@vertices, $new_value, $property);

        return $self->get_property_hash($property);
}


sub compute_rank_step {
        my $self = shift;

        my $P = shift;
        my $c = shift;
        my $v = shift;
        my $x = shift;

        my $result = $P->multiply($x);
        $result->multiply_scalar($result, $c);

        my $d = $x->norm_one() - $result->norm_one();
        my $temp_v = $v->clone();
        $temp_v->multiply_scalar($temp_v, $d);

        $result->add($result, $temp_v);

        return $result;
}


sub compute_stationary_distribution {
        my $self = shift;
        my $graph = $self->{graph};

        my @vertices = $graph->vertices;

        my $max_iterations = 200;
        my $tolerance = 0.001;

        # Get the current probability matrix
        # We pass the list of vertices along to guarantee that they go through
        # the vertices in the same order (the same ordering is not guaranteed
        # by graph->vertices, although it is probably the case)
        my $cur_prob = $self->get_current_probability_matrix(\@vertices);
        my $trans_matrix = $self->get_transition_probability_matrix(\@vertices);

        my $last_prob = $cur_prob->clone();
        my $new_prob;
        for (my $i = 0; $i < $max_iterations; ++$i) {
                $new_prob = $self->compute_random_walk_step($cur_prob, $trans_matrix);

                if ($self->is_vector_change_within_tolerance($cur_prob, $new_prob, $tolerance) == 1) {
                        last;
                }

                $cur_prob = $new_prob;
        }

        $self->set_current_probability_matrix(\@vertices, $new_prob);

        return $self->get_current_probability_distribution();
}

sub compute_rank_result {
        my $self = shift;
        my $graph = $self->{graph};
        my @vertices = $graph->vertices;

        my $value_property = shift;
        my $matrix_property = shift;

        my $jump = shift;
        if ($jump == 0) {
                $jump = .15;
        }
        if ($jump < 0 or $jump > 1) {
                die "Jump must be greater than 0 and less than 1.\n";
        }
        my $c = 1 - $jump;

        my $v_property = shift;

        my %params = @_;

        my $max_iterations = 200;
        if (exists $params{max_iterations} and $params{max_iterations} ne 0) {
                $max_iterations = $params{max_iterations};
        }


        my $tolerance = 0.001;
        if (exists $params{tolerance} and $params{tolerance} ne 0) {
                $tolerance = $params{tolerance};
        }

        my $cur_value;
        if ($value_property eq 0) {
                $cur_value = $self->create_uniform_vector(scalar @vertices);
        } else {
                $cur_value = $self->get_property_vector(\@vertices, $value_property);

                # If all values are zero
                if ($cur_value->norm_one() == 0) {
                        $cur_value = $self->create_uniform_vector(scalar @vertices);
                }
        }

        my $rank_matrix = $self->get_property_matrix(\@vertices, $matrix_property);
        $self->make_matrix_stochastic($rank_matrix);

        my $v_matrix;
        if ($v_property eq 0) {
                $v_matrix = $self->create_uniform_vector(scalar @vertices);
        } else {
                $v_matrix = $self->get_property_vector(\@vertices, $v_property);

                # If all values are zero use a uniform matrix
                if ($v_matrix->norm_one() == 0) {
                        $v_matrix = $self->create_uniform_vector(scalar @vertices);
                }
        }
        $self->make_matrix_stochastic($v_matrix);

        my $last_value = $cur_value->clone();
        my $new_value;

        for (my $i = 0; $i < $max_iterations; ++$i) {
                $new_value = $self->compute_rank_step($rank_matrix, $c, $v_matrix, $cur_value);

                if ($self->is_vector_change_within_tolerance($cur_value, $new_value, $tolerance) == 1) {
                        last;
                }

                $cur_value = $new_value;
        }

        $self->set_property_matrix(\@vertices, $new_value, $value_property);

        return $self->get_property_hash($value_property);
}

sub compute_pagerank  {
        my $self = shift;
        my %params = @_;

        my $pagerank_value = 'pagerank_value';
        if (exists $params{pagerank_value}) {
                $pagerank_value = $params{pagerank_value};
        }

        my $pagerank_transition = 'pagerank_transition';
        if (exists $params{pagerank_transition}) {
                $pagerank_transition = $params{pagerank_transition};
        }

        my $pagerank_bias = 'pagerank_bias';
        if (exists $param{pagerank_bias}) {
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

        return $self->compute_rank_result($pagerank_value, $pagerank_transition, $jump,
                                          $pagerank_bias, tolerance => $tolerance,
                                                                                                                                                max_iterations => $max_iterations);
}


sub is_vector_change_within_tolerance {
        my $self = shift;
        my $cur_prob = shift;
        my $new_prob = shift;
        my $tolerance = shift;

        # Create a new matrix that holds the differences in probabilities
        my ($row, $col) = $cur_prob->dim();
        my $diff = new Math::MatrixReal($row, $col);
        $diff->subtract($cur_prob, $new_prob);

        # Find the largest absolute value of the differences
        my $max = $diff->norm_max();

        # If that value is less than or equal to the tolerance,
        # then return 1, otherwise return 0
        if ($max <= $tolerance) {
                return 1;
        } else {
                return 0;
        }
}


sub add_node {
        my $self = shift;

        my $node = shift;
        my @remaining_args = @_;

        # my $text = shift;

        my %parameters = @_;

        my $graph = $self->{graph};

        $graph->add_vertex($node);

        foreach $key (keys %parameters) {
                $graph->set_vertex_attribute($node, $key, $parameters{$key});
        }
        $self->clear_cache();
}

sub has_node {
        my $self = shift;
        my $graph = $self->{graph};

        my $node = shift;

        return $graph->has_vertex($node);
}

sub has_edge {
        my $self = shift;
        my $graph = $self->{graph};

        my $u = shift;
        my $v = shift;

        return $graph->has_edge($u, $v);
}

#sub add_node {
#       my $self = shift;
#       my $node = shift;
#
#       my $graph = $self->{graph};
#
#       $graph->add_vertex($node);
#}


sub remove_node {
        my $self = shift;
        my $id = shift;

        my $graph = $self->{graph};

        $graph->delete_vertex($id);
        $self->clear_cache();
}

sub add_edge {
        my $self = shift;

        my $u = shift;
        my $v = shift;

        my $graph = $self->{graph};

        $graph->add_edge($u, $v);
        $self->clear_cache();
}

=head2 add_weighted_edge

add_weighted_edge($id1, $id2, $w);

Creates an edge between the two vertices specified.  If a vertex is
not already part of the graph, it is automatically added.

=cut

sub add_weighted_edge {
  my $self = shift;

  my $u = shift;
  my $v = shift;
  my $w = shift;

  my $graph = $self->{graph};

  $graph->add_weighted_edge($u, $v, $w);
  $self->clear_cache();
}

sub remove_edge {
        my $self = shift;
        my $u = shift;
        my $v = shift;

        my $graph = $self->{graph};

        $graph->delete_edge($u, $v);
        $self->clear_cache();
}


sub set_node_weight {
        my $self = shift;
        my $id = shift;
        my $weight = shift;

        my $graph = $self->{graph};

        $graph->set_vertex_weight($id, $weight);
}

sub get_node_weight {
        my $self = shift;
        my $id = shift;

        my $graph = $self->{graph};

        my $weight = $graph->get_vertex_weight($id);

        return $weight;
}

sub set_edge_weight {
        my $self = shift;
        my $u = shift;
        my $v = shift;

        my $graph = $self->{graph};

        my $weight = shift;

        $graph->set_edge_weight($u, $v, $weight);
}

sub set_edge_attribute {
        my $self = shift;
        my $u = shift;
        my $v = shift;

        my $graph = $self->{graph};

        my $property = shift;
        my $value = shift;

        $graph->set_edge_attribute($u, $v, $property, $value);
}

sub get_edge_attribute {
        my $self = shift;
        my $u = shift;
        my $v = shift;
        my $graph = $self->{graph};
        my $property = shift;

        return $graph->get_edge_attribute($u, $v, $property);
}

sub has_edge_attribute {
        my $self = shift;
        my $u = shift;
        my $v = shift;
        my $graph = $self->{graph};
        my $property = shift;

        return $graph->has_edge_attribute($u, $v, $property);
}

sub set_vertex_attribute {
        my $self = shift;
        my $u = shift;
        my $graph = $self->{graph};
        my $property = shift;
        my $value = shift;

        $graph->set_vertex_attribute($u, $property, $value);
}

sub get_vertex_attribute {
        my $self = shift;
        my $u = shift;
        my $graph = $self->{graph};
        my $property = shift;

        return $graph->get_vertex_attribute($u, $property);
}

sub has_vertex_attribute {
        my $self = shift;
        my $u = shift;
        my $graph = $self->{graph};
        my $property = shift;

        return $graph->has_vertex_attribute($u, $property);
}

sub get_edge_weight {
        my $self = shift;
        my $u = shift;
        my $v = shift;

        my $graph = $self->{graph};

        my $weight = 0;

        if ($graph->has_edge_weight($u, $v)) {
                $weight = $graph->get_edge_weight($u, $v);
        }

        return $weight;
}

sub get_edges {
        my $self = shift;
        my $graph = $self->{graph};

        return $graph->edges;
}

sub get_vertices {
        my $self = shift;
        my $graph = $self->{graph};

        return $graph->vertices;
}

sub find_path {
        my $self = shift;

        my $s = shift;
        my $t = shift;

        my $graph = $self->{graph};

        my $apsp = $graph->APSP_Floyd_Warshall;

        my @path = $apsp->path_vertices($s, $t);

        return @path;
}

sub compute_cohesion {
        my $self = shift;
        my %parameters = @_;

        my $text_of = $self->{text_of};

        my %cosine_of;

        my $graph = $self->{graph};

        foreach $u ($graph->vertices) {
                my %cosines_of_u;

                foreach $v ($graph->vertices) {
                        if ($u < $v) {
                                my $text_of_u = $text_of->{$u};
                                my $text_of_v = $text_of->{$v};

                                my $cosine = GetLexSim($text_of_u, $text_of_v);
                                print "$u $v, $cosine\n";
                                $cosines_of_u{$v} = $cosine;
                        }
                }

                if (scalar(keys(%u_cosine_of)) > 0) {
                        $cosine_of{$u} = \%cosines_of_u;
                }
        }

        return %cosine_of;
}

sub export_to_Pajek {
  my $self = shift;

  my $graph = $self->{graph};
  my $networkName = shift;
  my $filename = shift;

  printf STDERR "export_to_Pajek is deprecated, please use ";
  printf STDERR "Clair::Network::Writer::Pajek\n";

  my $export = Clair::Network::Writer::Pajek->new();
  $export->set_name($networkName);
  $export->write_network($self, $filename);
}

sub num_nodes
{
        my $self = shift;

        my $graph = $self->{graph};
        my $num_nodes = $graph->vertices;

        return $num_nodes;
}

sub num_documents
{
        my $self = shift;

        my $graph = $self->{graph};
        my $num_docs = $graph->vertices;

        return $num_docs;
}

sub num_pairs
{
        my $self = shift;

        my $num_docs = $self->num_documents;
        my $num_pairs = $num_docs*($num_docs-1)/2;

        return $num_pairs;
}

sub num_links
{
        my $self = shift;

        my $graph = $self->{graph};
        my @links = $graph->edges;
        my $num_links = 0;

        my %parameters = @_;
        my $internal = 1;
        my $unique = 0;

        if ( (exists $parameters{internal} && $parameters{internal} == 0) ||
             (exists $parameters{external} && $parameters{external} == 1) ) {
                $internal = 0;
        }

        if (exists $parameters{unique} && $parameters{unique} == 1)
        {
                $unique = 1;
        }

        my %seen_links = ();

        foreach $l (@links) {
                my $u;
                my $v;

                ($u, $v) = @$l;

                if ($unique == 0 || not exists $seen_links{"$u,$v"}) {
                        if ($u =~ 'EX' or $v =~ 'EX') {
                                if ($internal == 0) {
                                        $num_links++;
                                }
                        } else {
                                if ($internal == 1) {
                                        $num_links++;
                                }
                        }
                }
        }

        return $num_links;
}

sub compute_in_link_histogram
{
        my $self = shift;
        my $graph = $self->{graph};

        my %histogram = ();

        foreach my $v ($graph->vertices)
        {
                my $num_in = $graph->predecessors($v);
                if (not exists $histogram{$num_in} )
                {
                        $histogram{$num_in} = 1;
                } else {
                        $histogram{$num_in}++;
                }
        }

        return %histogram;
}

sub avg_in_degree
{
        my $self = shift;
        my %histogram = $self->compute_in_link_histogram();

        my $total_in = 0;
        my $num_nodes = scalar $self->get_vertices();
        foreach my $value (keys %histogram)
        {
                #skip nodes that have no links
                next if $value == 0;

                my $num = $histogram{$value};

                $total_in += $value * $num;
        }

        return $total_in/$num_nodes;
}

sub compute_out_link_histogram
{
        my $self = shift;
        my $graph = $self->{graph};

        my %histogram = ();

        foreach my $v ($graph->vertices)
        {
                my $num_out = $graph->successors($v);
                if (not exists $histogram{$num_out})
                {
                        $histogram{$num_out} = 1;
                } else {
                        $histogram{$num_out}++;
                }
        }

        return %histogram;
}

sub avg_out_degree
{
        my $self = shift;
        my %histogram = $self->compute_out_link_histogram();

        my $total_out = 0;
        my $num_nodes = scalar $self->get_vertices();
        foreach my $value (keys %histogram)
        {
                #skip nodes that have no links
                next if $value == 0;

                my $num = $histogram{$value};
                $total_out += $value * $num;
        }
        return $total_out/$num_nodes;
}

sub compute_total_link_histogram
{
        my $self = shift;
        my $graph = $self->{graph};

        my %histogram = ();

        foreach my $v ($graph->vertices) {
          my $num_total = 0;
          if ($self->{directed}) {
            $num_total = $self->total_degree($v)
          } else {
            $num_total = $graph->degree($v);
          }

          if (not exists $histogram{$num_total}) {
            $histogram{$num_total} = 1;
          } else {
            $histogram{$num_total}++;
          }
        }

        return %histogram;
}

sub avg_total_degree
{
        my $self = shift;
        my %histogram = $self->compute_total_link_histogram();

        if (!$self->{directed}) {
          return $self->{graph}->average_degree();
        }
        my $total = 0;
        my $num_nodes = 0;
        foreach my $value (keys %histogram)
        {
                #skip nodes that have no links
                next if $value == 0;

                my $num = $histogram{$value};
                $total += $value * $num;
                $num_nodes += $num;
        }
        my $deg = 0;
        if ($self->{directed}) {
          $deg = $total / $num_nodes;
        } else {
          $deg = ($total / $num_nodes) / 2;
        }
        return $deg;
}

# Copied and slightly modified from power_law_exponent.pl
sub power_law_exponent
{
        my $self = shift;
        my $hist = shift;
        my %histogram = %$hist;

  # This will compute the power law coefficient of a set of data
  # this uses linear regression on the logs of the data points to
  # find both the coefficient and the exponent.

        my %points;

        # x_total is the sum of all x's
        my $x_total=0;
        # y_total is likewise: \sum_i y_i
        my $y_total=0;
        # number of data points.
        my $num_points=0;

        foreach my $value (keys %histogram)
        {
                my $num = $histogram{$value};
                # Don't take the log of 0
                if ($value == 0 || $num == 0)
                {
                        next;
                }

                # print "$num pages have $value links.\n";
                my $one = log($num);
                my $two = log($value);

                $points{$two}=$one;
                $x_total+=$two;
                $y_total+=$one;
                $num_points++;
        }

        my $x_average=$x_total/$num_points;
        my $y_average=$y_total/$num_points;

        # \sum_i x_i y_i
        my $sum_x_and_y=0;
        # \sum_i {x_i}^2
        my $sum_x_squared=0;
        my $sum_x=0;
        my $sum_y=0;
                my $sum_y_squared = 0;

        foreach (keys %points)
        {
          $sum_x_and_y+=($_)*($points{$_});
                $sum_x_squared+=($_)**2;
                $sum_x+=$_;
                $sum_y+=$points{$_};
                                $sum_y_squared += ($points{$_})**2;
        }

        # here's where the formula for linear regression comes in (check your
        # stats book if you forgot)

        # This check added by Mark Hodges May 10, 2006 to prevent
        # a divide by zero
        my $denom = $num_points*$sum_x_squared - $sum_x**2;
        if ($denom == 0)
        {
                return "Unable to compute power law (div by 0)";
        }

        my $m=( $num_points*$sum_x_and_y - $sum_x*$sum_y ) /
              ( $num_points*$sum_x_squared - $sum_x**2 );

        my $b=$y_average-$m*$x_average;
                my $r = $sum_x_and_y/(sqrt($sum_x_squared*$sum_y_squared));

        #  Since $b is actually (log C) in log y = log C + a log x,
        #  with y = Ce^(ax), we get

        my $C=exp($b);


        my $a = $m;

        my $retVal = "y = $C x^$a\t$r";
        return $retVal;
}


sub newman_power_law_exponent
{
  my $self = shift;
  my $h = shift;
  my $x_min = shift;
  my %hist = %$h;

  if ($x_min < 1) {
    $x_min = 1;
  }

  my $n = 0;
  my $sum = 0;

  foreach my $x (keys %hist) {
    if ($x > 0) {
      if ($x >= $x_min) {
        $n += $hist{$x};
        $sum += ($hist{$x} * log($x / $x_min));
      }
    }
  }

  if ($sum == 0) {
    return 0;
  }

  my $alpha = 1 + ($n * (1 / $sum));
  my $sigma = ($alpha - 1) / sqrt($sum);

  return ($alpha, $sigma);
}


sub power_law_out_link_distribution
{
        my $self = shift;
        my %histogram = $self->compute_out_link_histogram();

        my $exponent = $self->power_law_exponent(\%histogram);

        return $exponent;
}

sub power_law_in_link_distribution
{
        my $self = shift;
        my %histogram = $self->compute_in_link_histogram();

        my $exponent = $self->power_law_exponent(\%histogram);

        return $exponent;
}

sub power_law_total_link_distribution
{
        my $self = shift;
        my %histogram = $self->compute_total_link_histogram();

        my $exponent = $self->power_law_exponent(\%histogram);

        return $exponent;
}

sub diameter
{
  my $self = shift;
  my $graph = $self->{graph};

  my %parameters = @_;

  my $directed = $self->{directed};
  if ( (exists $parameters{directed} and $parameters{directed} == 0) ||
       (exists $parameters{undirected} and $parameters{undirected} == 1) ) {
    $directed = 0;
  }

  my $max = 1;
  if ( (exists $parameters{max} and $parameters{max} == 0) ||
       (exists $parameters{avg} and $parameters{avg} == 1) ) {
    $max = 0;
  }

  my $asp_matrix = $self->get_shortest_path_matrix(directed => $directed);

  if ($max) {
    my $top = 0;
    foreach my $v1 (keys %{$asp_matrix}) {
      foreach my $v2 (keys %{$asp_matrix->{$v1}}) {
        if ($asp_matrix->{$v1}{$v2} > $top) {
          $top = $asp_matrix->{$v1}{$v2};
        }
      }
    }
    return $top;
  } else {
    # average shortest path calculation
    my $cnt = 0.0;
    my $diameter = 0.0;
    foreach my $v1 (keys %{$asp_matrix}) {
      foreach my $v2 (keys %{$asp_matrix->{$v1}}) {
        my $length = $asp_matrix->{$v1}{$v2};
        if ($length > 0) {
          $cnt++;
          $diameter += $length;
        }
      }
    }
    if ($cnt != 0) {
    return $diameter / $cnt;
    } else {
            return 0;
    }
  }
}

#
# average shortest path
# Based partly on diameter code
#
sub average_shortest_path
{
  my $self = shift;
  my $graph = $self->{graph};

  my $directed = $self->{directed};

  my $asp_matrix = $self->get_shortest_path_matrix(directed => $directed);

  my %avg = ();
  my $total_cnt = 0;
  foreach my $v1 (keys %{$asp_matrix}) {
    my $sum = 0;
    my $cnt = 0;
    foreach my $v2 (keys %{$asp_matrix->{$v1}}) {
      my $len = $asp_matrix->{$v1}{$v2};
      if ($len >= 0) {
        $sum += $len;
        $cnt++;
      }
    }
    if ($cnt > 1) {
      $avg{$v1} = $sum / $cnt;
      $total_cnt++;
    }
  }

  my $sum = 0;
  foreach my $k (keys %avg) {
    $sum += $avg{$k};
  }

  if (int(scalar(keys %avg)) == 0) {
    return 0;
  } else {
    return $sum / int(scalar(keys %avg));
  }
}

#
# another way to calculate average shortest path, using harmonical mean
#

sub new_average_shorest_path {
  my $self = shift;
  my $graph = $self->{graph};

  my $directed = $self->{directed};

  # get the cached shortest path matrix
  my $asp_matrix = $self->get_shortest_path_matrix(directed => $directed);

  my $sum = 0;
  my @vertices = $self->get_vertices();
  my $n = scalar(@vertices);
  foreach my $n1 (0..($n - 1)) {
    $v1 = $vertices[$n1];
    foreach my $n2 (0..($n - 1)) {
      $v2 = $vertices[$n2];
      if (defined $asp_matrix->{$v1}{$v2}) {
        if ($asp_matrix->{$v1}{$v2} > 0) {
          $sum += 1 / $asp_matrix->{$v1}{$v2};
        }
      }
    }
  }
  if ($sum == 0) {
          return 0;
  } else {
          return 1/$sum;
  }
}
=head2 harmonic_mean_geodesic_distance

Compute the harmonic mean geodesic distance

=cut

sub harmonic_mean_geodesic_distance {
  my $self = shift;
  my $graph = $self->{graph};

  my $directed = $self->{directed};

  # get the cached shortest path matrix
  my $asp_matrix = $self->get_shortest_path_matrix(directed => $directed);

  my $sum = 0;
  my @vertices = $self->get_vertices();
  my $n = scalar(@vertices);
  foreach my $n1 (0..($n - 1)) {
    $v1 = $vertices[$n1];
    foreach my $n2 ($n1..($n - 1)) {
      $v2 = $vertices[$n2];
      if (defined $asp_matrix->{$v1}{$v2}) {
        if ($asp_matrix->{$v1}{$v2} > 0) {
          $sum += 1 / $asp_matrix->{$v1}{$v2};
        }
      }
    }
  }

  if (($n > 0) and ($sum > 0)) {
    my $mult = 1 / (($n * ($n - 1)) / 2);
    return 1 / ($mult * $sum);
  } else {
    return 0;
  }
}

sub write_links
{
  my $self = shift;
  my $filename = shift;

  printf STDERR "write_links is deprecated, please use ";
  printf STDERR "Clair::Network::Writer::Edgelist\n";

  my $export = Clair::Network::Writer::Edgelist->new();
  $export->write_network($self, $filename, @_);
}


sub write_nodes
{
        my $self = shift;
        my $graph = $self->{graph};

        my $filename = shift;

        open(FILE, "> $filename") or die "Could not open file: $filename\n";

        foreach my $v ($graph->vertices)
        {
                print(FILE "$v\n");
        }

        close(FILE);
}

sub Watts_Strogatz_clus_coeff
{
  my $self = shift;
  my $graph = $self->{graph};

  my %parameters = @_;

  my $write_to_file = 0;
  my $filename = "";
  if (exists $parameters{filename}) {
    $write_to_file = 1;
    $filename = $parameters{filename};
    open(WATT, "> $filename") or die("Could not open file: $filename\n");
  }

  my %link_hash;

  if ($write_to_file == 1) {
    print WATT "reading the input...\n";
  }

  %link_hash = $self->get_adjacency_matrix(undirected => 1);

  if ($write_to_file == 1) {
    print WATT "done!\n";
  }

  my $sum = 0;
  my $count = 0;
  my $skipped = 0;

  foreach my $v (keys %link_hash) {
    my $c = 0;
    my $connected = 0;
    my %nn;
    my @neighbors;

    if (exists $link_hash{$v}) {
      @neighbors = keys %{$link_hash{$v}};
      if (@neighbors > 1) {
        if (@neighbors > 5000) {
          $skipped++;
          next;
        }
        foreach my $n1 (0..$#neighbors) {
          foreach my $n2 ($n1+1..$#neighbors) {
            if (exists $link_hash{$neighbors[$n1]}{$neighbors[$n2]}) {
              $connected++;
            }
          }
        }
        $c = 2 * $connected / (@neighbors * (@neighbors-1));
      }
    }

    $count++;

    if ($write_to_file == 1) {
      print WATT "clustering coefficient for $v is $c\n";
    }

    $sum += $c;
  }

  if ($write_to_file == 1) {
    print WATT "\nnumber of nodes skipped (with degree > 5000): $skipped\n";
  }

  close WATT;

  if ($count == 0) {
    return 0;
  } else {
    return $sum/$count;
  }
}

=head2 Watts_Strogatz_local_clus_coeff

Get the local clustering coefficient for each vertex

This is only defined for vertices with > 2 edges

=cut

sub Watts_Strogatz_local_clus_coeff
{
  my $self = shift;
  my $graph = $self->{graph};

  my %parameters = @_;

  my $write_to_file = 0;
  my $filename = "";
  if (exists $parameters{filename}) {
    $write_to_file = 1;
    $filename = $parameters{filename};
    open(WATT, "> $filename") or die("Could not open file: $filename\n");
  }

  my %link_hash;

  if ($write_to_file == 1) {
    print WATT "reading the input...\n";
  }

  %link_hash = $self->get_adjacency_matrix();

  my $skipped = 0;
  my %local_cc = ();

  foreach my $v (keys %link_hash) {
    my $c = 0;
    my $connected = 0;
    my %nn;
    my @neighbors;

    if (exists $link_hash{$v}) {
      @neighbors = keys %{$link_hash{$v}};
      if (@neighbors > 1) {
        if (@neighbors > 5000) {
          $skipped++;
          next;
        }
        foreach my $n1 (0..$#neighbors) {
          foreach my $n2 ($n1+1..$#neighbors) {
            if (exists $link_hash{$neighbors[$n1]}{$neighbors[$n2]}) {
              $connected++;
            }
          }
        }
        $c = 2 * $connected / (@neighbors * (@neighbors-1));
      }
    }

    if ($write_to_file == 1) {
      print WATT "clustering coefficient for $v is $c\n";
    }

    $local_cc{$v} = $c;
  }

  if ($write_to_file == 1) {
    print WATT "\nnumber of nodes skipped (with degree > 5000): $skipped\n";
  }

  close WATT;

  return %local_cc;
}

sub print_db
{
        my $self = shift;
        my $filename = shift;

        $hash_size = 100000;

        tie my %hash, 'BerkeleyDB::Btree', -Filename => $filename,
            -Cachesize => $hash_size,
            -Flags => DB_CREATE,
            -Mode => 0660
          or die "Couldn't create db '$filename': $!\n";

        foreach $key (keys %hash) {
                print "DB: Key: $key, Value: ", $hash{$key}, "\n";
        }

        untie %hash;

}

# Taken from build-db and slightly modified
sub write_db
{
        my $self = shift;
        my $graph = $self->{graph};
        my $filename = shift;

        my %parameters = @_;

        $transpose = 0;
        if (exists $parameters{transpose} and $parameters{transpose} == 1) {
                $transpose = 1;
        }

        $hash_size = 100000;
        if (exists $parameters{hash_size}) {
                $hash_size = $parameters{hash_size};
        }

        tie my %hash, 'BerkeleyDB::Btree', -Filename => $filename,
            -Cachesize => $hash_size,
            -Flags => DB_CREATE,
            -Mode => 0660
          or die "Couldn't create db '$filename': $!\n";

        my $current_from = "";
        my $to_links = "";
        my $num_recs = 0;

        %hash = ();

        foreach my $e (sort $graph->edges) {
                my ($from, $to) = @$e;

                if ($transpose == 1) {
                        my $temp = $from;
                        $from = $to;
                        $to = $temp;
                }

                if ($current_from eq "") {
                        $current_from = $from;
                        $to_links = "$to";

                } elsif ($from ne $current_from) {
                        $hash{$current_from} = $to_links;
                        $num_recs++;
                        $current_from = $from;
                        $to_links = "$to";

                } else {
                        $to_links .= " $to";
                }
        }

        $hash{$current_from} = $to_links;
        $num_recs++;

        untie %hash;

}

# Taken from scc-db-3.pl and slightly modified
sub dfs_visit_1 {
    my ($u) = @_;

    $color{$u} = 'gray';
    print STDERR "dfs-visit: visiting $u\n" if $verbose;
    if (exists $adj{$u}) {
  for my $v (split " ", $adj{$u}) {
      dfs_visit_1($v) if !exists($color{$v});
  }
    }
    $color{$u} = 'black';
    print FIN "$u\n";
    print STDERR "." if $dots and !($dotcount++%10000);
}

sub iterative_dfs_visit_1 {
    my ($u) = @_;
    my @s = ();

    $color{$u} = 'gray';
    push @s, $u;
    while ($#s >= 0) {
  $u = pop @s;
  if ($color{$u} eq 'gray') {
      print STDERR "dfs-visit: visiting $u\n" if $verbose;
      $color{$u} = 'black';
      push @s, $u;
      for my $v (split " ", $adj{$u}) {
    if (!exists($color{$v})) {
        push @s, $v;
        $color{$v} = 'gray';
    }
      }

  } elsif ($color{$u} eq 'black') {
      print STDERR "dfs-visit: finishing $u\n" if $verbose;
      print FIN "$u\n";
      print STDERR "." if $dots and !($dotcount++%10000);
  } else {
      warn "ERROR: uncolored page in stack: ($u, $color{$u})\n";
  }
    }
}

sub iterative_dfs_visit_1_v2 {
    my ($u) = @_;
    my @s = ();

    push @s, $u;
    while ($#s >= 0) {
  $u = pop @s;
        next if not exists $color{$u};
  next if $color{$u} eq 'black';
      print STDERR "dfs-visit: visiting $u\n" if $verbose;
      $color{$u} = 'gray';
      push @s, $u;
                        if (exists $adj{$u}) {
      for my $v (split " ", $adj{$u}) {
    if (!exists($color{$v})) {
        push @s, $v;
    }
      }

  } elsif ($color{$u} eq 'gray') {
      print STDERR "dfs-visit: finishing $u\n" if $verbose;
      $color{$u} = 'black';
      print FIN "$u\n";
      print STDERR "." if $dots and !($dotcount++%10000);
  }
    }
}

sub dfs_visit_2 {
    my ($u) = @_;
    my @children;

    $color{$u} = 'gray';
    print STDERR "dfs-visit-2: visiting $u\n" if $verbose;
    if (exists $adjT{$u}) {
  for my $v (split " ", $adjT{$u}) {
      next if exists($color{$v});
      my $recursed = dfs_visit_2($v);
      push @children, @$recursed;
  }
    }
    $color{$u} = 'black';
    print STDERR "." if $dots and !($dotcount++%10000);
    unshift @children, $u;
    return \@children;
}

sub iterative_dfs_visit_2 {
    my ($u) = @_;
    my @s = ();
    my @children = ();

    $color{$u} = 'gray';
    push @s, $u;
    while ($#s >= 0) {
  $u = pop @s;
  if ($color{$u} eq 'gray') {
      print STDERR "dfs-visit-2: visiting $u\n" if $verbose;
      $color{$u} = 'black';
      push @s, $u;
      for my $v (split " ", $adjT{$u}) {
    if (!exists($color{$v})) {
        push @s, $v;
        $color{$v} = 'gray';
    }
      }

  } elsif ($color{$u} eq 'black') {
      print STDERR "dfs-visit-2: finishing $u\n" if $verbose;
      push @children, $u;
      print STDERR "." if $dots and !($dotcount++%10000);
  } else {
      warn "ERROR: uncolored page in stack: ($u, $color{$u})\n";
  }
    }

    return \@children;
}

sub iterative_dfs_visit_2_v2 {
    my ($u) = @_;
    my @s = ();
    my @children = ();

    push @s, $u;
    while ($#s >= 0) {
  $u = pop @s;
  next if $color{$u} eq 'black';
  if (!exists($color{$u})) {
      print STDERR "dfs-visit-2: visiting $u\n" if $verbose;
      $color{$u} = 'gray';
      push @s, $u;
      for my $v (split " ", $adjT{$u}) {
    if (!exists($color{$v})) {
        push @s, $v;
    }
      }

  } elsif ($color{$u} eq 'gray') {
      print STDERR "dfs-visit-2: finishing $u\n" if $verbose;
      $color{$u} = 'black';
      push @children, $u;
      print STDERR "." if $dots and !($dotcount++%10000);
  }
    }

    return \@children;
}

sub find_scc {
        my $self = shift;
        my %adj;
        my %adjT;
        my $v;

        my $verbose = 0;
        my $dots = 0;
        my $finish = 0;

        my $dbfile = shift;
        my $xpfile = shift;
        my $finfile = shift;
        my $color = ".tmp.scc-db-3-".time."-$$";
        my %color;

        my %parameters = @_;

        if (exists $parameters{verbose} and $parameters{verbose} == 1) {
                $verbose = 1;
        }

        if (exists $parameters{dots} and $parameters{dots} == 1) {
                $dots = 1;
        }

        $dots = 0 if $verbose;
        if ($dots) {
            # make stderr unbuffered
            my $oldfh = select(STDERR); $| = 1; select($oldfh);
        }
        my $dotcount = 0;

        # $dbinfo->{'cachesize'} = 50000;

        goto SECOND_DFS if $finish;

        FIRST_DFS:
        tie %adj, 'BerkeleyDB::Btree', -Filename => $dbfile,
            -Cachesize => 50000,
            -Mode => 0660
          or die "Couldn't open '$dbfile' as BerkeleyDB::Btree: $!\n";

        tie %color, 'BerkeleyDB::Btree', -Filename => $color,
            -Flags => DB_CREATE,
            -Cachesize => 50000,
            -Mode => 0660
          or die "Couldn't open '$color' as BerkeleyDB::Btree: $!\n";

        open(FIN, ">$finfile") or die "Couldn't open $finfile: $!\n";

        print STDERR "dfs-1: " if $dots;
        while ($v = each %adj) {
            if (!exists($color{$v})) {
          print STDERR "dfs: examining $v\n" if $verbose;
          iterative_dfs_visit_1_v2($v);
            }
        }
        print STDERR "done, cleaning up.\n" if $verbose;
        close(FIN);
        untie %adj;
        untie %color;
        unlink $color;

        SECOND_DFS:
        tie %adjT, 'BerkeleyDB::Btree', -Filename => $xpfile,
            -Mode => 0660,
            -Cachesize => 50000
          or die "Couldn't open '$xpfile' as BerkeleyDB::Btree: $!\n";

        tie %color, 'BerkeleyDB::Btree', -Filename => "color",
            -Flags => DB_CREATE,
            -Cachesize => 50000,
            -Mode => 0660
          or die "Couldn't open 'color' as BerkeleyDB::Btree: $!\n";

        open(FIN, "tac $finfile|") or die "Couldn't tac $finfile: $!\n";
        print STDERR "\ndfs-2: " if $dots;
        while (<FIN>) {
            chomp;
            my $v = $_;
            if (!exists($color{$v})) {
          print STDERR "dfs: examining $v\n" if $verbose;
          my $scc = iterative_dfs_visit_2_v2($v);
          print scalar(@$scc), "\n   ", join("\n   ", @$scc), "\n";
            }
        }
        print STDERR "done, cleaning up.\n" if $verbose;
        close(FIN);
        untie %adjT;
        untie %color;
        unlink "color";
}

sub get_scc {
        my $self = shift;

        my $fileA=shift;
        my $map=shift;
        my %linkMap;

        my $out_file = shift;

        dbmopen %linkMap, $map, 0666;

        open (IN, "<$fileA") or die "Couldn't open file: $fileA.\n";
        open (OUT, ">$out_file") or die "Coulnd't open output file: $out_file.\n";

        foreach (<IN>)
        {
          chomp;
          print OUT "$linkMap{$_}\n";
        }

        close IN;
        close OUT;

        return %linkMap;
}

=head2 Number of find_largest_component_size

Find size of largest component

=cut

sub find_largest_component_size {
  my $self = shift;

  my @components = $self->find_components("weakly");
  if (scalar(@components) > 0) {
    my $max = 0;
    my $component_count = scalar(@components);

    for (my $i = 0; $i < $component_count; $i++) {
      my $component = $components[$i];
      if (scalar(@{$component}) > $max) {
        $max = scalar(@{$component});
      }
    }
    if ($verbose) { print STDERR "Found size $max\n"; }
    return $max;
  } else {
    return 0;
  }
}

#
# Find the largest component
# Pass in connected component type (strongly or weakly)
#
sub find_largest_component
{
  my $self = shift;
  my $type = shift;
  if ($verbose) { print STDERR "Copying network\n"; }
  my $copy = dclone($self);

  my $graph = $self->{graph};
  my @wcc = ();
  if ($self->{directed}) {
    if ($type eq "weakly") {
      if ($verbose) { print STDERR "Finding weakly connected components\n"; }
      @wcc = $graph->weakly_connected_components();
    } elsif ($type eq "strongly") {
      if ($verbose) { print STDERR "Finding strongly connected components\n"; }
      @wcc = $graph->strongly_connected_components();
    }
  } else {
    if ($verbose) { print STDERR "Finding largest connected component\n"; }
    @wcc = $graph->connected_components();
  }

  # Find largest component
  my $max = 0;
  my @largest_component = ();
  my $largest_component;
  my $component_count = scalar(@wcc);

  for (my $i = 0; $i < $component_count; $i++) {
    my $component = $wcc[$i];
    if (scalar(@{$component}) > $max) {
      if ($verbose) { print "component size: ", scalar(@{$component}), "\n"; }
      @largest_component = @{$component};
      $largest_component = $i;
      $max = scalar(@{$component});
    }
  }

  if ($verbose) { print "Creating subset network\n"; }
  # It's faster to remove the subsets that are not in the largest component
  # assuming we have a giant component
  if (($self->num_nodes() / 2) < $max) {
    # giant component
    if ($verbose) { print "Found giant component\n"; }
    for (my $i = 0; $i < $component_count; $i++) {
      if ($i != $largest_component) {
        my $comp = $wcc[$i];
        foreach my $v (@{$comp}) {
          $copy->remove_node($v);
        }
      }
    }
    return $copy;
  } else {
    my $net = $self->create_subset_network(\@largest_component);
    return $net;
  }
}

sub write_link_matlab
{
        my $self = shift;
        my $hist = shift;
        my %histogram = %$hist;
        my $filename = shift;
        my $dependency = shift;

        open(MLAB, "> $filename") or die "Could not open file: $filename";

        my @cts;
        my @vals;

        foreach my $value (keys %histogram) {
                my $num = $histogram{$value};

                push(@cts, $num);
                push(@vals, $value);
        }

        print MLAB "yy = [";
        foreach $ct (@cts) {
            print MLAB "$ct ";
        }

        print MLAB "];\n";

        print MLAB "xx = [";
        foreach $val (@vals) {
            print MLAB "$val ";
        }

        print MLAB "];\n";

        print MLAB <<EOH
  loglog(xx,yy,'.');
  axis ([0,10000,0,10000]);
  grid on;
  xlabel('X');
  ylabel('Y');
EOH
            ;

        print MLAB "print ('-deps', '$dependency')";
        close(MLAB);
}

sub write_link_dist
{
        my $self = shift;
        my $hist = shift;
        my %histogram = %$hist;

        my $filename = shift;

        open(OUT, "> $filename") or die ("Could not open file: $filename");

        my $total_in = 0;
        my $num_nodes = 0;
        foreach my $value (keys %histogram)
        {
                #skip nodes that have no links
                next if $value == 0;

                my $num = $histogram{$value};

                $total_in += $value * $num;
                $num_nodes += $num;

                print OUT "$num pages have $value links\n";
        }

        my $avg = $total_in/$num_nodes;
        print OUT "average degree $avg\n";

        close OUT;
}

sub average_cosines
{
        my $self = shift;
        my $graph = $self->{graph};

        my $cm = shift;
        my %cos_matrix = %$cm;

        my $tot_link_cos = 0;
        my $link_count = 0;

        my $tot_nl_cos = 0;
        my $nl_count = 0;

        foreach my $doc1 (keys %cos_matrix) {
                foreach my $doc2 (keys %{ $cos_matrix{$doc1} }) {
                        if ($graph->has_edge($doc1, $doc2)) {
                                $tot_link_cos += $cos_matrix{$doc1}{$doc2};
                                $link_count++;
                        } else {
                                $tot_nl_cos += $cos_matrix{$doc1}{$doc2};
                                $nl_count++;
                        }
                }
        }

        my $link_avg = 0;
        if ($link_count > 0) {
                $link_avg = $tot_link_cos/$link_count;
        }

        my $nl_avg = 0;
        if ($nl_count > 0) {
                $nl_avg = $tot_nl_cos/$nl_count;
        }

        return ($link_avg, $nl_avg);
}

# Used by the cosine histogram function:
sub get_index
{
    my $d = shift;

    if ($d =~ /^1\./) { return 100;}

    $d =~ s/.*\.(\d\d)$/$1/g;
    my $f = int ($d);

    return $f;
}

sub cosine_histograms
{
        my $self = shift;
        my $graph = $self->{graph};
        my $cm = shift;
        my %cos_matrix = %$cm;

        my $link_total = 0;
        my $nolink_total = 0;

        my $link_count = 0;
        my $nolink_count = 0;

        my @link_bin = ();
        $link_bin[100] = 0;

        my @nolink_bin = ();
        $nolink_bin[100] = 0;

        foreach my $doc1 (keys %cos_matrix) {
                foreach my $doc2 (keys %{ $cos_matrix{$doc1} }) {
                        my $cos = $cos_matrix{$doc1}{$doc2};
                        my $c = sprintf("%.2f", $cos);
                        my $d = get_index($c);

                        if ($graph->has_edge($doc1, $doc2)) {
                                $link_bin[$d]++;
                        } else {
                                $nolink_bin[$d]++;
                        }
                }
        }

        return (\@link_bin, \@nolink_bin);

}

sub write_histogram_matlab
{
        my $self = shift;
        my $lb = shift;
        my @link_bin = @$lb;
        my $nlb = shift;
        my @nolink_bin = @$nlb;

        my $filename_base = shift;
        my $domain = shift;

        my $fname = $filename_base . "_linked_hist.m";
        my $fname2 = $filename_base . "_linked_cumulative.m";
        open(OUT,">$fname")
          or die ("Cannot write to $fname");
        open(OUT2,">$fname2")
    or die ("Cannot write to $fname2");
        print OUT "x = [";
        print OUT2 "x = [";
        my $cumulative=0;

        foreach my $i (0..$#link_bin)
        {
                my $out = $link_bin[$i];
                if(not defined $link_bin[$i]) {
                        $out = 0;
                }
                $cumulative+= $out;
                my $thres = $i/100;
                print OUT "$thres $out\n";
                print OUT2 "$thres $cumulative\n";
        }

        print OUT "];\n";
        print OUT "loglog(x(:,1), x(:,2));\n";
        print OUT "title(['Number of linked pairs per cosine value in the $domain domain']);\n";
        print OUT "xlabel('Cosine value');\n";
        print OUT "ylabel('Number of linked pairs');\n";
        print OUT "v = axis;\n";
        print OUT "v(1) = 0; v(2) = 1;\n";
        print OUT "axis(v)\n";
        print OUT "print ('-deps', '$domain-linked-histogram')\n";
        close OUT;

        print OUT2 "];\n";
        print OUT2 "loglog(x(:,1), x(:,2));\n";
        print OUT2 "title(['Number of linked pairs per cosine value in the $domain domain']);\n";
        print OUT2 "xlabel('Cosine value');\n";
        print OUT2 "ylabel('Number of linked pairs with cosine less than or equal to threshold');\n";
        print OUT2 "v = axis;\n";
        print OUT2 "v(1) = 0; v(2) = 1;\n";
        print OUT2 "axis(v)\n";
        print OUT2 "print ('-deps', '$domain-linked-cumulative')\n";
        close OUT2;

        $fname = $filename_base . "_not_linked_hist.m";

        open(OUT,">$fname")
            or die ("Cannot write to $fname");
        print OUT "x = [";

        foreach my $i (0..$#nolink_bin)
        {
                my $out = $nolink_bin[$i];
                if(not defined $nolink_bin[$i])
                {
                        $out = 0;
                }
                my $thres = $i/100;
                print OUT "$thres $out\n";
        }

        print OUT "];\n";
        print OUT "loglog(x(:,1), x(:,2));\n";
        print OUT "title(['Number of not-linked pairs per cosine value in the $domain domain']);\n";
        print OUT "xlabel('Cosine value');\n";
        print OUT "ylabel('Number of not-linked pairs');\n";
        print OUT "v = axis;\n";
        print OUT "v(1) = 0; v(2) = 1;\n";
        print OUT "axis(v)\n";
        print OUT "print ('-deps', '$domain-not-linked-histogram')\n";
        close OUT;
}

sub get_histogram_as_string
{
  my $self = shift;
  my $lb = shift;
  my @link_bin = @$lb;
  my $nlb = shift;
  my @nolink_bin = @$nlb;

        my $retString = "linked histogram:\n";

        foreach my $i (0..$#link_bin)
        {
                my $out = $link_bin[$i];
                if(not defined $link_bin[$i])
                {
                        $out = 0;
                }
                my $thres = $i/100;
                $retString .= "$thres $out\n";
        }

        $retString .= "not linked histogram:\n";

        foreach my $i (0..$#nolink_bin)
        {
                my $out = $nolink_bin[$i];
                if(not defined $nolink_bin[$i])
                {
                        $out = 0;
                }
                my $thres = $i/100;
                $retString .= "$thres $out\n";
        }

        return $retString;
}

sub create_cosine_dat_files
{
        my $self = shift;
        my $domain = shift;
        my $cm = shift;
        my %cos_matrix = %$cm;
        my %parameters = @_;

        my $directory = $domain;
        if (exists $parameters{directory}) {
                $directory = $parameters{directory};
        }

        my %thresh;
        my %diag_h = ();
        my @lines = ();

        srand;

        foreach my $n1 (keys %cos_matrix) {
                foreach my $n2 (keys %{ $cos_matrix{$n1} }) {
                        my $cos = $cos_matrix{$n1}{$n2};
                        push @lines, "$n1 $n2 $cos\n";
                        push @lines, "$n2 $n1 $cos\n";
                        unless(defined $diag_h{$n1}) {
                                push @lines, "$n1 $n1 1\n";
                                $diag_h{$n1} = 1;
                        }
                        unless(defined $diag_h{$n2}) {
                                push @lines, "$n2 $n2 1\n";
                                $diag_h{$n2} = 1;
                        }

                        foreach my $i (0 .. 9)
                        {
                                foreach my $y (0 .. 9)
                                {
                                        $thres = $i/10 + $y / 100;

                                        if ($cos > $thres) {
                                                $thresh{$thres} ++;
                                        }
                                        else { goto HERE;}
                                }
                        }
                        HERE:
                }
        }

        my $fname = "$directory/$domain-point-one-all.dat";
        open(OUT, ">$fname") or die "cannot write to $fname\n";

        foreach $i (0 .. 9)
        {
           foreach $y (0 .. 9)
           {
              $thres = $i/10 + $y / 100;
              print OUT "$thres ";
                                if (exists $thresh{$thres}) {
                                        print OUT $thresh{$thres};
                                }
                                print OUT "\n";
           }
        }

        close(OUT);

        open(OUT, ">$directory/$domain-all-cosine")
              or die "cannot write to $directory/$domain-all-cosine\n";
        print OUT @lines;
        close(OUT);

        foreach $i (0 .. 9)
        {
                @thresh =();
                %didhash=();

                $thres = $i / 10;
                foreach $l (@lines)
                {
                        ($doc1, $doc2, $cos) = split " ", $l;
                        if($cos >= $thres)
                        {
                                unless(defined $didhash{$doc1})
                        {
                                $didhash{$doc1} = 0;
                        }
                                $didhash{$doc1}++;
                        }
                }

                foreach $l (@lines)
                {
                        ($doc1, $doc2, $cos) = split " ", $l;
                        if($cos > $thres)
                        {
                                $out_degree = 1/$didhash{$doc1};
                                push @thresh, "$doc1 $doc2 $out_degree\n";
                        }
                }

                $fname = "$directory/$domain.$thres";
                $fname =~ s/\./-/g;
                $fname = $fname . ".dat";

                open(OUT, ">$fname") or die "cannot write to $fname\n";
                print OUT @thresh;
                close(OUT);
        }
}

sub count_lines {
        my $self = shift;
        my $filename = shift;

        my @lines = `cat $filename`;

        return scalar(@lines);
}

# From the C2 script
sub get_dat_stats
{
        my $self = shift;
        my $domain = shift or die "need a domain name.";
        my $links_file = shift or die "need a links file.";
        my $cosine_file = shift or die "need a cosine file.";

        my $strResult = "";

        my $num_links_link = $self->count_lines("$links_file");

        my $num_pairs =  $self->count_lines("$cosine_file");

        my $num_links_0 = $self->count_lines("$domain-0.dat");
        my $num_links_0_1 = $self->count_lines("$domain-0-1.dat");
        my $num_links_0_5 = $self->count_lines("$domain-0-5.dat");
        my $num_links_0_9 = $self->count_lines("$domain-0-9.dat");

        my $tot_cos = 0;
        my $cnt = 0;
        open(COS, "$cosine_file") or die "cannot open $cosine_file\n";
        while(<COS>)
        {
                $line = $_;
                chomp $line;
                ($doc1, $doc2, $cos) = split " ", $line;
                $cnt++;
                $tot_cos += $cos;
        }
        close(COS);

        my $avg_cosine = $tot_cos/$cnt;
        $avg_cosine = sprintf("%9.2f", $avg_cosine);

        $strResult .= "cosine sampled from $num_pairs (unique) pairs\n";
        $strResult .= "number of links in cosine 0 file: $num_links_0\n";
        $strResult .= "ratio of links in cosine 0-1 file: " . $num_links_0_1/$num_links_0 . "\n";
        $strResult .= "ratio of links in cosine 0-5 file: " . $num_links_0_5/$num_links_0 . "\n";
        $strResult .= "ratio of links in cosine 0-9 file: " . $num_links_0_9/$num_links_0 . "\n";
        $strResult .= "average cosine per URL pair: $avg_cosine\n";

        open(POINTONE, "$domain-point-one-all.dat")
          or die "Cannot open $domain-point-one-all.dat\n";

        my $found_thres = 0;
        while(<POINTONE>)
        {
                my $line = $_;
                chomp $line;
                (my $thres, my $count) = split " ", $line;
                if($count <= $num_links_link)
                {
                        $found_thres = 1;
                        last;
                }
        }
        close (POINTONE);

        if($found_thres == 0)
        {
                # cosine maxes out at 1. a value of 2 indicates
                # cosine-based always estimates more links than real link
                # this does not account for the case when the cosine-based
                # metrix estimates less than the number of real links
                print STDERR "2\n";
        }

        return $strResult;
}

sub get_undirected_graph
{
        my $self = shift;
        my $graph = shift;

        my $u_graph = $graph->undirected_copy_graph;

        # Copy the weight for each vertex and edge to the new
        # undirected graph
        foreach my $v ($graph->vertices)
        {
                if ($graph->has_vertex_weight($v))
                {
                        my $weight = $graph->get_vertex_weight($v);
                        $u_graph->set_vertex_weight($v, $weight);
                }
        }

        foreach my $e ($graph->edges)
        {
                my $u;
                my $v;

                ($u, $v) = @$e;
                if ($graph->has_edge_weight($u, $v))
                {
                        my $weight = $graph->get_edge_weight($u, $v);
                        $u_graph->set_edge_weight($u, $v, $weight);
                }
        }

        return $u_graph;
}


sub scale_to_unit_interval {

    my $self = shift;
    my $vector = shift;

    my $rows = ($vector->dim())[0];
    my $min = $vector->element(1,1);
    my $max = $vector->element(1,1);
    my @list;

    for (my $i = 0; $i < $rows; $i++) {
        push @list, $vector->element($i + 1, 1);
    }

    foreach my $elt (@list) {
        if ($elt < $min) {
            $min = $elt;
        }
        if ($elt > $max) {
            $max = $elt;
        }
    }

    if ($max != $min) {
        @list = map { ($_ - $min) / ($max - $min) } @list;
    } else {
        if ($max == 0) {
            die "Zero vector cannot be scaled";
        } else {
            @list = map { $_ / $max } @list;
        }
    }

    for (my $i = 0; $i < @list; $i++) {
        $vector->assign($i + 1, 1, $list[$i]);
    }

    return $vector;
}


sub mmr_rerank_lexrank {

    my $self = shift;
    my $lambda = shift;

    die "mmr parameter must be in [0,1]" unless (0 <= $lambda && $lambda <= 1);

    # Convert to cluster to get lexical similarity
    my $cluster = Clair::Cluster->new();
    my @verts = $self->{graph}->vertices();
    foreach my $vertex (@verts) {
        my $doc = $self->{graph}->get_vertex_attribute($vertex, "document");
        $cluster->insert($vertex, $doc);
    }

    # Similarity between sents
    my %sim = $cluster->compute_cosine_matrix();

    # Copying the lexrank vector
    my $lr_matrix = $self->get_property_vector(\@verts, "lexrank_value");
    $lr_matrix = $self->scale_to_unit_interval($lr_matrix);
    my %scores = ();
    for (my $i = 0; $i < @verts; $i++) {
        $scores{$verts[$i]} = $lr_matrix->element($i + 1, 1);
    }

    # Sorting the sentences based on their lexrank score
    my @sorted_verts = sort { $scores{$a} cmp $scores{$b} } keys %scores;

    # Applying MMR
    # Don't need to loop past 2nd to last sentence, since its score remains
    # the same
    for (my $i = 0; $i < @sorted_verts - 1; $i++) {

        my $vertex = $sorted_verts[$i];
        my $old_score = $scores{$vertex};
        my $max_sim = 0;

        # Find the maximum similarity between this (the ith) sentence
        # and the sentences with original scores higher than this sentence
        for (my $j = $i + 1; $j < @sorted_verts; $j++) {
            my $sim = $sim{$vertex}->{$sorted_verts[$j]};
            if ($sim > $max_sim) {
                $max_sim = $sim;
            }
        }

        # Set the new score
        my $new_score = $lambda * $old_score - (1 - $lambda) * $max_sim;
        $self->{graph}->set_vertex_attribute($vertex,
            "lexrank_value", $new_score);
    }

    # Scale vector to [0,1]
          my $v = $self->get_property_vector(\@verts, "lexrank_value");
          $v = $self->scale_to_unit_interval($v);
          $self->set_property_matrix(\@verts, $v, "lexrank_value");
}


# This will compute the power law exponent of a set of data
# this uses linear regression on the logs of the data points to
# find both the exponent and the exponent.
sub linear_regression
{
        my $self = shift;
        my $hist = shift;
        my %histogram = %$hist;

        my %parameters = @_;

        my $log = 0;
        if (exists $parameters{log}) {
                $log = $parameters{log};
        }


        my %points;

        # x_total is the sum of all x's
        my $x_total=0;
        # y_total is likewise: \sum_i y_i
        my $y_total=0;
        # number of data points.
        my $num_points=0;

        foreach my $value (keys %histogram)
        {
                my $num = $histogram{$value};
                # Don't take the log of 0
                if ($value == 0 || $num == 0)
                {
                        next;
                }

                my ($one, $two);
                if ($log) {
                  $one = log($num);
                  $two = log($value);
                } else {
                  $one = $num;
                  $two = $value;
                }

                $points{$two}=$one;
                $x_total+=$two;
                $y_total+=$one;
                $num_points++;
        }

        if ($num_points == 0) {
          return "Unable to compute power law (div by 0)";
        }

        my $x_average = $x_total / $num_points;
        my $y_average = $y_total / $num_points;

        # \sum_i x_i y_i
        my $sum_x_and_y = 0;
        # \sum_i {x_i}^2
        my $sum_x_squared = 0;
        my $sum_y_squared = 0;
        my $sum_x = 0;
        my $sum_y = 0;

        foreach (keys %points) {
          $sum_x_and_y += ($_) * ($points{$_});
          $sum_x_squared += ($_)**2;
          $sum_y_squared += $points{$_}**2;
          $sum_x += $_;
          $sum_y += $points{$_};
        }

        # here's where the formula for linear regression comes in (check your
        # stats book if you forgot)

        # This check added by Mark Hodges May 10, 2006 to prevent
        # a divide by zero
        my $denom = $num_points * $sum_x_squared - $sum_x**2;
        if ($denom == 0) {
                return "Unable to compute power law (div by 0)";
        }

        my $m = ($num_points * $sum_x_and_y - $sum_x * $sum_y) /
              ($num_points * $sum_x_squared - $sum_x**2);

        my $b = $y_average - $m * $x_average;

        #  Since $b is actually (log C) in log y = log C + a log x,
        #  with y = Ce^(ax), we get
        my $C = exp($b);
        my $a = $m;

        # calculate r-squared
        my $sxy = $sum_x_and_y - (($sum_x * $sum_y) / $num_points);
        my $sxx = $sum_x_squared - (($sum_x)**2) / $num_points;
        my $syy = $sum_y_squared - (($sum_y)**2) / $num_points;

        my $r = $sxy / sqrt($sxx * $syy);

        my @ret = ();
        my $retVal = "y = $C x^$a";

        push @ret, $a;
        push @ret, $r;

        return @ret;
}

=head2 find_components

find_components($type)

Return s list of components in the graph.
Type refers to the type of components and is either "weakly" or "strongly"

=cut

sub find_components
{
  my $self = shift;
  my $type = shift;

  my $graph = $self->{graph};
  my @comp = ();

  if ($self->{directed}) {
    if ($type eq "weakly") {
      if ($verbose) { print STDERR "Finding weakly connected components\n"; }
      @comp = $graph->weakly_connected_components();
    } elsif ($type eq "strongly") {
      if ($verbose) { print STDERR "Finding strongly connected components\n"; }
      @comp = $graph->strongly_connected_components();
    }
  } else {
    if ($verbose) { print STDERR "Finding connected components\n"; }
    @comp = $graph->connected_components();
  }

  return @comp;
}


=head2 get_cumulative_distribution

get_cumulative_distribution(\%histogram)

Convert a histogram to cumulative distribution

=cut

sub get_cumulative_distribution
{
  my $self = shift;
  my $h = shift;
  my %hist = %$h;

  my $sum = 0;
  foreach my $v (values %hist) {
    $sum += $v;
  }

  my %cum_hist = ();
  foreach my $k (sort {$a <=> $b} keys %hist) {
    $cum_hist{$k} = $sum;
    $sum -= $hist{$k};
  }

  return %cum_hist;
}

=head2 save_network_to_file

save_network_to_file($filename)

Save network to a file, including edge weights if they are defined.

=cut

sub save_network_to_file
{
  my $self = shift;
  my $fn = shift;

  printf STDERR "save_network_to_file is deprecated, please use ";
  printf STDERR "Clair::Network::Writer::Edgelist\n";

  my $export = Clair::Network::Writer::Edgelist->new();
  $export->write_network($self, $fn, @_);
}

=head2 output_graphviz

output_graphviz($filename)

Output GraphViz compatible file
To generate postscript:
dot -Tps filename.dot > filename.ps

=cut

sub output_graphviz
{
  my $net = shift;
  my $fn = shift;

  open(DOTFILE, ">$fn") or die "Couldn't open $fn for writing dotfile\n";

  print DOTFILE "digraph G {\n";
  foreach my $edge ($net->get_edges) {
    my ($u, $v) = @$edge;
    print DOTFILE "\"", $u, "\" -> \"", $v, "\";\n";
  }
  print DOTFILE "}\n";

  close DOTFILE;
}


=head2 print_network_info

print_network_info()

Prints various statistics about the network

=cut

sub print_network_info
{
  my $net = shift;

  my %parameters = @_;

  my $delim = " ";
  if (exists $parameters{delim}) {
    $delim = $parameters{delim};
  }

  my $assortativity = 0;
  if (exists $parameters{assortativity}) {
    $assortativity = $parameters{assortativity};
  }

  my $localcc = 0;
  if (exists $parameters{localcc}) {
    $localcc = $parameters{localcc};
  }

  my $paths = 0;
  if (exists $parameters{paths}) {
    $paths = $parameters{paths};
  }

  my $diameter = 0;
  if (exists $parameters{paths}) {
          $diameter = $parameters{paths};
  }

  my $wcc = 0;
  if (exists $parameters{wcc}) {
    $wcc = $parameters{wcc};
  }

  my $scc = 0;
  if (exists $parameters{scc}) {
    $scc = $parameters{scc};
  }

  my $components = 0;
  if (exists $parameters{components}) {
    $components = $parameters{components};
  }

  my $triangles = 0;
  if (exists $parameters{triangles}) {
    $triangles = $parameters{triangles};
  }

  my $verbose = 0;
  if (exists $parameters{verbose}) {
    $verbose = $parameters{verbose};
  }

  # Compute shortest path matrix
  my $asp_matrix = $net->get_shortest_path_matrix(directed => $net->{directed});

  print "Network information:\n";
  print "  nodes: ", $net->num_nodes(), "\n";
  print "  edges: ", scalar($net->get_edges()), "\n";
  print "  diameter: ", $net->diameter(directed => $net->{directed}), "\n";
  print "  average degree: ",
    Clair::Util::round_number($net->avg_total_degree(), 2), "\n";
  print "  largest connected component size: ",
    $net->find_largest_component_size(), "\n";

  print "  Degree statistics:\n";
  if (not $net->{directed}) {
    # Only print one set of statistics
    my %hist = ();

    %hist = $net->compute_in_link_histogram();
    my @fit = $net->cumulative_power_law_exponent(\%hist);
    my @newman = $net->newman_power_law_exponent(\%hist, 2);
    print "    degree stats:\n";
    if ((defined $fit[0]) and (defined $fit[1])) {
      print "      power law exponent: ", Clair::Util::round_number($fit[0], 2),
        " r-squared: ", Clair::Util::round_number($fit[1], 2), "\n";
      if ($fit[2] < 0.05) {
        print "      likely power law relationship (p = " .
          Clair::Util::round_number($fit[2], 2) . ")\n";
      } else {
        print "      not a power law relationship (p = " .
          Clair::Util::round_number($fit[2], 2) . ")\n";
      }
    }
    if ((defined $newman[0]) and (defined $newman[1])) {
      print "      Newman power law exponent: ",
        Clair::Util::round_number($newman[0], 2),
            ", error: ", Clair::Util::round_number($newman[1], 2), "\n";
    }
  } else {
    # Directed network
    my %hist = ();
    %hist = $net->compute_in_link_histogram();
    my @fit = $net->cumulative_power_law_exponent(\%hist);
    my @newman = $net->newman_power_law_exponent(\%hist, 2);
    print "    in degree stats:\n";
    if ((defined $fit[0]) and (defined $fit[1])) {
      print "      power law exponent: ", Clair::Util::round_number($fit[0], 2),
        " r-squared: ", Clair::Util::round_number($fit[1], 2), "\n";
      if ($fit[2] < 0.05) {
        print "      likely power law relationship (p = " .
          Clair::Util::round_number($fit[2], 2) . ")\n";
      } else {
        print "      not a power law relationship (p = " .
          Clair::Util::round_number($fit[2], 2) . ")\n";
      }
    }
    if ((defined $newman[0]) and (defined $newman[1])) {
      print "      Newman power law exponent: ",
        Clair::Util::round_number($newman[0], 2),
            ", error: ", Clair::Util::round_number($newman[1], 2), "\n";
    }

    %hist = $net->compute_out_link_histogram();
    @fit = $net->cumulative_power_law_exponent(\%hist);
    @newman = $net->newman_power_law_exponent(\%hist, 2);
    print "    out degree stats:\n";
    if ((defined $fit[0]) and (defined $fit[1])) {
      print "      power law exponent: ", Clair::Util::round_number($fit[0], 2),
        " r-squared: ", Clair::Util::round_number($fit[1], 2), "\n";
      if ($fit[2] < 0.05) {
        print "      likely power law relationship (p = " .
          Clair::Util::round_number($fit[2], 2) . ")\n";
      } else {
        print "      not a power law relationship (p = " .
          Clair::Util::round_number($fit[2], 2) . ")\n";
      }
    }
    if ((defined $newman[0]) and (defined $newman[1])) {
      print "      Newman power law exponent: ",
        Clair::Util::round_number($newman[0], 2),
            ", error: ", Clair::Util::round_number($newman[1], 2), "\n";
    }

    %hist = $net->compute_total_link_histogram();
    @fit = $net->cumulative_power_law_exponent(\%hist);
    @newman = $net->newman_power_law_exponent(\%hist, 2);
    print "    total degree stats:\n";
    if ((defined $fit[0]) and (defined $fit[1])) {
      print "      power law exponent: ", Clair::Util::round_number($fit[0], 2),
        " r-squared: ", Clair::Util::round_number($fit[1], 2), "\n";
      if ($fit[2] < 0.05) {
        print "      likely power law relationship (p = " .
          Clair::Util::round_number($fit[2], 2) . ")\n";
      } else {
        print "      not a power law relationship (p = " .
          Clair::Util::round_number($fit[2], 2) . ")\n";
      }
    }
    if ((defined $newman[0]) and (defined $newman[1])) {
      print "      Newman power law exponent: ",
        Clair::Util::round_number($newman[0], 2),
            ", error: ",  Clair::Util::round_number($newman[1], 2), "\n";
    }
  }
  print "  Strongly connected components: ";

  my @components = $net->find_components();
  my $no = $#components+1;
  print $no,"\n";

  print "  Clustering:\n";
  print "    Watts Strogatz clustering coefficient: ",
    Clair::Util::round_number($net->Watts_Strogatz_clus_coeff(), 4), "\n";
  print "    Newman clustering coefficient";
  if ($verbose) {
    my ($triangles, $triangle_cnt, $triple_cnt) = $net->get_triangles();
    print " (3 * $triangle_cnt triangles / $triple_cnt triples): ";
  } else {
    print ": ";
  }
  print Clair::Util::round_number($net->newman_clustering_coefficient(), 4),
    "\n";

  print "  clairlib avg. ";
  if ($net->{directed}) {
    print "directed";
  } else {
    print "undirected";
  }
  print " shortest path: ",
    Clair::Util::round_number($net->diameter(directed => $net->{directed},
                                             avg => 1), 2), "\n";
  print "  Ferrer avg. ";
  if ($net->{directed}) {
    print "directed";
  } else {
    print "undirected";
  }
  print " shortest path: ",
    Clair::Util::round_number($net->average_shortest_path(), 2), "\n";
  print "  harmonic mean geodesic distance: ",
    Clair::Util::round_number($net->harmonic_mean_geodesic_distance(), 2),"\n";
  print "  harmonic mean geodesic distance with self-loop counted in: ";
   my $hmgd_tmp =  Clair::Util::round_number($net->harmonic_mean_geodesic_distance(), 2);
   my @vertices = $net->get_vertices();
   my $len = $#vertices+1;
   $hmgd_tmp *= ($len+1)/($len-1);
   print $hmgd_tmp, "\n";
  print "  full average shortest path: " ,
        Clair::Util::round_number($net->new_average_shorest_path(), 4), "\n";
  print "Note: (=harmonic mean geodesic distance / (n*(n-1)/2), n is the # of nodes in the network)\n";

  if ($assortativity) {
    print "  Assortativity: ",
      Clair::Util::round_number($net->degree_assortativity_coefficient(), 2), "\n";
  }

  # Print shortest path matrix if requested
  if ($paths) {
    print "  Shortest paths:\n";
    $net->print_asp_matrix(delim => $delim);
#    print "  All paths:\n";
#    foreach my $path ($net->find_all_paths()) {
#      foreach my $v (@$path) {
#        print $v, $delim;
#      }
#      print "\n";
#    }
  }

  # Print strongly connected components if requested
  if ($scc) {
    print " Strongly connected components:\n";
    my @components = ();
    @components = $net->find_components("strongly");
    foreach my $component (@components) {
      print "    ", join($delim, @{$component}), "\n";
    }
  }

  # Print weakly connected components if requested
  if ($wcc) {
    print "  Weakly connected components:\n";
    my @components = ();
    @components = $net->find_components("weakly");
    foreach my $component (@components) {
      print "    ", join($delim, @{$component}), "\n";
    }
  }

  # Print components if requested
  if ($components) {
    print "  Connected components:\n";
    my @components = ();
    @components = $net->find_components("weakly");
    foreach my $component (@components) {
      print "    ", join($delim, @{$component}), "\n";
    }
  }

  # Print triangles if requested
  if ($triangles) {
    my ($triangles, $triangle_cnt, $triple_cnt) = $net->get_triangles(delim => $delim);
    print "  Triangles ($triangle_cnt triangles, $triple_cnt triples):\n";
    foreach my $triangle (@{$triangles}) {
      print "    ", $triangle, "\n";
    }
  }

  if ($localcc) {
    print "  Local clustering coefficient for each connected vertex:\n";
    my %local_cc = $net->Watts_Strogatz_local_clus_coeff();
#    foreach my $v (sort{$a <=> $b} keys %local_cc) {
#      print "$v", $delim, $local_cc{$v}, "\n";
#    }
    my @unsort_v = $net->{graph}->vertices();
    my @v = sort {$a <=> $b} @unsort_v;
    for (my $i = 0; $i <= $#v; $i++) {
            if (! defined $local_cc{$v[$i]}) {
                    print " $v[$i]", $delim, 0, "\n";
            }else {

                    print " $v[$i]", $delim, $local_cc{$v[$i]}, "\n";
            }
    }
  }

}

sub get_adjacency_matrix {
  my $self = shift;
  my %parameters = @_;

  my $directed = $self->{directed};
  if ( (exists $parameters{directed} and $parameters{directed} == 0) ||
       (exists $parameters{undirected} and $parameters{undirected} == 1) ) {
    $directed = 0;
  }

  my %link_hash;

  if ($directed) {
    if (not defined $self->{adjacency_matrix_directed}) {
      $self->compute_adjacency_matrix(directed => $directed);
    }

    %link_hash = %{$self->{adjacency_matrix_directed}};
  } else {
    # undirected network
    if (not defined $self->{adjacency_matrix_undirected}) {
      $self->compute_adjacency_matrix(directed => $directed);
    }
    %link_hash = %{$self->{adjacency_matrix_undirected}};
  }

  return %link_hash;
}

=head2 compute_adjacency_matrix

Compute the adjacency matrix and store it.
This is used by several functions to speed up computations.
The Perl Graph library has slow accessors for nodes/edges if node/edge
properties are used.

=cut

sub compute_adjacency_matrix {
  my $self = shift;
  my $graph = $self->{graph};
  my %parameters = @_;

  my $directed = $self->{directed};
  if ( (exists $parameters{directed} and $parameters{directed} == 0) ||
       (exists $parameters{undirected} and $parameters{undirected} == 1) ) {
    $directed = 0;
  }
  if ($self->{filebased}) {
    my ($fh, $filename) = tempfile(OPEN => 0);
    $self->{adjacency_matrix_file} = $filename;
    tie %{$self->{adjacency_matrix}}, 'MLDBM', $filename
      or die "Couldn't open $filename: $!\n";
  } else {
    %{$self->{adjacency_matrix}} = ();
  }

  # Build adjacency matrix
  # Create return link for undirected graph
  if ($verbose) { print STDERR "Building adjacency matrix\n"; }
  foreach $e ($graph->edges()) {
    my ($from, $to) = @$e;
    my $hash_ref;
    if (not exists $self->{adjacency_matrix}{$from}) {
      $hash_ref = {};
    } else {
      $hash_ref = $self->{adjacency_matrix}{$from};
    }

    $hash_ref->{$to} = 1;
    $self->{adjacency_matrix}{$from} = $hash_ref;

    if ($directed == 0) {
      if (not exists $self->{adjacency_matrix}{$to}) {
        $hash_ref = {};
      } else {
        $hash_ref = $self->{adjacency_matrix}{$to};
      }
      $hash_ref->{$from} = 1;
      $self->{adjacency_matrix}{$to} = $hash_ref;
    }
  }

  if ($directed) {
    %{$self->{adjacency_matrix_directed}} = %{$self->{adjacency_matrix}};
  } else {
    %{$self->{adjacency_matrix_undirected}} = %{$self->{adjacency_matrix}};
  }
}


=head2 get_shortest_path_matrix

Get the shortest path matrix, computing it if necessary

=cut

sub get_shortest_path_matrix {
  my $self = shift;
  my %parameters = @_;


  my $directed = $self->{directed};
  if ( (exists $parameters{directed} and $parameters{directed} == 0) ||
       (exists $parameters{undirected} and $parameters{undirected} == 1) ) {
    $directed = 0;
  }

  # get the cached shortest path matrix
  my $asp_matrix;

  if ($directed) {
    if (not defined $self->{asp_matrix_directed}) {
      $self->compute_asp_matrix(directed => $directed);
    }
    $asp_matrix = $self->{asp_matrix_directed};
  } else {
    if (not defined $self->{asp_matrix_undirected}) {
      $self->compute_asp_matrix(directed => $directed);
    }
    $asp_matrix = $self->{asp_matrix_undirected};
  }

  return $asp_matrix;
}

=head2 compute_asp_matrix

Compute the average shortest path matrix.  This is used by several functions.

=cut

sub compute_asp_matrix {
  my $self = shift;
  my $graph = $self->{graph};
  my %parameters = @_;

  my $directed = $self->{directed};
  if ( (exists $parameters{directed} and $parameters{directed} == 0) ||
       (exists $parameters{undirected} and $parameters{undirected} == 1) ) {
    $directed = 0;
  }

  my %link_hash = $self->get_adjacency_matrix(directed => $directed);

  if ($self->{filebased}) {
    my ($fh, $filename) = tempfile(OPEN => 0);
    $self->{path_length_matrix_filename} = $filename;
    tie %{$self->{path_length_matrix}}, 'MLDBM', $filename
      or die "Couldn't open $filename: $!\n";
  } else {
    %{$self->{path_length_matrix}} = ();
  }

  # traverse the graph
  my $nodes = scalar($self->num_nodes());
  my $edges = scalar($graph->edges());

  if ($verbose) { print STDERR "Building shortest path matrix for $nodes nodes, $edges edges (1 dot = 100,000 paths)\n"; }
  my $dotcount = 0;
  my $hash_ref = {};
  if ($verbose) { print STDERR "Going through " . scalar(keys %link_hash) . " nodes\n"; }
  foreach my $v (keys %link_hash) {
#    if ($verbose) { print STDERR "Exploring $v\n" };
    $self->{path_length_matrix}{$v} = ();
    my @queue = ($v);
    $hash_ref = {};
    $hash_ref->{$v} = 0;
    $self->{path_length_matrix}{$v} = $hash_ref;

    while (@queue) {
      my $next = pop @queue;
      my $d = $self->{path_length_matrix}{$v}{$next} + 1;
      foreach my $n (keys %{$link_hash{$next}}) {
        if (!(exists $self->{path_length_matrix}{$v}{$n})) {
          $hash_ref = $self->{path_length_matrix}{$v};
          $hash_ref->{$n} = $d;
          $self->{path_length_matrix}{$v} = $hash_ref;
          unshift(@queue, $n);
          print STDERR "." if $verbose and !($dotcount++%100000);
        }
      }
    }
  }

  # Make sure to set the path length to itself for any successorless vertices
  foreach my $v ($self->{graph}->successorless_vertices()) {
    if (!(exists $self->{path_length_matrix}{$v})) {
      $self->{path_length_matrix}{$v} = ();
    }
    $self->{path_length_matrix}{$v}{$v} = 0;
  }

  if ($verbose) { print STDERR "\n"; }

  if ($directed) {
    %{$self->{asp_matrix_directed}} = %{$self->{path_length_matrix}};
  } else {
    %{$self->{asp_matrix_undirected}} = %{$self->{path_length_matrix}};
  }
}

=head2 print_asp_matrix

Print the average shortest path matrix

=cut

sub print_asp_matrix {
  my $self = shift;

  my %parameters = @_;

  my $delim = " ";
  if (exists $parameters{delim}) {
    $delim = $parameters{delim};
  }
  my $directed = $self->{directed};

  my $asp_matrix = $self->get_shortest_path_matrix(directed => $directed);
  my %path_length_matrix = %{$asp_matrix};


  my @vertices = sort keys %path_length_matrix;
  my @unsortedvertices = sort keys %path_length_matrix;
  @vertices = sort {$a <=> $b} @unsortedvertices;

  print join($delim, @vertices), "\n";
  foreach my $v1 (@vertices) {
    print $v1;
    foreach my $v2 (@vertices) {
      if (defined $path_length_matrix{$v1}->{$v2}) {
        print $delim, $path_length_matrix{$v1}->{$v2};
      } else {
        print $delim, -1;
      }
    }
    print "\n";
  }
}


=head2 find_all_shortest_paths

Find all pairs of shortest paths

=cut

sub find_all_shortest_paths {
  my $self = shift;
  my %parameters = @_;

  my $graph = $self->{graph};

  my $directed = $self->{directed};
  if ( (exists $parameters{directed} and $parameters{directed} == 0) ||
       (exists $parameters{undirected} and $parameters{undirected} == 1) ) {
    $directed = 0;
  }

  my %link_hash = $self->get_adjacency_matrix(directed => $directed);

  if ($self->{filebased}) {
    my ($fh, $filename) = tempfile(OPEN => 0);
    $self->{ext_path_length_matrix_filename} = $filename;
    tie %{$self->{ext_path_length_matrix}}, 'MLDBM', $filename
      or die "Couldn't open $filename: $!\n";
  } else {
    %{$self->{ext_path_length_matrix}} = ();
  }

  # traverse the graph
  my $nodes = scalar($self->num_nodes());
  my $edges = scalar($graph->edges());

  if ($verbose) { print STDERR "Building shortest path matrix for $nodes nodes, $edges edges (1 dot = 100,000 paths)\n"; }
  my $dotcount = 0;
  my $hash_ref = {};
  if ($verbose) { print STDERR "Going through " . scalar(keys %link_hash) . " nodes\n"; }
  foreach my $v (keys %link_hash) {
    $self->{ext_path_length_matrix}{$v} = ();
    my @queue = ($v);
    $hash_ref = {};
    $hash_ref->{$v} = [[], 0];
    $self->{ext_path_length_matrix}{$v} = $hash_ref;

    while (@queue) {
      my $next = pop @queue;
      my $d = $self->{ext_path_length_matrix}{$v}{$next}[1] + 1;
      foreach my $n (keys %{$link_hash{$next}}) {
        if (exists $self->{ext_path_length_matrix}{$v}{$n}) {
          if ($self->{ext_path_length_matrix}{$v}{$n}[1] <= $d) {
            $hash_ref = $self->{ext_path_length_matrix}{$v};
            my @predecessors = @{$hash_ref->{$n}[0]};
            push @predecessors, $next;
            $hash_ref->{$n} = [\@predecessors, $d];
          }
        } else {
          $hash_ref = $self->{ext_path_length_matrix}{$v};
          $hash_ref->{$n} = [[$next], $d];
          $self->{ext_path_length_matrix}{$v} = $hash_ref;
          unshift(@queue, $n);
          print STDERR "." if $verbose and !($dotcount++%100000);
        }
      }
    }
  }
  if ($verbose) { print STDERR "\n"; }

  return $self->{ext_path_length_matrix};
}

=head2 find_shortest_paths

Find all shortest paths between two nodes

=cut

sub find_shortest_paths {
  my $self = shift;
  my $source = shift;
  my $dest = shift;
  my %parameters = @_;

  my $paths = $self->find_all_shortest_paths(%parameters);

  my @paths = ();
  my @path = ();
  @paths = $self->_find_shortest_paths($paths, $source, $dest, \@path);


  # Reverse paths
  my @new_paths = ();
  foreach my $path (@paths) {
    push @new_paths, [reverse @$path];
  }

  return @new_paths;
}

=head2 _find_shortest_paths

Helper method for find_shortest_paths

=cut

sub _find_shortest_paths {
  my $self = shift;
  my $paths = shift;
  my $start = shift;
  my $end = shift;
  my $p2 = shift;
  my @path = @{$p2};

  push @path, $end;

  if ($start eq $end) {
    return \@path;
  }

  if (not exists $paths->{$start}{$end}) {
    return ();
  }

  my @paths = ();

  if (exists $paths->{$start}{$end}) {
    foreach my $node (@{$paths->{$start}{$end}[0]}) {
      @newpaths = $self->_find_shortest_paths($paths, $start, $node, \@path);
      foreach $path (@newpaths) {
        push @paths, $path;
      }
    }
  }

  return @paths;
}

=head2 find_path_counts

Find all shortest paths, then find the vertex counts in each.

=cut

sub find_shortest_path_counts {
  my $self = shift;

  my %parameters = @_;
  my @b = ();
  my %counts = ();

  # Build the hash of counts
  my @vertices = $self->get_vertices();
  foreach my $v1 (@vertices) {
    foreach my $v2 (@vertices) {
      if ($v1 ne $v2) {
        @b = $self->find_paths($v1, $v2);

        # Now we have all the paths between v1 and v2, find the shortest ones
        my $min = scalar(@vertices) + 1;
        foreach my $path (@b) {
          if (scalar(@{$path}) < $min) {
            $min = scalar(@{$path});
          }
        }

        # Now count how many times each vertex is in a shortest path
        foreach my $path (@b) {
          if (scalar(@{$path}) == $min) {
            foreach my $v (@{$path}) {
              if (exists $counts{$v1}{$v2}{$v}) {
                $counts{$v1}{$v2}{$v} = $counts{$v1}{$v2}{$v} + 1;
              } else {
                $counts{$v1}{$v2}{$v} = 1;
              }
            }
          }
        }
      }
    }
  }

  return \%counts;
}

=head2 get_network_info_as_string

get_network_info_as_string()

Print one line space-seperated summary of network info.
Useful when printing statistics on many networks, subnets, or similar.

Below is a list of the columns returned

nodes number of nodes in the network
edges number of edges in the network
diameter diameter of the network
lcc size of the largest connected component
avg_short_path average shortest path
ferrer_avg_short_path Ferrer i Cancho average shortest path
watts_strogatz_cc Watts-Strogatz clustering coefficient
newman_cc Newman clustering coefficient
in_link_power In-link power-law exponent (calculated from regression)
in_link_power_rsquared In-link power-law rsquared value
in_link_pscore In-link power-law p-score (< 0.005 means fit)
in_link_power_newman In-link power-law exponent Newman formula
in_link_power_newman_error In-link power-law exponent Newman statistical error
out_link_power Out-link power-law exponent (calculated from regression)
out_link_power_rsquared Out-link power-law rsquared value
out_link_pscore Out-link power-law p-score (< 0.005 means fit)
out_link_power_newman Out-link power-law exponent Newman formula
out_link_power_newman_error Out-link power-law exponent Newman statistical error
total_link_power Total-link power-law exponent (calculated from regression)
total_link_power_rsquared Total-link power-law rsquared value
total_link_pscore Total-link power-law p-score (< 0.005 means fit)
total_link_power_newman Total-link power-law exponent Newman formula
total_link_power_newman_error Total-link power-law exponent Newman statistical error
avg_degree average degree

=cut

sub get_network_info_as_string
{
  my $net = shift;
  my $p = shift;
  my @p = @{$p};

  # Setup hash value for faster searching of properties
  my %props = ();
  map { $props{$_} = 1; } @p;

  my %hist = ();
  my $str = "";

  if ($props{"nodes"}) {
    if ($verbose) { print STDERR "Getting number of nodes\n"; }
    $str .= $net->num_nodes() . " ";
  }
  if ($props{"edges"}) {
    if ($verbose) { print STDERR "Getting number of edges\n"; }
    $str .= scalar($net->get_edges()) . " ";
  }
  if ($props{"diameter"}) {
    if ($verbose) { print STDERR "Getting diameter\n"; }
    $str .= $net->diameter(directed => $net->{directed}) . " ";
  }
  if ($props{"lcc"}) {
    if ($verbose) { print STDERR "Finding largest component size\n"; }
    $str .= $net->find_largest_component_size() . " ";
  }
  if ($props{"strongly_connected_components"}) {
    if ($verbose) { print STDERR "print the number of strongly_connected_components\n";}
    my @components = $net->find_components();
  #  my $graph = $net->{graph};
  #  my @vertices = $graph->vertices();
  #  print "#of nodes:",$#vertices+1,"\n";
    my $no = $#components+1;
    $str .= "$no ";
  #  foreach $array( @components) {
  #          print join("|", @$array);
#        print "\n";
 #   }
  }
  if ($props{"avg_short_path"}) {
    if ($verbose) { print STDERR "Getting asp\n"; }
    $str .= Clair::Util::round_number($net->diameter(directed =>
                                                     $net->{directed},
                                                     avg => 1), 2) . " ";
  }
  if ($props{"ferrer_avg_short_path"}) {
    if ($verbose) { print STDERR "Getting Ferrer asp\n"; }
    $str .= Clair::Util::round_number($net->average_shortest_path(), 2) . " ";
  }
  if ($props{"watts_strogatz_cc"}) {
    if ($verbose) { print STDERR "Getting wscc\n"; }
    $str .= Clair::Util::round_number($net->Watts_Strogatz_clus_coeff(), 4) .
      " ";
  }

  if ($props{"hmgd"}) {
    if ($verbose) { print STDERR "Getting hmgd\n"; }
    $str .= Clair::Util::round_number($net->harmonic_mean_geodesic_distance(),
                                      4) . " ";
  }
  if ($props{"full_avsp"}) {
    if ($verbose) { print STDERR "Getting full average shortest path\n"; }
    $str .= Clair::Util::round_number($net->new_average_shorest_path(),
                                      4) . " ";

  }

  if ($props{"newman_cc"}) {
    if ($verbose) { print STDERR "Getting newman cc\n"; }
    $str .= Clair::Util::round_number($net->newman_clustering_coefficient(), 4) . " ";
  }

  if ($props{"in_link_power"} or $props{"in_link_power_rsquared"} or
      $props{"in_link_power_pscore"} or $props{"in_link_power_newman"} or
      $props{"in_link_power_newman_error"}) {
    %hist = $net->compute_in_link_histogram();
    if ($props{"in_link_power"} or $props{"in_link_power_rsquared"} or
        $props{"in_link_power_pscore"}) {
      my @fit = cumulative_power_law_exponent($net, \%hist);
      if (defined $fit[0] and defined $fit[1]) {
        if ($props{"in_link_power"}) {
          $str .= Clair::Util::round_number($fit[0], 2) . " ";
        }
        if ($props{"in_link_power_rsquared"}) {
          $str .= Clair::Util::round_number($fit[1], 2) . " ";
        }
        if ($props{"in_link_pscore"}) {
          $str .= Clair::Util::round_number($fit[2], 2) . " ";
        }
      } else {
        if ($props{"in_link_power"}) {
          $str .= "0 ";
        }
        if ($props{"in_link_power_rsquared"}) {
          $str .= "0 ";
        }
        if ($props{"in_link_pscore"}) {
          $str .= "0 ";
        }
      }
    }
    if ($props{"in_link_power_newman"} or
        $props{"in_link_power_newman_error"}) {
      my @newman = $net->newman_power_law_exponent(\%hist, 2);
      if ((defined $newman[0]) and (defined $newman[1])) {
        if ($props{"in_link_power_newman"}) {
          $str .= Clair::Util::round_number($newman[0], 2) . " ";
        }
        if ($props{"in_link_power_newman_error"}) {
          $str .- Clair::Util::round_number($newman[1], 2) . " ";
        }
      } else {
        if ($props{"in_link_power_newman"}) {
          $str .= "0 ";
        }
        if ($props{"in_link_power_newman_error"}) {
          $str .= "0 ";
        }
      }
    }
  }

  if ($props{"out_link_power"} or $props{"out_link_power_rsquared"} or
      $props{"out_link_pscore"} or $props{"out_link_power_newman"} or
      $props{"out_link_power_newman_error"}) {
    if ($props{"out_link_power"} or $props{"out_link_power_rsquared"} or
        $props{"out_link_pscore"}) {
      %hist = $net->compute_out_link_histogram();
      my @fit = cumulative_power_law_exponent($net, \%hist);
      if (defined $fit[0] and defined $fit[1]) {
        if ($props{"out_link_power"}) {
          $str .= Clair::Util::round_number($fit[0], 2) . " ";
        }
        if ($props{"out_link_power_rsquared"}) {
          $str .= Clair::Util::round_number($fit[1], 2) . " ";
        }
        if ($props{"out_link_pscore"}) {
          $str .= Clair::Util::round_number($fit[2], 2) . " ";
        }
      } else {
        if ($props{"out_link_power"}) {
          $str .= "0 ";
        }
        if ($props{"out_link_power_rsquared"}) {
          $str .= "0 ";
        }
        if ($props{"out_link_pscore"}) {
          $str .= "0 ";
        }
      }
    }

    if ($props{"out_link_power_newman"} or
        $props{"out_link_power_newman_error"}) {
      my @newman = $net->newman_power_law_exponent(\%hist, 2);

      if ((defined $newman[0]) and (defined $newman[1])) {
        if ($props{"out_link_power_newman"}) {
          $str .= Clair::Util::round_number($newman[0], 2) . " ";
        }
        if ($props{"out_link_power_newman_error"}) {
          $str .= Clair::Util::round_number($newman[1], 2) . " ";
        }
      } else {
        if ($props{"out_link_power_newman"}) {
          $str .= "0 ";
        }
        if ($props{"out_link_power_newman_error"}) {
          $str .= "0 ";
        }
      }
    }
  }

  if ($props{"total_link_power"} or $props{"total_link_power_rsquared"} or
      $props{"total_link_pscore"} or $props{"total_link_power_newman"} or
      $props{"total_link_power_newman_error"}) {
    if ($props{"total_link_power"} or $props{"total_link_power_rsquared"} or
        $props{"total_link_pscore"}) {
      %hist = $net->compute_total_link_histogram();
      my @fit = cumulative_power_law_exponent($net, \%hist);
      if (defined $fit[0] and defined $fit[1]) {
        if ($props{"total_link_power"}) {
          $str .= Clair::Util::round_number($fit[0], 2) . " ";
        }
        if ($props{"total_link_power_rsquared"}) {
          $str .= Clair::Util::round_number($fit[1], 2) . " ";
        }
        if ($props{"total_link_pscore"}) {
          $str .= Clair::Util::round_number($fit[2], 2) . " ";
        }
      } else {
        if ($props{"total_link_power"}) {
          $str .= "0 ";
        }
        if ($props{"total_link_power_rsquared"}) {
          $str .= "0 ";
        }
        if ($props{"total_link_pscore"}) {
          $str .= "0 ";
        }
      }
    }

    if ($props{"total_link_power_newman"} or
        $props{"total_link_power_newman_error"}) {
      my @newman = $net->newman_power_law_exponent(\%hist, 2);

      if ((defined $newman[0]) and (defined $newman[1])) {
        if ($props{"total_link_power_newman"}) {
          $str .= Clair::Util::round_number($newman[0], 2) . " ";
        }
        if ($props{"total_link_power_newman_error"}) {
          $str .= Clair::Util::round_number($newman[1], 2) . " ";
        }
      } else {
        if ($props{"total_link_power_newman"}) {
          $str .= "0 ";
        }
        if ($props{"total_link_power_newman_error"}) {
          $str .= "0 ";
        }
      }
    }
  }

  if ($props{"avg_degree"}) {
    $str .= Clair::Util::round_number($net->{graph}->average_degree(), 2);
  }
  return $str;
}

=head2 cumulative_power_law_exponent

cumulative_power_law_exponent(\%histogram)

Calculate the power law exponent from the cumulative distribution

=cut

sub cumulative_power_law_exponent {
  my $self = shift;
  my $h = shift;
  my %hist = %{$h};

  my %cum_hist = $self->get_cumulative_distribution(\%hist);
  my @fit = $self->linear_regression(\%cum_hist, log => 1);
  my $n = scalar keys %cum_hist;
  # Get the p-score to test if the regression doesn't fit
  my $p_score = $self->get_p_score($n, \@fit);

  if (defined $fit[0] and defined $fit[1]) {
    $fit[0] = 1 - $fit[0];
    $fit[1] = $fit[1]**2;
  }
  $fit[2] = $p_score;

  return @fit;
}

=head2 get_p_score

Calculate the p score
TODO: Move this into the statistics package

=cut

sub get_p_score {
  my $self = shift;
  my $n = shift;
  my $arr = shift;
  my ($coef, $r) = @{$arr};

  my $r_squared = $r**2;

  my $df = 1;
  if ($n > 2) {
    $df = $n - 2;
  } else {
    return 10;
  }
  if ((1 - $r_squared) < 0.0001) {
    return 10;
  }
  my $sr = sqrt((1 - $r_squared) / $df);
  if ($sr == 0) {
    return 10;
  }
  my $t = $r / $sr;
  my $tdist = Clair::Statistics::Distributions::TDist->new();
  my $t_prob = $tdist->get_prob($df, $t) * 2;

  return $t_prob;
}


=head2 newman_clustering_coefficient

newman_clustering_coefficient()

Calculate the Newman clustering coefficient of a graph.
Uses formula 3 in Newman's "Structure and Function of Complex Networks"

=cut

sub newman_clustering_coefficient
{
  my $self = shift;
  my $graph = $self->{graph};

  my %parameters = @_;
  my %link_hash;

  %link_hash = $self->get_adjacency_matrix(directed => 0);

  my $skipped = 0;

  my $triples = 0;
  my $triangles = 0;

  my @vertex_keys = keys %link_hash;
  my %neis = ();

  foreach my $k (0..$#vertex_keys) {
    my $v = $vertex_keys[$k];
    my $deg = 0;
    my @neighbors;

    if (exists $link_hash{$v}) {
      @neighbors = keys %{$link_hash{$v}};
      if (@neighbors > 1) {
        if (@neighbors > 5000) {
          $skipped++;
          next;
        }

        # mark the neighbors of $v
        foreach my $n1 (0..$#neighbors) {
          $neis{$neighbors[$n1]} = ($k + 1);
          $deg++;
        }
        $triples += ($deg * ($deg - 1)) / 2;

        # count the triangles
        foreach my $n1 (0..$#neighbors) {
          # get neighbors of this neighbor
          my @neighbors2 = keys %{$link_hash{$neighbors[$n1]}};
          foreach my $n2 (0..$#neighbors2) {
            if (exists $neis{$neighbors2[$n2]}) {
              if ($neis{$neighbors2[$n2]} == ($k + 1)) {
                $triangles++;
              }
            }
          }
        }
      }
    }
  }

  if ($triples == 0) {
        return 0;
  }
  return ($triangles / 2) / $triples;
}

=head2 get_triangles

get_triangles()

Return all of the triangles in the network

=cut

sub get_triangles
{
  my $self = shift;
  my $graph = $self->{graph};

  my %parameters = @_;
  my %link_hash;

  my $delim = "-";
  if (exists $parameters{delim}) {
    $delim = $parameters{delim};
  }

  # convert to undirected
  foreach my $e ($graph->edges) {
    my $u;
    my $v;

    ($u, $v) = @$e;

    if ($u ne $v) {
      $link_hash{$u}{$v} = 1;
      $link_hash{$v}{$u} = 1;
    }
  }

  my $skipped = 0;

  my $triples = 0;
  my $triangles = 0;

  my @vertex_keys = keys %link_hash;
  my %neis = ();
  my %all_triangles = ();       # Set of all triangles in the network

  foreach my $k (0..$#vertex_keys) {
    my $v = $vertex_keys[$k];
    my $deg = 0;
    my @neighbors;

    if (exists $link_hash{$v}) {
      @neighbors = keys %{$link_hash{$v}};
      if (@neighbors > 1) {
        if (@neighbors > 5000) {
          $skipped++;
          next;
        }

        # mark the neighbors of $v
        foreach my $n1 (0..$#neighbors) {
          $neis{$neighbors[$n1]} = ($k + 1);
          $deg++;
        }
        $triples += ($deg * ($deg - 1)) / 2;

        # count the triangles
        my @triangle = ();
        foreach my $n1 (0..$#neighbors) {
          # get neighbors of this neighbor
          my @neighbors2 = keys %{$link_hash{$neighbors[$n1]}};
          foreach my $n2 (0..$#neighbors2) {
            if (exists $neis{$neighbors2[$n2]}) {
              if ($neis{$neighbors2[$n2]} == ($k + 1)) {
                @triangle = ($v, $neighbors2[$n2], $neighbors[$n1]);
                # Add the triangle
                if (@triangle) {
                        @triangle = sort @triangle;
                        my $triangle = $triangle[0] . $delim . $triangle[1] . $delim .
                                $triangle[2];
                        if (not exists $all_triangles{$triangle}) {
                                $all_triangles{$triangle} = 1;
                        }
                }
                $triangles++;
              }
            }
          }
        }

      }
    }
  }

  my @tri = keys %all_triangles;
  return (\@tri, $triangles / 6, $triples);
}



=head2 create_network_from_cosines

create_network_from_cosines($threshold)

Return a new network with with edges >= threshold

=cut

sub create_network_from_cosines {
  my $self = shift;
  my $graph = $self->{graph};
  my $threshold = shift;
  my %params = @_;

  my $reverse = 0;
  if (exists $params{reverse}) {
    $reverse = $params{reverse};
  }
  if ((not defined $self->{sorted_edges}) or
      ($self->{sorted_edges_order} != $reverse)) {
    $self->sort_edges(reverse => $reverse);
  }

  my $new_net = new Clair::Network(directed => $self->{directed},
                                   unionfind => 1);
  my $new_graph = $new_net->{graph};

  # add all of the nodes
  foreach my $v ($self->get_vertices()) {
    $new_graph->add_vertex($v);
  }

  foreach my $key (@{$self->{sorted_edges}}) {
    my $edge = $self->{myedges}->[$key];
    my $w = $self->{weights}->{$key};
    if (($reverse and ($w <= $threshold)) or
        (not $reverse and ($w >= $threshold))) {
      my ($u, $v) = @{$edge};
      $new_graph->add_edge($u, $v);
      $new_graph->set_edge_weight($u, $v, $w);
    } else {
      last;
    }
  }


  return $new_net;
}

=head2 create_cosine_network

create_cosine_network(\@edges)

Create a network with nodes being documents and edge weights cosine values
for the documents.

=cut

sub create_cosine_network {
  my $self = shift;
  my $e = shift;
  my @edges = @{$e};

  my $net = new Clair::Network(undirected => 1);

  foreach my $edge (@edges) {
    my ($u, $v, $w) = @{$edge};
    $net->add_edge($u, $v);
    $net->set_edge_weight($u, $v, $w);
  }

  return $net;
}

=head2 import_from_pajek()

import_from_pajek($filename)

Create a network from a pajek .net file.
Example:   $network = Clair::Network->import_from_pajek($filename);

=cut

sub import_from_pajek {
  my $class = shift;

  my $filename = shift;

  my %parameters = @_;

  printf STDERR "export_to_Pajek is deprecated, please use ";
  printf STDERR "Clair::Network::Writer::Pajek\n";

  my $reader = Clair::Network::Reader::Pajek->new();
  my $net = $reader->read_network($filename);

  return $net;
}

=head2 import_network

import_network($filename)

Load in a network from a file.  File should be in edge edge format or
edge edge weight.
Parameters:
delim is the edge delimiter used in the file
sample is used to take a uniform random sample of the edges
directed and undirected indicate whether the graph should be directed or
undirected.  The default is directed.

=cut

sub import_network {
  my $class = shift;
  my $filename = shift;

  printf STDERR "import_network is deprecated, please use ";
  printf STDERR "Clair::Network::Reader::Edgelist\n";

  my $reader = Clair::Network::Reader::Edgelist->new();
  my $net = $reader->read_network($filename, @_);

  return $net;
}


=head2 create_network_from_array


=cut

sub create_network_from_array {
  my $class = shift;

  my $edges_ref = shift;
  my @edges = @$edges_ref;

  my %parameters = @_;

  my $property = '';
  if (exists $parameters{property}) {
    $property = $parameters{property};
  }

  my $directed = 1;
  if ((exists $parameters{directed} and $parameters{directed} == 0) ||
      (exists $parameters{undirected} and $parameters{undirected} == 1)) {
    $directed = 0;
  }

  my $self = new Clair::Network(directed => $directed);

  foreach my $h (@edges) {
    my ($u_id, $v_id) = @$h;

    my $add_u = $u_id;
    my $add_v = $v_id;

    if ((defined $add_u) and (defined $add_v)) {
      if (not $self->has_node($add_u)) {
        $self->add_node($add_u);
      }

      if ($u_id ne $v_id) {
        if (not $self->has_node($add_v)) {
          $self->add_node($add_v);
        }

        $self->add_edge($add_u, $add_v);
        if ($property ne "") {
          $self->set_edge_attribute($add_u, $add_v, $property, 1);
        }
      } else {
        $self->add_node($add_u);

        if ($property ne "") {
          $self->set_vertex_attribute($add_u, $property, 1);
        }
      }
    }
  }

  return $self;
}

=head2 get_shortest_path_length

get_shortest_path_length($vertex1, $vertex2)

Return the length of the shortest path between two nodes.

=cut

sub get_shortest_path_length
{
  my $self = shift;
  my $v1 = shift;
  my $v2 = shift;

  my $graph = $self->{graph};

  my %parameters = @_;

  my $directed = $self->{directed};

  if ( (exists $parameters{directed} and $parameters{directed} == 0) ||
       (exists $parameters{undirected} and $parameters{undirected} == 1) ) {
    $directed = 0;
  }

  my $weighted = 0;
  if ((exists $parameters{weighted} and $parameters{weighted} == 1) ||
      (exists $parameters{unweighted} and $parameters{unweighted} == 0)) {
    $weighted = 1;
  }

  if ($weighted) {
    # use Dijkstra's algorithm
    my $g;
    if ($directed == 0) {
      $g = $graph->undirected_copy_graph;
    } else {
      $g = $graph;
    }
    my @path = $g->SP_Dijkstra($v1, $v2);
    my $len = scalar(@path);
    if ($len == 0) {
      return undef;
    } else {
      return $len - 1;
    }
  } else {
    # Unweighted, breadth first search will work
    my %link_hash;

    # Build adjacency matrix
    # Create return link for undirected graph
    foreach $e ($graph->edges) {
      my ($from, $to) = @$e;

      $link_hash{$from}{$to} = 1;

      if ($directed == 0) {
        $link_hash{$to}{$from} = 1;
      }
    }
    if ($v1 eq $v2) {
      return 0;
    }

    my %distance = ();
    my @queue = ($v1);
    $distance{$v1} = 0;

    while (@queue) {
      my $next = pop @queue;
      my $d = $distance{$next} + 1;
      foreach my $n (keys %{$link_hash{$next}}) {
        if ($v2 eq $n) {
          return $d;
        }
        if (!(exists $distance{$n})) {
          $distance{$n} = $d;
          unshift(@queue, $n);
        }
      }
    }

    return $distance{$v2};
  }
}


=head2 get_shortest_paths_lengths

get_shortest_paths_lengths($vertex)

Return the shortest paths between vertex1 and the rest of the graph.  This is
returned as a hash with the keys being vertices and the values the distance
to that vertex.

=cut

sub get_shortest_paths_lengths
{
  my $self = shift;
  my $v1 = shift;

  my $graph = $self->{graph};

  my %parameters = @_;

  my $directed = $self->{directed};

  if ( (exists $parameters{directed} and $parameters{directed} == 0) ||
       (exists $parameters{undirected} and $parameters{undirected} == 1) ) {
    $directed = 0;
  }

  my %link_hash;

  %link_hash = $self->get_adjacency_matrix();

  my %distance = ();
  my @queue = ($v1);
  $distance{$v1} = 0;

  while (@queue) {
    my $next = pop @queue;
    my $d = $distance{$next} + 1;
    foreach my $n (keys %{$link_hash{$next}}) {
      if (!(exists $distance{$n})) {
        $distance{$n} = $d;
        unshift(@queue, $n);
      }
    }
  }

  return %distance;
}

=head2 find_all_paths

find all paths between all pairs of vertices

=cut

sub find_all_paths {
  my $self = shift;

  my $graph = $self->{graph};

  my %parameters = @_;

  my $directed = $self->{directed};

  if ( (exists $parameters{directed} and $parameters{directed} == 0) ||
       (exists $parameters{undirected} and $parameters{undirected} == 1) ) {
    $directed = 0;
  }

  my $weighted = 0;
  if ((exists $parameters{weighted} and $parameters{weighted} == 1) ||
      (exists $parameters{unweighted} and $parameters{unweighted} == 0)) {
    $weighted = 1;
  }

  # use the path length matrix to determine if there is a path between two
  # vertices
  my $asp_matrix = $self->get_shortest_path_matrix(directed => $directed);
  my %path_length_matrix = %{$asp_matrix};

  # Unweighted, breadth first search will work
  my %link_hash;

  %link_hash = $self->get_adjacency_matrix();

  my @paths = ();
  foreach my $v1 (keys %path_length_matrix) {
    foreach my $v2 (keys %{$path_length_matrix{$v1}}) {
      my @path = ();
      push @paths, $self->_find_paths(\%link_hash, $v1, $v2, \%path, \@path);
    }
  }

  return @paths;
}

=head2 find_paths

@paths = find_paths($v1, $v2)

Find all paths between $v1 and $v2

=cut

sub find_paths {
  my $self = shift;
  my $v1 = shift;
  my $v2 = shift;

  my $graph = $self->{graph};

  my %parameters = @_;

  my $directed = $self->{directed};

  if ( (exists $parameters{directed} and $parameters{directed} == 0) ||
       (exists $parameters{undirected} and $parameters{undirected} == 1) ) {
    $directed = 0;
  }

  my $weighted = 0;
  if ((exists $parameters{weighted} and $parameters{weighted} == 1) ||
      (exists $parameters{unweighted} and $parameters{unweighted} == 0)) {
    $weighted = 1;
  }

  # Unweighted, breadth first search will work
  my %link_hash;

  %link_hash = $self->get_adjacency_matrix();

  if ($v1 eq $v2) {
    return ();
  }

  my @paths = ();
  my @path = ();
  @paths = $self->_find_paths(\%link_hash, $v1, $v2, \%path, \@path);

  return @paths;
}

=head2 _find_paths

Private helper method to find paths

=cut

sub _find_paths {
  my $self = shift;
  my $lh = shift;
  my %link_hash = %{$lh};
  my $start = shift;
  my $end = shift;
  my $p = shift;
  my %path = %{$p};
  my $p2 = shift;
  my @path = @{$p2};

  $path{$start} = 1;
  push @path, $start;

  if ($start eq $end) {
    return \@path;
  }
  if (not exists $link_hash{$start}) {
    return ();
  }
  my @paths = ();

  foreach my $node (keys %{$link_hash{$start}}) {
    if (!(exists $path{$node})) {
      @newpaths = $self->_find_paths(\%link_hash, $node, $end, \%path, \@path);
      foreach $path (@newpaths) {
        push @paths, $path;
      }
    }
  }

  return @paths;
}

=over

=item degree

degree($vertex)

Return the degree of a vertex.  For undirected graphs, this is the total
degree.  For directed graphs this is in-degree minus out-degree.

=back

=cut

sub degree {
  my $self = shift;
  my $v = shift;

  return $self->{graph}->degree($v);
}

=item in_degree

in_degree($vertex)

Return the indegree of a vertex

=cut

sub in_degree {
  my $self = shift;
  my $v = shift;

  return $self->{graph}->in_degree($v);
}

=item out_degree

out_degree($vertex)

Return the outdegree of a vertex

=cut

sub out_degree {
  my $self = shift;
  my $v = shift;

  return $self->{graph}->out_degree($v);
}

=item total_degree

total_degree($vertex)

Return the total degree of a vertex

=cut

sub total_degree {
  my $self = shift;
  my $v = shift;

  return $self->{graph}->in_degree($v) + $self->{graph}->out_degree($v);
}

=item degree_assortativity_coefficient

Return the assortavity coefficient for mixing by vertex degree.

Directed:
Newman, Mixing patterns in networks, eq. 26

Undirected:
Newman, Assortative mixing in networks, eq. 4

=cut

sub degree_assortativity_coefficient {
  my $self = shift;
  my $graph = $net->{graph};

  my $num_edges = scalar ($self->get_edges);
  if ($num_edges == 0) {
    return 0;
  }
  my $m = 1 / $num_edges;



  my $sum_jk = 0;
  my $sum_j = 0;
  my $sum_k = 0;
  my $sum_j_squared = 0;
  my $sum_k_squared = 0;
  my $r = 0;
  if ($self->{directed}) {
    # network is directed
    foreach my $edge ($self->get_edges) {
      my ($u, $v) = @{$edge};
      my $j_i = $self->out_degree($u) - 1;
      my $k_i = $self->in_degree($v) - 1;
      $sum_j += $j_i;
      $sum_k += $k_i;
      $sum_jk += $j_i * $k_i;
      $sum_j_squared += $j_i * $j_i;
      $sum_k_squared += $k_i * $k_i;
    }
    #print "sum_j: $sum_j, sum_k: $sum_k\n";
    if ($sum_k == 0 || ($sum_j_squared - $m * ($sum_j * $sum_j)) * ($sum_k_squared - $m * ($sum_k * $sum_k)) == 0) {
      return 0;
    }
    $r = ($sum_jk - ($m * $sum_j * $sum_k)) /
      sqrt(($sum_j_squared - $m * ($sum_j * $sum_j)) *
           ($sum_k_squared - $m * ($sum_k * $sum_k)));
  } else {
    # network is undirected
    my $sum_j_plus_k = 0;
    my $sum_j_plus_k_squared = 0;
    foreach my $edge ($self->get_edges) {
      my ($u, $v) = @{$edge};
      my $j_i = $self->degree($u) - 1;
      my $k_i = $self->degree($v) - 1;
      $sum_j += $j_i;
      $sum_k += $k_i;
      $sum_jk += $j_i * $k_i;
      $sum_j_plus_k += ($j_i + $k_i) / 2;
      $sum_j_plus_k_squared += (($j_i * $j_i) + ($k_i * $k_i)) / 2;
    }
    my $part = ($m * $sum_j_plus_k) * ($m * $sum_j_plus_k);
    if ((($m * $sum_j_plus_k_squared) - $part) == 0) {
            $r = 0;
    } else {
            $r = ($m * $sum_jk - $part) / (($m * $sum_j_plus_k_squared) - $part);
    }

  }

  return $r;
}

=head2 clear_cache

Clear cached objects such as asp matrix

=cut

sub clear_cache {
  my $self = shift;

  # undef the adjacency matrix
  undef $self->{adjacency_matrix_undirected};
  undef $self->{adjacency_matrix_directed};
  undef $self->{adjacency_matrix};

  # undef the average shortest path matrix
  undef $self->{asp_matrix_undirected};
  undef $self->{asp_matrix_directed};

  # undef the cached edge weights
  undef $self->{sorted_edges};
  undef $self->{sorted_edges_order};
  undef $self->{weights};
  undef $self->{myedges};
}

=head2 sort_edges

Cache a list of edges sorted by weight

=cut

sub sort_edges {
  my $self = shift;
  my %params = @_;

  my $reverse = 0;
  if (exists $params{reverse}) {
    $reverse = $params{reverse};
  }
  my @sorted = ();

  my $graph = $self->{graph};

  my $cnt = 0;
  my @edges = ();
  my %weights = ();

  if ((not defined $self->{sorted_edges}) or
      ($self->{sorted_edges_order} != $reverse)) {
    $self->{sorted_edges} = $graph->edges;
    $self->{sorted_edges_order} = $reverse;
    foreach my $edge ($graph->edges) {
      my ($u, $v) = @{$edge};
      if ($graph->has_edge_weight($u, $v)) {
        $edges[$cnt] = dclone($edge);
        $weights{$cnt} = $graph->get_edge_weight($u, $v);
      }
      $cnt++;
    }

    if ($reverse) {
      @sorted = sort { $weights{$a} <=> $weights{$b} } keys %weights;
    } else {
      @sorted = sort { $weights{$b} <=> $weights{$a} } keys %weights;
    }

    @{$self->{myedges}} = @edges;
    @{$self->{sorted_edges}} = @sorted;
    %{$self->{weights}} = %weights;
  }
}

sub compute_lexrank {
  my $self = shift;

  print STDERR "Clair::Network::compute_lexrank is deprecated\n";
  print STDERR "Please use Clair::Network::Centrality::LexRank\n";
}


1;

