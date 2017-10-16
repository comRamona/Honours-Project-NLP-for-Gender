package Clair::GraphWrapper;

use strict;
use warnings;
use Carp;

use vars qw($VERSION);

$VERSION = '0.01';


=head1 NAME

Clair::GraphWrapper - Abstract class for underlying graphs

=head1 SYNOPSIS

Clair::GraphWrapper should not be called directly, but instead
inherited from a concrete GraphWrapper subclass.

=cut

=head1 DESCRIPTION

This object is a base class for graph objects used by the Network class.

=cut


sub new {
  my $self = shift;

  die "Must overload method new in concrete subclass\n";
}

sub add_vertex {
  my $self = shift;

  die "Must override method add_vertex in subclass\n";
}

sub add_edge {
  my $self = shift;

  die "Must override method add_edge in subclass\n";
}

sub is_directed {
  my $self = shift;

  die "Must override method is_directed in subclass\n";
}

sub edges {
  my $self = shift;

  die "Must override method edges in subclass\n";
}

sub vertices {
  my $self = shift;

  die "Must override method vertices in subclass\n";
}



1;
