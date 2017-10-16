package Clair::Network::Reader;

use strict;
use warnings;
use Carp;

use vars qw($VERSION);

$VERSION = '0.01';

=head1 NAME

Clair::Network::Reader - Abstract class for reading in network formats

=cut

=head1 SYNOPSIS

Clair::Network::Reader should not be called directly, but instead
inherited from a concrete Reader class.

=cut

=head1 DESCRIPTION

This object is a base class for reading in Clair::Network objects from
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

Write graph to file.

Subclasses must implement the _read_network method, and return a
Clair::Network object.

=cut

sub read_network {
  my $self = shift;
  my $filename = shift;

  return $self->_read_network($filename, @_);
}

1;
