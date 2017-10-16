use strict;
use warnings;

package Clair::ALE::Default::Tokenizer;

use Exporter;

use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(ale_tokenize);


sub ale_tokenize
{
  map {
    split(/[^a-zA-Z]+/);
  } @_;
}

1;
