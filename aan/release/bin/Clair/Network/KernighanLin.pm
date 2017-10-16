package Clair::Network::KernighanLin;

use Clair::Network;

@ISA = qw(Clair::Network);
=head1 NAME

Clair::Network::KrenighanLin - Network module implemented the Krenighan-Lin algorithm

=head1 VERSION

Version 0.01

=cut
$VERSION = 0.01;
=head1 SYNOPSIS

my $fileName = "karate.gml";
my $reader = Clair::Network::Reader::GML->new();
my $net = $reader->read_network($fileName);

my $KL = new Clair::Network::KernighanLin($net);

$graphPartition = $KL->generatePartition();

#graphPartiton is a hash with node id as key and partition number 0/1 as value.
# structure of $graphPartition
$graphPartition = {
1 => 1,
2 => 1,
3 => 1,
4 => 0,
...
};

=head1 METHODS

=cut

=head2 new

$KL = new Clair::Network::KernighanLin($network);

Load the graph needed to be partitioned (the Clair::Network object).

=cut

=head2 generatePartition

run the KernighanLin algorithm and generate the partition.

=cut

=head2 Alllocked

private method, used to check if all nodes have been exchanged.

=cut

=head2 getAllcost

private method, used to intialize all algorithms' parameters.

=cut

=head1 AUTHOR

Chen Huang << <clair at umich.edu> >>

=cut

sub new {
    my $class = shift;
    my $self = shift;
    $self->{graph} = $self->get_undirected_graph($self->{graph});
    bless($self, $class);
    return $self;
}

sub generatePartition {
    my $self = shift;
    # read in the number of partition needed
    $self->{numberOfPartitions} = shift;

    # now I need to get the weight matrix for all edges.
    # first get all nodes
    my @vertices =  $self->get_vertices();
    my $nodes = \@vertices;

    my @edges = $self->get_edges();
    $self->{edges} = \@edges;

    my $nodePartition = {};
    my $nodeStatus = {};
    my $size = $#$nodes+1;
    $self->{nodes} = $nodes;


    # initilaize all variables
    for (my $i = 0; $i < $size; $i++) {
            $$nodePartition{$$nodes[$i]} = "" if (! exists $$nodePartition{$$nodes[$i]});
        if ($i%2 != 0) {
            $$nodePartition{$$nodes[$i]} = 0;#$$nodePartition{$$nodes[$i]}.0;
            $value0 = $$nodePartition{$$nodes[$i]};
        }
        else {
            $$nodePartition{$$nodes[$i]} = 1;#$$nodePartition{$$nodes[$i]}.1;
            $value1 = $$nodePartition{$$nodes[$i]};
        }
        $$nodeStatus{$$nodes[$i]} = 0;
    }
         #use Data::Dumper;
         #print "Status ",Dumper($nodeStatus);

    if($Clair::Network::verbose){
        print "Initial node assignments (50 per cent at random)\n";
        foreach my $n (0...$#$nodes){
                printf "%4s  %2s\n",$$nodes[$n],$$nodePartition{$$nodes[$n]};
        }
    }
    my $k=1;
    while (1) {
        my $EC = {};
        my $IC = {};
        my $D = {};
        my @s = ();
        my @t = ();
        my @g = ();
        my $maxI;
        my $maxJ;
        my $maxG;
        my $nodeStatus = {};

        # unlock all nodes
        for (my $i = 0;  $i < $size; $i++) {
            $$nodeStatus{$$nodes[$i]} = 0;
        }


        # get all cost based on current partition
        $self->getAllCost($EC, $IC, $D, $nodePartition);


         #print Dumper($nodePartition);
        while ($self->AllLocked($nodeStatus) == 0) {
            $maxI = 0;
            $maxJ = 0;
            $maxG = -10000;
            my $cost =0;
            foreach $node1(@vertices) {
                next if ($$nodePartition{$node1} == $value1);
                next if ($$nodeStatus{$node1} == -1);
                foreach $node2(@vertices) {
          #          print "N1 $node1  N2 $node2 \n";
                    next if($$nodePartition{$node2} == $value0);
                    next if ($$nodeStatus{$node2} == -1);
                    my $g = $$D{$node1} + $$D{$node2} - 2*($self->get_edge_weight($node1, $node2));
                    if ($g > $maxG) {
                        $maxI = $node1;
                        $maxJ = $node2;
          #              print "maxI $maxI   maxJ $maxJ\n";
                        $maxG = $g;
                    }
                }
            }

            push(@s, $maxI);
            push(@t, $maxJ);
            push(@g, $maxG);
            $$nodeStatus{$maxI} = $$nodeStatus{$maxJ} = -1;
#            print "maxI $maxI   maxJ $maxJ\n";
            #update all other nodes:
            foreach $node (keys %$nodeStatus) {
                if ($$nodeStatus{$node} == -1) {
                    next;
                }
                if($$nodePartition{$node} == $value0) {
                    $$D{$node} = $$D{$node} + 2*($self->get_edge_weight($node,$maxI)) - 2*($self->get_edge_weight($node,$maxJ));
                }

                if($$nodePartition{$node} == $value1) {
                    $$D{$node} = $$D{$node} + 2*($self->get_edge_weight($node,$maxJ)) - 2*($self->get_edge_weight($node, $maxI));
                }

            }
        }
        my $sum = 0;
        my $maxSum = -100000;
        my $maxPair = 0;

        for (my $i = 0; $i < $#g; $i++) {
            $sum += $g[$i];
            if ($sum > $maxSum) {
                $maxSum = $sum;
                $maxPair = $i;
            }
        }

        if ($maxSum > 0) {
            print "===== iteration $k =====\n" if $Clair::Network::verbose;
            for ($i = 0; $i <= $maxPair; $i++) {
                $$nodePartition{$s[$i]} = $value1;
                printf "Node: %5s  Partition: %4s\n",$s[$i],$value1+1 if $Clair::Network::verbose;
                $$nodePartition{$t[$i]} = $value0;
                printf "Node: %5s  Partition: %4s\n",$t[$i],$value0+1 if $Clair::Network::verbose;
            }
            print "Cost $maxSum\n" if $Clair::Network::verbose;
        }else {
            last;
        }
        $k++;

    }
    print "--------------------------------------\n";
    return $nodePartition;
}

sub AllLocked {
    (my $self, my $nodeStatus) = @_;

    foreach $item(keys %$nodeStatus) {
#        print "item ",$item,"\n";
        return 0 if ($$nodeStatus{$item} != -1);
    }

    return 1;
}

sub getAllCost {
    my $self = shift;
    (my $EC, my $IC, my $D, my $nodePartition) = @_;

    $edges = $self->{edges};

    foreach $edge(@$edges) {
        $source = $$edge[0];
        $target = $$edge[1];

        if ($$nodePartition{$source} eq $$nodePartition{$target}) {
            $$IC{$source} += $self->get_edge_weight($source, $target);
            $$IC{$target} += $self->get_edge_weight($source, $target);
        }
        # if not, External Cost
        if ($$nodePartition{$source} ne $$nodePartition{$target}) {
            $$EC{$source} += $self->get_edge_weight($source, $target);
            $$EC{$target} += $self->get_edge_weight($source, $target);
        }
        $$EC{$source} = 0  if (! exists $$EC{$source});
        $$IC{$source} = 0  if (! exists $$IC{$source});
        $$EC{$target} = 0  if (! exists $$EC{$target});
        $$IC{$target} = 0  if (! exists $$IC{$target});

        $$D{$source} = $$EC{$source} - $$IC{$source};
        $$D{$target} = $$EC{$target} - $$IC{$target};
    }

}

1;
