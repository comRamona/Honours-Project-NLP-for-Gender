package Clair::Network::Centrality;

use strict;
use warnings;
use Carp;

use vars qw($VERSION);

$VERSION = '0.01';

=head1 NAME

Clair::Network::Centrality - Abstract class for computing network centrality

=cut

=head1 SYNOPSIS

Clair::Network::Centrality should not be called directly, but instead
inherited from a concrete Centrality subclass.

=cut

=head1 DESCRIPTION

This object is a base class for computing vertex centrality.

=cut

sub new {
  my $class = shift;
  my $net = shift;

  my $self = {};
  $self->{net} = $net;

  bless($self, $class);

  return $self;
}

=head2 centrality

Compute centrality for every vertex.

Subclasses must implement the _centrality method, and return a hash
with vertices as the keys and centrality measures as the values.

=cut

sub centrality {
  my $self = shift;

  return $self->_centrality(@_);
}

=head2 normalized_centrality

Compute centrality for every vertex, normalized to a value betwen 0
and 1.

Subclasses must implement the _normalized_centrality method, and
return a hash with vertices as the keys and normalized centrality
measures as the values.

=cut

sub normalized_centrality {
  my $self = shift;

  return $self->_normalized_centrality(@_);
}

=head2 node_centrality

Compute centrality for a single vertex.

Subclasses must implement the _centrality method, and return a
single value indicating the node's centrality.

=cut

sub node_centrality {
  my $self = shift;
  my $node = shift;

  return $self->_node_centrality($node, @_);
}

=head2 save

Save centrality values to a file

Subclasses must implement the save method, which takes one argument:
the filename to save

=cut

sub save {
  die "Centrality subclasses must implement save method\n";
}

1;
