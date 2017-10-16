package Clair::SentenceSegmenter::MxTerminator;

use strict;
use Carp;
use Clair::Utils::MxTerminator;

use vars qw(@ISA);

use Clair::SentenceSegmenter::SentenceSegmenter;
@ISA = qw (Clair::SentenceSegmenter::SentenceSegmenter);

sub new {
  my $class = shift;
  my %params = @_;

  # Instantiate our base class/create representation
  $params{segmenter_type} = "MxTerminator";
  my $self = $class->new_sentence_segmenter (%params);

  return $self;
}

#
# Takes a string of sentences to split.
# Returns a list of sentences, each ending in a whitespace character.
#
sub split_sentences {
    my $self = shift;
	my $text = shift;

    # print "MxTerminator, splitting.\n";

    # The rest of clairlib expects to see a single whitespace char at the end of
    # each sentence.
    # MxTerminator keeps a single whitespace character at the end of each sentence.
    
#    Clair::Utils::MxTerminator::init;
    my @sentences = Clair::Utils::MxTerminator::do_document($text);
	return @sentences;
}

1;
