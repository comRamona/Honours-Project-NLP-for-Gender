package Clair::ALE::NormalizeURL;

use warnings;
use strict;
use Clair::Utils::ALE qw(%ALE_ENV);

use Exporter;

use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(ale_normalize_url);

# BEGIN { $Exporter::Verbose=1 }
sub import
{
  if (!$ALE_ENV{ALE_NORMALIZE_URL})
  {
    $ALE_ENV{ALE_NORMALIZE_URL}='Clair::ALE::Default::NormalizeURL';
  }
  if ($ALE_ENV{ALE_NORMALIZE_URL} =~ /^(Clair::ALE::[\w:]+)$/)
  {
    eval "require $1";
  }
  else
  {
    die "Invalid class name for ALE_NORMALIZE_URL\n";
  }
  die $@ if $@;
  $ALE_ENV{ALE_NORMALIZE_URL}->export_to_level(1,@_);
}

1;
