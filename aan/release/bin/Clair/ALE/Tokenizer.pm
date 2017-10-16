use strict;
use warnings;

package Clair::ALE::Tokenizer;
use Exporter;

use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(ale_tokenize);

sub import
{
  if (!$ENV{ALE_TOKENIZER})
  {
    $ENV{ALE_TOKENIZER}='Clair::ALE::Default::Tokenizer';
  }
  if ($ENV{ALE_TOKENIZER} =~ /^(Clair::ALE::[\w:]+)$/)
  {
    eval "require $1";
  }
  else
  {
    die "Invalid class name for ALE_TOKENIZER\n";
  }
  die $@ if $@;
  $ENV{ALE_TOKENIZER}->export_to_level(1,@_);
}

1;
