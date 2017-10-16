package Clair::ALE::Default::NormalizeURL;

use warnings;
use strict;

use Exporter;
use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(ale_normalize_url);

sub ale_normalize_url
{
  local($_) = @_;

  if (defined $_) {
    s/\t/%09/g;
    s/\r/%0D/g;
    s/\n/%0A/g;
    s/\/index\.html$//;
    s/\/$//;

    /[\x00-\x1f\x7f-\xff]/ ? undef : $_;
  } else {
	return undef;
  }
}

1;
