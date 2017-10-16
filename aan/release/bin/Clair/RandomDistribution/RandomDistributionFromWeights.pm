=head1 NAME

Clair::RandomDistribution::RandomDistributionFromWeights

=cut

=head1 SYNOPSIS

my $z = Clair::RandomDistribution::RandomDistributionFromWeights->new(weights => \@weight_array);

=cut

=head1 DESCRIPTION

Concrete class representing a distribution passed as an array that
maps indices to weights. Note that index zero (0) should not contain a
meaningful value in the distribution, as no value can have zero rank.

=cut

package Clair::RandomDistribution::RandomDistributionFromWeights;
use Clair::RandomDistribution::RandomDistributionBase;
@ISA = qw (Clair::RandomDistribution::RandomDistributionBase);

use strict;
use Carp;

sub new {
  my $class = shift;
  my %params = @_;

  # We require an "filename" parameter
  unless (exists $params{weights}) {
    croak "RandomDistributionFromWeights requires a weights array\n";
  }

  $params{dist_size} = scalar (@{$params{weights}}) - 1;

  # Instantiate our base class/create representation
  $params{dist_name} = "Clair::RandomDistribution::RandomDistributionFromWeights";
  my $self = $class->new_distribution (%params);

  return $self;
}

sub dist_function {
  my $self = shift;
  return $self->{weights}->[$_[0]];
}

1;
