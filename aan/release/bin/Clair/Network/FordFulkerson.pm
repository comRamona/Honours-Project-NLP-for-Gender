package Clair::Network::FordFulkerson;

use Clair::Network;
use Data::Dumper;

@ISA = qw(Clair::Network);

sub new {
    my $class = shift;
    my $net = shift;
    my $src = shift;
    my $dest= shift;
    my $self = bless { 
                    network => $net,
                    source => $src,
                    destination => $dest
                    }, $class;
    return $self;
}

sub set_source{
	my $self=shift;
    my $src =shift;
    return 0 unless has_node($src);
	$self->{source}=$src;
	return 1;
}

sub set_destination{
	my $self = shift;
    my $dest = shift;
    return 0 unless has_node($dest);
	$self->{destination}=$dest;
	return 1;
}

sub run{
	my $self = shift;
	my $src = $self->{source};
	my $dest = $self->{destination};
	my $net =  $self->{network};
    my $flow = (ref $net)->new;
    my @edges = $net->get_edges();
    my ( $u, $v );
    foreach $e (@edges) {
        my $u = @$e[0];
        my $v = @$e[1];   
        $flow->add_edge($u, $v );
        $flow->set_edge_attribute( $u, $v,'capacity',
                              $net->get_edge_attribute(  $u, $v, 'capacity' ) || 0 );
        $flow->set_edge_attribute( $u, $v,'flow', 0 );
        $flow->set_edge_attribute( $v, $u,'flow', 0 );
    }              
    my($p,$min)= $self->_next_augmenting_path($flow);
    @path=@$p;
    while(@path){ 
    	$flow = $self->_update_f($flow,\@path,$min) unless (!@path);
        ($p,$min)= $self->_next_augmenting_path($flow);
        @path=@$p;
    }
    my $max_flow=0; 
    @neighbours = $net->{graph}->neighbours($src);
    foreach $v (@neighbours){                              
        my $f=$flow->get_edge_attribute(  $src, $v, 'flow' );
        $max_flow=$max_flow+$f;
    }
    return ($flow,$max_flow);    
}

sub _update_f{
	my $self=shift;
	my $net=shift;
	my $p=shift;
	my $min=shift;
	@path=@$p;
	my $len=@path;
    for($i=0;$i<$len-1;$i++)
    {
       my $u=$path[$i];
       my $v=$path[$i+1];
       my $f=$net->get_edge_attribute(  $u, $v, 'flow' );
       $net->set_edge_attribute(  $u, $v,'flow', $f+$min );
       $f=$net->get_edge_attribute(  $v, $u, 'flow' );
       $net->set_edge_attribute(  $v, $u,'flow', $f-$min );
    }
    return $net;
}


sub _next_augmenting_path{
    my $self=shift;
    my $net=shift;
    my $src=$self->{source};
    my $dest=$self->{destination};
    @paths=$net->find_paths($src,$dest);
    L: foreach $path (@paths){
           my $min=$net->get_edge_attribute(@$path[0], @$path[1],'capacity');
           $len=@$path;
    	   for($i=0;$i<$len-1;$i++)
    	   {
               $u=@$path[$i];
               $v=@$path[$i+1];
               $c=$net->get_edge_attribute(  $u, $v, 'capacity' );
               $f=$net->get_edge_attribute(  $u, $v, 'flow' );
               $cf=$c-$f;                                  
               if($cf<=0){
               	 next L;
               }
               if($cf<$min){
  	              $min=$cf;
               }
    	   }
    	   @p=@$path;
    	   return (\@p,$min);
    }

    return (undef,undef);
}





