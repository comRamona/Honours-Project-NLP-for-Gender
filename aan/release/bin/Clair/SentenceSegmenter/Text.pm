package Clair::SentenceSegmenter::Text;

use strict;
use Carp;
use vars qw(@ISA);

use Clair::SentenceSegmenter::SentenceSegmenter;
use Text::Sentence;
@ISA = qw (Clair::SentenceSegmenter::SentenceSegmenter);

sub new {
  my $class = shift;
  my %params = @_;

  # Instantiate our base class/create representation
  $params{segmenter_type} = "Text";
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

#    print "Text, splitting.\n";

# Setting the locale first may be worthwhile here. TODO
    my @sentences = Text::Sentence::split_sentences( $text );

    # The rest of clairlib expects to see a single whitespace char at the end of
    # each sentence.
    # MxTerminator keeps a single whitespace character at the end of each sentence.
    # Text::Sentence does not, leading to undesired behavior.
    # The following loop makes this function conform to its original authors'
    #  expectations.
    for my $i (0..$#sentences) {
        $sentences[$i] = "$sentences[$i] ";
    }

	return @sentences;
}

1;
