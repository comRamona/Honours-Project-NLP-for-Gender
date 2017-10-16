=head1 NAME

Clair::RandomDistribution::LogNormal

=cut

=head1 SYNOPSIS

my $z = Clair::RandomDistribution::LogNormal->new(mean => 1.1, std_dev => 0.3, dist_size => 20);

=cut

=head1 DESCRIPTION

Concrete class representing a LogNormal distributions.

=cut

package Clair::RandomDistribution::LogNormal;
use Clair::RandomDistribution::RandomDistributionBase;
@ISA = qw (Clair::RandomDistribution::RandomDistributionBase);

use strict;
use Carp;
use constant sqrt_twopi => sqrt (8 * atan2 (1, 1));

sub new {
  my $class = shift;
  my %params = @_;

  # We require a mean and a variance
  unless ((exists $params{mean}) && (exists $params{std_dev})) {
    croak "LogNormal dist requires mean and std_dev parameters\n";
  }

  # Instantiate our base class/create representation
  $params{dist_name} = "LogNormal";
  my $self = $class->new_distribution (%params);

  return $self;
}

=head2 dist_function

Takes a random variable

=cut

sub dist_function {
  my $self = shift;
  return (exp -((log ($_[0]) - $self->{mean}) ** 2) /
                (2 * ($self->{std_dev} ** 2))) /
         (sqrt_twopi * $self->{std_dev} * $_[0]);
}

1;
