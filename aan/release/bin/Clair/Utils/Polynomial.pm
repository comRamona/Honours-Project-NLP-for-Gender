package Clair::Utils::Polynomial;

use strict;
use warnings;

use overload ('""' => 'to_string');
use vars qw($VERSION);

$VERSION = '0.01';

=head1 NAME

Clair::Utils::Polynomial - Class for working with polynomials

=cut

=head1 SYNOPSIS

my $poly = Clair::Utils::Polynomial->new((2, 0, 5, 4);
my $v = $poly->eval_poly(4);

=cut

=head1 DESCRIPTION

This class handles polynomials.

=cut

sub new {
  my $class = shift;
  my $poly = shift;

  my $self = {poly => $poly};

  bless($self, $class);

  return $self;
}

=head2 eval_poly

Evaluate the polynomial at x

Usage:

$poly->eval_poly($x);

=cut

sub eval_poly {
  my $self = shift;
  my $x = shift;

  my $size = scalar(@{$self->{poly}});
  my $sum = 0;
  my $power = $size - 1;
  for my $coef (@{$self->{poly}}) {
    $sum += $coef * ($x ** $power);
    $power--;
  }

  return $sum;
}

=head2 deriv

First derivative of the polynomial

Usage:

$deriv_poly = $poly->deriv();

=cut

sub deriv {
  my $self = shift;

  my @a = ();
  my $size = scalar(@{$self->{poly}});
  my $power = $size - 1;
  for my $coef (@{$self->{poly}}) {
    if ($power > 0) {
      push @a, $coef * $power;
    }
    $power--;
  }
  my $deriv = Clair::Utils::Polynomial->new(\@a);

  return $deriv;
}

sub div {
  my $self = shift;
  my $div = shift;

  my @p = map {$_ / $div} @{$self->{poly}};

  return Clair::Utils::Polynomial->new(\@p);
}

=head2 to_array

Return the array representing the polynomial.

=cut

sub to_array {
  my $self = shift;

  return $self->{poly};
}

sub to_string {
  my $self = shift;

  my $size = scalar(@{$self->{poly}});
  my $power = $size - 1;
  my @str = ();
  for my $coef (@{$self->{poly}}) {
    my $term = "";
    if ($coef != 0) {
      if ($coef != 1) {
        $term .= "$coef";
      }
      if ($power > 0) {
        $term .= "x^$power";
      }
      push @str, $term;
    }
    $power--;
  }

  return join(" + ", @str);
}

1;
