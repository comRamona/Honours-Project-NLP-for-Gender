=head1 NAME

Clair::RandomDistribution::RandomDistributionBase - base class for all distributions

=cut

=head1 SYNOPSIS

Do not try to instantiate this class - it is an abstract base
 providing methods and structures for creating probability
 distributions, drawing random values from distributions,
 and so on.

=cut

=head1 DESCRIPTION

This class implements the following methods, which in general should
 not be overridden:

 - new_distribution
    Base class constructor; only to be called from child classes
- draw_rand_from_dist
    Draws a random integer from the distribution
- dump_distribution_array
    Returns a string containing the distribution array,
    useful for debugging, suitable for printing

This class expects the following methods to be implemented by child
 classes, which should be overridden:

	- dist_function
	    Returns a weight value given a random variable
	    NOTE: These weights need not sum to 1

=cut

package Clair::RandomDistribution::RandomDistributionBase;

use strict;
use Carp;
use Math::Random;	# used for drawing rand numbers
#use Math::TrulyRandom;	# used ONCE to seed random number generator above

# Seed the RNG once for this package
#random_set_seed (abs (truly_random_value() % 2147483561) + 1,
#                 abs (truly_random_value() % 2147483561) + 1);


=head2 new_distribution

This is the base class constructor. It should be called only by the
 constructor of a child class. It depends on the method
 "dist_function" having been implemented, because it uses this
 function to build the internal distribution representation.

Parameters:
 dist_size	=> number of values in distribution (positive integer)
 dist_name	=> name of distribution (string)

=cut

sub new_distribution {
  my $class = shift;
  my %params = @_;
  my $dist_size = $params{dist_size};	# use local var for repeated access

  # We require the following args: "dist_size" and "dist_name"
  unless ($dist_size) {
    croak "Must specify number of values in distribution (positive integer)\n";
  }

  # Create generic instance hash
  my $self = bless {
    %params,
    dist_array => [ -1 ]
  }, $class;

  # Populate distribution array representation
  # NOTE: All actual values start at index 1

  my $running_sum = 0;
  for (my $i = 1; $i <= $dist_size; $i++) {
    $running_sum += $self->dist_function ($i);
    push (@{$self->{dist_array}}, $running_sum);
  }

  # Running sum now contains the total weight of the dist
  for (my $i = 1; $i <= $dist_size; $i++) {
    $self->{dist_array}->[$i] /= $running_sum;
  }

  # Array is done. Return our instance.
  return $self;
}

#
# Performs a binary search on the distribution array
#  to find the corresponding distribution value for a 
#  uniformly distributed index. Repeated calls return
#  terms distributed based on the underlying (inhereted)
#  distribution.
#
sub draw_rand_from_dist {
  my $self = shift;
  my $rand_val = random_uniform ();	# Rand val on interval [0,1]

  my $dist_array = $self->{dist_array};

  # lower, upper end of search interval
  my ($l, $u) = (0, $self->{dist_size});
  my $i;                    # index of probe

  while ($l <= $u) {
    $i = ($l + $u) >> 1;
    if ($dist_array->[$i] < $rand_val) {
        $l = $i+1;
    } elsif ($dist_array->[$i-1] >= $rand_val) {
        $u = $i-1;
    } else {
        return $i;
    }
  }
}

=head2 dump_distribution_array

This method returns a string containing the underlying distribution
 array representation. This is useful primarily for debugging.

=cut

sub dump_distribution_array {
  my $self = shift;
  my $out_str = "";

  for (my $i = 0; $i <= $self->{dist_size}; $i++) {
    $out_str .= "$i -> " . $self->{dist_array}->[$i] . "\n"; 
  }

  return $out_str;
}

=head2 dist_function

This is a skeleton method, which should be overridden by all children
 classes.

=cut

sub dist_function {
  croak "dist_function has not been implemented\n";
  return;
}

1;
