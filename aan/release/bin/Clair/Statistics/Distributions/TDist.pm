# This package is based on the CPAN module Statistics::Distributions by
# Michael Kospach:
# http://search.cpan.org/~mikek/Statistics-Distributions-1.02/Distributions.pm
#
package Clair::Statistics::Distributions::TDist;
use Clair::Statistics::Distributions::DistBase;

use strict;
use warnings;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

@ISA = qw(Clair::Statistics::Distributions::DistBase);

use constant PI => 3.1415926536;
use constant SIGNIFICANT => 5; # number of significant digits to be returned

$VERSION = '0.01';

sub get_dist {
  my ($self, $n, $p) = @_;

  return $self->tdistr($n, $p);
}

sub get_prob {
  my ($self, $n, $x) = @_;

  return $self->tprob($n, $x);
}

sub tdistr { # Percentage points   t(x,n)
  my ($self, $n, $p) = @_;
  if ($n <= 0 || abs($n) - abs(int($n)) != 0) {
    die "Invalid n: $n\n";
  }
  if ($p <= 0 || $p >= 1) {
    die "Invalid p: $p\n";
  }
  return $self->precision_string($self->_subt($n, $p));
}

sub tprob { # Upper probability   t(x,n)
  my ($self, $n, $x) = @_;
  if (($n <= 0) || ((abs($n) - abs(int($n))) != 0)) {
    die "Invalid n: $n\n"; # degree of freedom
  }
  return $self->precision_string($self->_subtprob($n, $x));
}

sub _subt {
  my ($self, $n, $p) = @_;

  if ($p >= 1 || $p <= 0) {
    die "Invalid p: $p\n";
  }

  if ($p == 0.5) {
    return 0;
  } elsif ($p < 0.5) {
    return - $self->_subt($n, 1 - $p);
  }

  my $u = $self->_subu($p);
  my $u2 = $u ** 2;

  my $a = ($u2 + 1) / 4;
  my $b = ((5 * $u2 + 16) * $u2 + 3) / 96;
  my $c = (((3 * $u2 + 19) * $u2 + 17) * $u2 - 15) / 384;
  my $d = ((((79 * $u2 + 776) * $u2 + 1482) * $u2 - 1920) * $u2 - 945)
    / 92160;
  my $e = (((((27 * $u2 + 339) * $u2 + 930) * $u2 - 1782) * $u2 - 765) * $u2
           + 17955) / 368640;

  my $x = $u * (1 + ($a + ($b + ($c + ($d + $e / $n) / $n) / $n) / $n) / $n);

  if ($n <= $self->log10($p) ** 2 + 3) {
    my $round;
    do {
      my $p1 = $self->_subtprob($n, $x);
      my $n1 = $n + 1;
      my $delta = ($p1 - $p)
        / exp(($n1 * log($n1 / ($n + $x * $x))
               + log($n/$n1/2/PI) - 1 
               + (1/$n1 - 1/$n) / 6) / 2);
      $x += $delta;
      $round = sprintf("%.".abs(int($self->log10(abs $x)-4))."f", $delta);
      } while (($x) && ($round != 0));
  }
  return $x;
}

sub _subtprob {
  my ($self, $n, $x) = @_;

  my ($a,$b);
  my $w = atan2($x / sqrt($n), 1);
  my $z = cos($w) ** 2;
  my $y = 1;

  for (my $i = $n - 2; $i >= 2; $i -= 2) {
    $y = 1 + ($i - 1) / $i * $z * $y;
  }

  if ($n % 2 == 0) {
    $a = sin($w) / 2;
    $b = .5;
  } else {
    $a = ($n == 1) ? 0 : sin($w) * cos($w) / PI;
    $b= .5 + $w / PI;
  }
  return $self->max(0, 1 - $b - $a * $y);
}

sub _subu {
  my ($self, $p) = @_;
  my $y = -log(4 * $p * (1 - $p));
  my $x = sqrt(
               $y * (1.570796288
                     + $y * (.03706987906
                             + $y * (-.8364353589E-3
                                     + $y *(-.2250947176E-3
                                            + $y * (.6841218299E-5
                                                    + $y * (0.5824238515E-5
                                                            + $y * (-.104527497E-5
                                                                    + $y * (.8360937017E-7
                                                                            + $y * (-.3231081277E-8
                                                                                    + $y * (.3657763036E-10
                                                                                            + $y *.6936233982E-12)))))))))));
  $x = -$x if ($p>.5);

  return $x;
}
1;

