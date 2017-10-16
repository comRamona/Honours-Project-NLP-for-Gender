package Clair::Network::Generator::GeneratorBase;

use strict;
use warnings;
use Math::Random;	# used for drawing rand numbers
use Carp;
use Clair::Network;

use vars qw($VERSION);

$VERSION = '0.01';

=head1 NAME

Clair::Network::Generator::GeneratorBase - Network generator abstract class

=cut

=head1 SYNOPSIS

This is an abstract class for network generators.  Use one of the subclasses.

=cut

=head1 DESCRIPTION

A standard interface for generating networks such as Erdos-Renyi random
networks.

=cut

sub new {
  my $class = shift;

  my $self = {};
  bless($self, $class);

  return $self;
}

=head2 generate

Override this method in your subclass.  It should return a new
Clair::Network object.

=cut

sub generate {
  croak "Generator sublcass must implement generate method\n";
  return;
}

=head2 get_random_uniform_integer

Method to return a random integer from a uniform distribution

=cut

sub get_random_uniform_integer {
  my $self = shift;

  return random_uniform_integer(@_);
}

=head2 get_random_uniform

Method to return a random number between 0 and 1 from a uniform distribution

=cut

sub get_random_uniform {
  my $self = shift;

  return random_uniform(@_);
}
