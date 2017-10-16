package Clair::SentenceSegmenter::SentenceSegmenter;

use strict;
use Carp;

#
# This constructor is generic; this is an abstract base class.
#

sub new_sentence_segmenter {
  my $class = shift;
  my %params = @_;

  # Create generic instance hash
  my $self = bless {
    %params,
  }, $class;

  return $self;
}


#
# This is a skeleton method, which should be overridden by
#  all children classes.
#
sub split_sentences {
  croak "split_sentences has not been implemented\n";
  return;
}

1;
