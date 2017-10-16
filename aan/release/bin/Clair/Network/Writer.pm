# Base abstract class for network writer
# Based on Graph::Writer by Neil Bowers
package Clair::Network::Writer;

use strict;
use warnings;
use Carp;

use vars qw($VERSION);

$VERSION = '0.01';


=head1 NAME

Clair::Network::Writer - Abstract class for exporting various Network formats

=cut

=head1 SYNOPSIS

Clair::Network::Writer should not be called directly, but instead
inherited from a concrete Writer subclass.

=cut

=head1 DESCRIPTION

This object is a base class writing Clair::Network objects to
different file formats.

=cut


sub new {
  my $class = shift;
  my $net = shift;

  my $self = {};

  bless($self, $class);

  return $self;
}

=head2 write_network

Write graph to file

Subclasses must implement the _write_network function, which is called by this.

=cut

sub write_network {
  my $self = shift;
  my $network = shift;
  my $filename = shift;

  $self->_write_network($network, $filename, @_);
}

=head2 set_name

Set the name of the export.  Some formats support network labels.

=cut

sub set_name {
  my $self = shift;
  my $name = shift;

  $self->{name} = $name;
}

1;
