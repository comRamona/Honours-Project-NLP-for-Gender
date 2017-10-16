package Clair::RandomDistribution::Gaussian;
use Clair::RandomDistribution::RandomDistributionBase;
@ISA = qw (Clair::RandomDistribution::RandomDistributionBase);

use strict;
use Carp;
use constant two_pi_sqrt_inverse => 1 / sqrt (8 * atan2 (1, 1));

=head1 NAME

Clair::RandomDistribution::Gaussian

=cut

=head1 SYNOPSIS

my $z = Gaussian->new (mean => 1.1, variance => 12, dist_size => 20);

=cut

=head1 DESCRIPTION

Concrete class representing a Gaussian distributions.

=cut

sub new {
  my $class = shift;
  my %params = @_;

  # We require a mean and a variance
  unless ((exists $params{mean}) && (exists $params{variance})) {
    croak "Gaussian dist requires mean and variance parameters\n";
  }

  # Instantiate our base class/create representation
  $params{dist_name} = "Gaussian";
  my $self = $class->new_distribution (%params);

  return $self;
}

=head2 Takes a random variable

=cut

sub dist_function {
  my $self = shift;
  return two_pi_sqrt_inverse *
    exp ( -(($_[0] - $self->{mean}) ** 2) / (2 * $self->{variance})) /
    sqrt ($self->{variance});
}

1;
