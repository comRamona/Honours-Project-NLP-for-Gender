=head1 NAME

Clair::RandomDistribution::Poisson

=cut

=head1 SYNOPSIS

my $z = Clair::RandomDistribution::Poisson->new(lambda => 5, dist_size => 50);

=cut

=head1 DESCRIPTION

Concrete class representing a Poisson distributions.

=cut

package Clair::RandomDistribution::Poisson;
use Clair::RandomDistribution::RandomDistributionBase;
#use PerlTreeMath;
@ISA = qw (Clair::RandomDistribution::RandomDistributionBase);

use strict;
use Carp;

sub new {
  my $class = shift;
  my %params = @_;

  # We require a lambda parameter (a positive real number, equal to
  #  the expected number of occurrences on the given interval)
  unless ((exists $params{lambda}) && ($params{lambda} > 0)) {
    croak "Poisson dist requires positive lambda parameter\n";
  }

  # Instantiate our base class/create representation
  $params{dist_name} = "Poisson";
  my $self = $class->new_distribution (%params);

  return $self;
}

=head2 dist_function

Takes a random variable

=cut

sub dist_function {
  my $self = shift;
  return (($self->{lambda} ** $_[0]) * exp (-$self->{lambda})) /
    factorial ($_[0]);
}

=head2 factorial

Iteratively computes factorial

=cut

sub factorial {
    return unless int( $_[0] ) == $_[0] && $_[0] >= 0;
    my $f = 1;
    foreach ( 2 .. $_[0] ) { $f *= $_ };
    $f;
}

1;
