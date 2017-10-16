use strict;
use warnings;

package Clair::ALE::Stemmer;

use Exporter;
use Clair::Utils::ALE qw(%ALE_ENV);

use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(ale_stem ale_stemsome);

=head1 NAME

Clair::ALE::Stemmer - Internal stemmer used by ALE.

=head1 SYNOPSIS

This module is used internally by the other ALE modules to stem words.

It looks in the C<ALE_STEMMER> environment variable to decide which
stemming module to load; by default it loads
L<Clair::ALE::Default::Stemmer|Clair::ALE::Default::Stemmer>.

=cut



sub import
{
  if (!$ALE_ENV{ALE_STEMMER})
  {
    $ALE_ENV{ALE_STEMMER}='Clair::ALE::Default::Stemmer';
  }
  if ($ALE_ENV{ALE_STEMMER} =~ /^(Clair::ALE::[\w:]+)$/)
  {
    eval "require $1";
  }
  else
  {
    die "Invalid class name for ALE_STEMMER\n";
  }
  die $@ if $@;
  
  $ALE_ENV{ALE_STEMMER}->export_to_level(1,@_);
}

1;
