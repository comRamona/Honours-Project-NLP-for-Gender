package Clair::Network::Spectral;

use Clair::Network;
use Math::MatrixReal;

@ISA = qw(Clair::Network);

sub new {
    my $class = shift;
    my $net=shift;
    my $method=shift;
    if(not defined $net){
      die "Network parameter not specified or invalid network";
    }
    my $graph=$net->get_undirected_graph($net->{graph});
    $net=new Clair::Network(graph => $graph);
    my $self = bless{
                    network => $net,
                    splitting_method => $method,
                    splitting_value => 0,
                    fiedler_vector
                    }, $class;
    if (defined $method) {
                $self->set_splitting_method($method);
    }
    return $self;
}

sub get_fiedler_vector{
    my $self=shift;
    if (defined $self->{fiedler_vector}) {
      return $self->{fiedler_vector};
    }
    my $net=$self->{network};
    my @m=$net->get_vertices();
    @m = sort(@m);
    my $n=scalar(@m);
    my $L=new Math::MatrixReal($n,$n);
    for($i=0;$i<$n;$i++){
       for($j=0;$j<$n;$j++){
           if($i==$j){
               $L->assign($i+1,$j+1,$net->degree($m[$i]));
           }
           else {
               if($net->has_edge($m[$i],$m[$j])) {
                   my $w = $net->get_edge_weight($m[$i],$m[$j]);
                   $L->assign($i+1,$j+1,-1*$w);
               }
               else {
                     $L->assign($i+1,$j+1,0);
               }
           }
       }
    }

#    printf "\nLaplacian Matrix\n\n", $L if $Clair::Network::verbose;

    if($Clair::Network::verbose){
         for(my $i=1;$i<=$n;$i++){
              print "[ ";
              for(my $j=1;$j<=$n;$j++){

                  printf  "%6s  ", sprintf("%0.3f", $L->element($i,$j));
              }
              print "]\n";
         }
    }

    my ($i,$v)=$L->sym_diagonalize();
    my $min_eignvalue_idx=1;
    my $second_min_eigenvalue_idx=1;
    for($j=1;$j<=$n;$j++) {
       if($i->element($j,1)<$i->element($second_min_eigenvalue_idx,1)) {
            if($i->element($j,1)<$i->element($min_eignvalue_idx,1)){
                 $second_min_eigenvalue_idx=$min_eignvalue_idx;
                 $min_eignvalue_idx=$j;
            }else{
                 $second_min_eigenvalue_idx=$j;
            }
       }
    }
    my $second_eigenvector_matrix=$v->column($second_min_eigenvalue_idx);
    my @second_eigenvector=();
    for($i=0;$i<$n;$i++){
         $second_eigenvector[$i]= $second_eigenvector_matrix->element($i+1,1);

    }
    $self->{fiedler_vector}=\@second_eigenvector;
    return $self->{fiedler_vector};
}


sub set_splitting_method{
    my $self=shift;
    my $splitting_method=shift;
    if($splitting_method eq "bisection" || $splitting_method eq "sign" ||
        $splitting_method eq "gap"){
           $self->{splitting_method}=$splitting_method;
           $self->compute_splitting_value();
    }
    else{
         die "Splitting method '$splitting_method' is unknown\n";
    }
}

sub compute_splitting_value{
    my $self=shift;
    if(not defined $self->{fiedler_vector}){
       $self->get_fiedler_vector();
    }
    my $filder=$self->{fiedler_vector};
    if ($self->{splitting_method} eq "bisection"){
         my $count = scalar @$filder;
         # Sort a COPY of the array, leaving the original untouched
         my @array = sort { $a <=> $b } @$filder;
         if ($count % 2) {
              $self->{splitting_value} = $array[int($count/2)];
         } else {
              $self->{splitting_value} = ($array[$count/2] + $array[$count/2 - 1]) / 2;
         }
    }elsif($self->{splitting_method} eq "gap"){
       my $max_gap=0;
       my $gap_start;
       my $gap_end;
       for($i=0;$i<scalar(@$fiedler)-1;$i++){
           if(@$fiedler[$i+1]-@$fiedler[$i]>$max_gap){
                $gap_start= $i;
                $gap_end=$i+1;
           }
       }
       $self->{splitting_value}= (@$fiedler[$gap_start]+@$fiedler[$gap_end])/2;
    }elsif($self->{splitting_method}=="sign"){
       $self->{splitting_value}=0;
    }

}

sub get_splitting_value{
    my $self=shift;
    return  $self->{splitting_value};
}

sub get_partitions{
    my $self=shift;
    if (not defined $self->{fiedler_vector}) {
      $self->get_fiedler_vector();
    }
    my @parta=();
    my @partb=();
    my @vertices=$self->{network}->get_vertices();
    @vertices=sort(@vertices);
    my $fiedler_vector=$self->{fiedler_vector};
    my $vertices_num=scalar(@vertices);
    my $splitting_value=$self->{splitting_value};
    for($i=0;$i<$vertices_num;$i++)
    {
        if(@$fiedler_vector[$i]>$splitting_value){
              push @parta, @vertices[$i];
        }else{
              push @partb, @vertices[$i];
        }
    }
    return (\@parta,\@partb);
}
1;

__END__

=pod

=head1 NAME

Clair::Network::Spectral - Implements the Spectral Partitioning using the Fiedler vector
(i.e. the eigenvector of the second smallest eigen value of the Laplacian matrix.)

=head1 VERSION

Version 0.01

=head1 SYNOPSIS
        $S=new Clair::Network::Spectral($network,"bisection");
        (@a,@b)) = $S->get_partitions();

=head1 METHODS

=head2 new

Function: Creates a new object of the class
Usage: $S = new Clair::Network::Spectral($network,$splitting_method);
Parameters: - $network: The graph file to be partitioned.
            - $splitting_method: The method used to choose the splitting value.
            It can take one of the following values:
               * bisection: splitting value is the median of the second eigenvector components
               * gap: splitting value is in the middle of the largest gap within the second eigenvector values
               * sign: splitting value is 0
returns: Clair::Network:Spectral object

=head2 set_splitting_method

Function: Sets the splitting method (i.e. the method used to choose the splitting value.)
Usage: $S->set_splitting_method($splitting_method);
Parameters: - $splitting_method: The method used to choose the splitting value.
            It can take one of the following values:
               * bisection: splitting value is the median of the second eigenvector components
               * gap: splitting value is in the middle of the largest gap within the second eigenvector values
               * sign: splitting value is 0
returns: nothing


=head2 compute_splitting_value

Internal function used by the module to compute the splitting value when needed

=head2 get_splitting_value

Function: returns the splitting value.
Usage: $S->get_splitting_value();
Parameters: none
returns: the splitting value (double)


=head2 get_fiedler_vector
Function: computes and returns the fiedler vector (i.e. the second eigenvector)
Usage: $S->get_fiedler_vector();
Parameters: none
returns: the fiedler vector (array)


=head1 AUTHOR

Amjad Abu Jbara << <clair at umich.edu> >>

=cut