#!/usr/bin/perl

package Clair::ALE::Default::Stemmer;

=head1 NAME

Clair::ALE::Default::Stemmer - ALE's default stemmer.

=head1 SYNOPSIS

This module is used internally by the other ALE modules to stem words.
Other modules (particularly L<Clair::ALE::Search|Clair::ALE::Search>) will use this
automatically, so you shouldn't have to use it yourself unless you're
writing an ALE module.

It is a thin frontend for a standard Porter stemmer.  It's main purpose
is to make it easy to change stemmers without having to change any
other code.

=cut

use strict;
use Clair::Utils::porter;

require Exporter;
use vars qw(@ISA);
@ISA = qw(Exporter);

use vars qw(@EXPORT_OK);
@EXPORT_OK = qw(ale_stem ale_stemsome);


sub ale_stem
{
  shift if (ref $_[0]);
  Clair::Utils::porter::porter($_[0]);
}

sub _ale_stem
{
  shift if (ref $_[0]);
  Clair::Utils::porter::porter($_[0]);
}

sub ale_stemsome
{
  return map { ale_stem($_) } @_;
}

sub stemsome
{
  my $self = shift;
  goto &ale_stemsome;
}

sub stem
{
  my $self = shift;
  goto &ale_stem;
}

sub new
{
  my $class = shift;
  my $self = {};
  bless $self,$class;
}

1;
