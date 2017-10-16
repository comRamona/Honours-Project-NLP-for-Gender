package Clair::Network::GirvanNewman;

use Clair::Network;

@ISA = qw(Clair::Network);
=head1 NAME

Clair::Network::KrenighanLin - Network module implemented the Krenighan-Lin algorithm

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

my $fileName = "karate.gml";
my $reader = Clair::Network::Reader::GML->new();
my $net = $reader->read_network($fileName);

my $GN = new Clair::Network::GirvanNewman($net);
my $graphPartition = $GN->partition();

# $graphPartition is a hash with node id as key and partition number as value
# Partition: the hierarchy structure for each node is represented as 0|1|2|1|....
# so the number between "|" is the partition the node belongs to in a specific hierachy
# if you want to get the bi-parititon of the node, call

$str = $$garphPartition{$node1};

print $str,"\n";
@p = split(/\|/, $str);

return $p[1];


=head1 METHODS

=cut

=head2 new

$GN = new Clair::Network::GirvanNewman($network);

Load the graph needed to be partitioned (the Clair::Network object)

=cut
sub new {
    my $class = shift;
    my $self = shift;

    bless($self, $class);
    return $self;
}

=head2 partition

$GN->partition();

run the algorithm and return the partition result as a hash.

=cut

=head1 AUTHOR

Chen Huang << <clair at umich.edu> >>

=cut

sub partition {
    my $self = shift;
    my $g = $self->{graph};
    $g = $self->get_undirected_graph($g);

    my @nodes = $g->vertices();
    my %id_by_node;
    for ($i = 0; $i <= $#nodes; $i++) {
        $id_by_node{$nodes[$i]} = $i;
    }
    my %graphPartition = ();
    for ($i = 0; $i <= $#nodes; $i++) {
        $graphPartition{$nodes[$i]} = 0;
    }
    my $prevNo = 0;

    my $iteration=0;
    while(1) {
        $iteration++;
        $NOedges = $g->edges;
        last if ($NOedges == 0);

        my $apsp = $g->APSP_Floyd_Warshall();
        my $maxScore = 0;
        my $maxI = 0;
        my $maxJ = 0;
        my $edgeScore = ();

        for ($i = 0; $i <= $#nodes; $i++) {
            for ($j = $i+1; $j <= $#nodes; $j++) {
                my @path = $apsp->path_vertices($nodes[$i], $nodes[$j]);
                for ($k = 1; $k <= $#path; $k++) {
                    $edgeScore->[$id_by_node{$path[$k-1]}]->[$id_by_node{$path[$k]}] += 1;
                    if ($edgeScore->[$id_by_node{$path[$k-1]}]->[$id_by_node{$path[$k]}] > $maxScore) {
                        $maxI = $id_by_node{$path[$k-1]};
                        $maxJ = $id_by_node{$path[$k]};
                        $maxScore = $edgeScore->[$id_by_node{$path[$k-1]}]->[$id_by_node{$path[$k]}];
                    }
                }
            }
        }

        $g = $g->delete_edge($nodes[$maxI], $nodes[$maxJ]);
        print "Interation $iteration : Removed edge ($nodes[$maxI], $nodes[$maxJ])\n" if Clair::Network::verbose;
        if ($g->is_connected != 1) {
            @cc = $g->connected_components();
            if ($prevNo != $#cc) {
                for ($i = 0; $i <= $#cc; $i++) {
                    my @cc1 = @{$cc[$i]};
                    for ($j = 0; $j <= $#cc1; $j++) {
                        #print  $cc1[$j]," ";
                        $graphPartition{$cc1[$j]} = $graphPartition{$cc1[$j]}."|".$i;
                    }
                }
                $prevNo = $#cc;
            }
        }

    }

    return \%graphPartition;
}
1;
