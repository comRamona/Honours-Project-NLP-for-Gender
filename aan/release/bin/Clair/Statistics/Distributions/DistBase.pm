# This package is based on the CPAN module Statistics::Distributions by
# Michael Kospach:
# http://search.cpan.org/~mikek/Statistics-Distributions-1.02/Distributions.pm
#
package Clair::Statistics::Distributions::DistBase;

use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use constant PI => 3.1415926536;
use constant SIGNIFICANT => 5; # number of significant digits to be returned

#require Exporter;

#@ISA = qw(Exporter AutoLoader);
#@EXPORT_OK = qw(PI SIGNIFICANT);

$VERSION = '0.01';

sub new {
  my $class = shift;
  my $self = {};

  bless($self, $class);

  return $self;
}

sub log10 {
  my $self = shift;
  my $n = shift;
  return log($n) / log(10);
}

sub max {
  my $self = shift;
  my $max = shift;
  my $next;
  while (@_) {
    $next = shift;
    $max = $next if ($next > $max);
  }
  return $max;
}

sub min {
  my $self = shift;
  my $min = shift;
  my $next;
  while (@_) {
    $next = shift;
    $min = $next if ($next < $min);
  }
  return $min;
}

sub precision {
  my $self = shift;
  my ($x) = @_;
  return abs int($self->log10(abs $x) - SIGNIFICANT);
}

sub precision_string {
  my $self = shift;
  my ($x) = @_;
  if ($x) {
    return sprintf "%." . $self->precision($x) . "f", $x;
  } else {
    return "0";
  }
}

1;
