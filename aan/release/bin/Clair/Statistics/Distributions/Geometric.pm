package Clair::Statistics::Distributions::Geometric;
use Clair::Statistics::Distributions::DistBase;

use strict;
use warnings;
use Math::Random qw(random_binomial);

use vars qw($VERSION @ISA);

@ISA = qw(Clair::Statistics::Distributions::DistBase);

$VERSION = '0.01';

sub get_dist {
  my ($self, $n, $p) = @_;

  return $self->geom_distr($n, $p);
}

sub get_prob {
  my ($self, $p, $x) = @_;

  return $self->geom_prob($x, $p);
}

=over

=item get_random_value

Returns a random value from the Geometric distribution.
This is defined here as the number of failures before the first success
(success on first trial == 0)

Another possible definition would be the number of trials needed to get one
success (success on first trial == 1)

=back

=cut

sub get_random_value {
  my ($self, $p) = @_;

  my $x = 0;
  my $cnt = 0;
  while ($x == 0) {
    $x = random_binomial(1, 1, $p);
    $cnt++;
  }

  return $cnt - 1;
}

sub geom_prob {
  my $self = shift;
  my ($x, $p) = @_;

  return unless $p > 0 && $p < 1;
  return 0 unless $x == int($x);
  return $p * ((1 - $p) ** ($x - 1));
}

sub geometric_expected {
  my $self = shift;
  my $x = shift;
  return 1 / $x;
}

sub geometric_variance {
  my $self = shift;
  my $x = shift;
  return (1 - $x) / ($x ** 2)
}

1;
