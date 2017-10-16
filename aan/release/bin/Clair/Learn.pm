package Clair::Learn;

=head1 NAME

B<package> Clair::Learn
Implement various learning algorithms here. Default algorithm is Perceptron.

=head1 AUTHOR

JB Kim
jbremnant@gmail.com
20070407

=head1 SYNOPSIS

Use the train data produced by Clair::Feature.pm (in svm_light format) to train
the classifier. The underlying algorithm can be either Naive Bayes or Perceptron.

Here, the "train" parameter is required in the constructor. 

	use Clair::Learn;

	my $lea = new Clair::Learn(DEBUG => $DEBUG, train => "train.dat", model => "model.file");
	$lea->learn($algo);

=head1 DESCRIPTION

The module should provide the ability to choose between different classifier
algorithms. However, it defaults to Perceptron for learning.

=cut


# use FindBin;
# use lib "$FindBin::Bin/../lib/perl5/site_perl/5.8.5";
# use lib "$FindBin::Bin/lib/perl5/site_perl/5.8.5";

use strict;
use vars qw/$DEBUG/;

use Clair::Debug;
use Data::Dumper;
use Clair::Features;
use File::Path;


=head2 new

 The constructor. Initializes several container hashes for later use. 
 We instantiate the Feature.pm object here, because it has the routines
 to read in the svm_light formatted training data and convert it into 
 a necessary hash structure.

=cut

sub new
{
	my ($proto, %args) = @_;
	my $class = ref $proto || $proto;

	my $self = bless {}, $class;
	$DEBUG = $args{DEBUG} || $ENV{MYDEBUG};
	
	$self->{train} = "output.train";
	$self->{model} = "model";
	$self->{eta} = 1;

	# overrides
	while ( my($k, $v) = each %args )
	{
		$self->{$k} = $v if(defined $v);
	}

	if(-f $self->{train})
	{
		# read in our features from the training data set
		my $fea = new Clair::Features(DEBUG => $DEBUG);
		$self->{train_data} = $fea->input($self->{train});
	}

  return $self;
}



=head2 learn
 
 A wrapper function for the underlying algorithms.

=cut

sub learn
{
	my ($self, $algo, $eta) = @_;

	$self->errmsg("the 'train' parameter is required in the constructor for learn() method", 1)
		unless($self->{train_data});

	$algo = "_learn_perceptron" unless($algo);

	$self->debugmsg("running \$self->$algo()", 2);

	return $self->$algo($eta);
}


=head2 _learn_perceptron
 
 Implementation of perceptron algorithm. From the book, 
 "Modeling the Internet and the Web":

  Perceptron(D)
   W <- 0
   w0 <- 0
   repeat
     e <- 0
     for i < 1 .. n
     do s <- sgn(y_i ( W' * X_i + w0 ))
       if s < 0
         then W <- W + y_i * X_i
              w0 <- w0 + y_i
              e <- e + 1
   until e = 0
   return (W, w0)

 From the lecture notes:

  W0 = 0, k = 0
  For i = 1 to n
    if y_i * (W_k * X_i) <= 0 //mistake
      W_k+1 = W_k + eta * y_i * X_i
      k = k + 1
    end
  end

 Some notes:

  n   = number of documents
  X_i = feature vector for i-th doc
  W   = weight vector
  y_i = class identifier (-1 or +1) for i-th doc

=cut

sub _learn_perceptron
{
	my ($self, $eta) = @_;

	my $w = {};
	my $w0 = 0;
	$eta = $self->{eta} unless($eta);

	for my $d (@{$self->{train_data}})
	{
		my $y = $d->{class};
		my $x = $d->{features};

		my $sum = $self->dot_product($x, $w);
		my $s = $y * ( $sum + $w0 ); # linear equation

		if($s <= 0)
		{
			# cuz x and w are vectors
			for my $j (keys %$x)
			{
				my $w_current = (exists $w->{$j}) ? $w->{$j} : 0;
				$w->{$j} = $w_current + ( $eta * $y * $x->{$j} ); 
			}
			$w0 = $w0 + $y;
		}
	}

	# save the result
	$self->{perceptron_w0} = $w0;
	$self->{perceptron_w} = $w;

	return ($w0, $w);
}


=head2 dot_product

 Compute the dot product of two matrices - each matrix is
 a hash.

=cut

sub dot_product
{
	my ($self, $a, $b) = @_;

	# we are only interested in multiplying the keys that intersect,
	# so it doesn't matter on which hash you do a loop.

	my $sum = 0;
	for my $k (keys %$a)
	{
		$sum += $a->{$k} * $b->{$k} if($b->{$k}); 
	}
	
	# my $sum_check = 0;
	# for my $k (keys %$b)
	# {
		# $sum_check += $a->{$k} * $b->{$k} if($a->{$k}); 
	# }

	# $self->errmsg("$sum != $sum_check : seriously wrong", 1) if($sum_check != $sum);

	return $sum;
}


=head2 read_model
 
 A simple function to read in key value-pair from a model file generated
 from Learn.pm. The model file should contain estimated coefficients/weights
 from the default (perceptron) algorithm.

=cut

sub read_model
{
	my ($self, $modelfile) = @_;
	
	$self->errmsg("file '$modelfile' does not exist", 1) unless(-f $modelfile);

	open MF, "< $modelfile" or $self->errmsg("cannot open '$modelfile': $!", 1);
	my @lines = <MF>;	
	close MF;

	chomp @lines;

	my %hash = ();
	for my $l (@lines)
	{
		my ($key, $val) = split /\s+/, $l;
		$hash{$key} = $val;
	}
	return \%hash;
}

1;
