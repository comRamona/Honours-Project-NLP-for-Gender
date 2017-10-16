=head1 NAME

Clair::RandomDistribution::Zipfian

=cut

=head1 SYNOPSIS

my $z = Clair::RandomDistribution::Zipfian->new(alpha => 1.1, dist_size => 20);
my $d = Clair::RandomDistribution::Zipfian->new(dist_size => 500000, alpha => 2.0);

=cut

=head1 DESCRIPTION

Concrete class representing a Zipfian distributions.

=cut

package Clair::RandomDistribution::Zipfian;
use Clair::RandomDistribution::RandomDistributionBase;
@ISA = qw (Clair::RandomDistribution::RandomDistributionBase);

use strict;
use Carp;

sub new {
  my $class = shift;
  my %params = @_;

  # We require an "alpha" parameter
  unless (exists $params{alpha}) {
    croak "Zipfian dist requires alpha parameter\n";
  }

  # Instantiate our base class/create representation
  $params{dist_name} = "Zipfian";
  my $self = $class->new_distribution (%params);

  return $self;
}

=head2 dist_function

Takes rank as a parameter

=cut

sub dist_function {
  my $self = shift;
  return 1 / ($_[0] ** $self->{alpha});
}

1;
