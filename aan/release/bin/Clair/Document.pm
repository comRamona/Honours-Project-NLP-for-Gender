package Clair::Document;


our $VERSION = '1.02';

use warnings;
use strict;

use Carp;
use Lingua::Stem;
use Lingua::Stem::En;
use IO::File;
use XML::Parser;
use Scalar::Util qw(looks_like_number);
use Lingua::EN::Sentence; #qw(get_sentences);
use Clair::Config;
use Clair::SentenceSegmenter::SentenceSegmenter;
use Clair::SentenceSegmenter::Text;
use Clair::Utils::TFIDFUtils qw();  # IMPORTANT: avoid importing split_words due to name clash with subroutine in this package
use Clair::Utils::MxTerminator;
use Text::Sentence qw(split_sentences);

use vars qw(@ISA @EXPORT);

my $sid;
my @sentences;
my $r_text;
my $latest_tag;


sub count_words
{
        my $self = shift;
        my $body = $self->{text};
        #my @words = split(r"[\s\.,\?]+", $body);
        my @words = split(/\s+/, $body);
        return scalar(@words);
}



sub split_into_words
{
        my $self = shift;
        my %parameters = @_;

        my $type = 'text';
        if (exists $parameters{type}) {
                $type = $parameters{type};
        }
    my $punc = $parameters{punc};

        my $body;
    if ($type eq "text") {
        $body = $self->get_text();
    } elsif ($type eq "html") {
        $body = $self->get_html();
    } elsif ($type eq "stem") {
        $body = $self->get_stem();
    } else {
        die "type must be html, text, or stem";
    }

    return Clair::Utils::TFIDFUtils::split_words($body, $punc);
}


sub get_unique_words
{
    my $self = shift;
    my %params = @_;

    my $type = $params{type} || "stem";
    my @words = $self->split_into_words( type => $type );
    my %hash;
    map {$hash{$_} = 1} @words;
    my @unique_words = keys %hash;
    return @unique_words;
}


sub print
{
        my $self = shift;
        my %parameters = @_;
        my $type = $parameters{type};
        my $body = $self->{$type};

        if ($type eq "sent") {
            my $sents = $self->{sent};
            foreach my $s (@{$sents}) {
                print "$s\n";
            }
        }
        else {
            print $body;
        }
}


sub save
{
        my $self = shift;
        my %parameters = @_;
        my $file = $parameters{file};
        my $type = $parameters{type};
        my $body = $self->{$type};

        open FILE, ">$file" or
        croak('Document::save - Could not open file for writing.');

        print FILE $body;
        close FILE;
}


sub strip_html
{
        my $self = shift;

    my $text;
    if (defined $self->{html}) {
            $text = $self->{html};
            $text =~ s/<.+?>//g;
            $self->{text} = $text;
    } else {
        $text = $self->{text};
    }
        return $text;
}

sub get_html {
        my $self = shift;
        return $self->{html};
}

sub get_xml {
        my $self = shift;
        return $self->{xml};
}

sub get_text {
        my $self = shift;
        return $self->{text};
}

sub get_stem {
        my $self = shift;
    if (defined $self->{stem}) {
            return $self->{stem};
    } else {
        return $self->stem();
    }
}

sub get_sent {
        my $self = shift;
    if (defined $self->{sent}) {
            return @{$self->{sent}};
    } else {
        return $self->split_into_sentences();
    }
}

sub get_sentences {
    my $self = shift;
    if (defined $self->{sent}) {
        return @{$self->{sent}};
    } else {
        return $self->split_into_sentences();
    }
}

sub get_id
{
        my $self = shift;

        return $self->{id};
}


sub get_class
{
        my $self = shift;

        return $self->{class};
}


sub set_id
{
        my $self = shift;
        my %parameters = @_;
        my $id = $parameters{id};

        if (!defined $id)
        {
                die('Document::set_id - id parameter not defined.');
        }

        $self->{id} = $id;
}


sub set_class
{
        my $self = shift;
        my $label = shift;

        $self->{class} = $label;
}


sub set_parent_document {
        my $self = shift;
        my $doc = shift;

        $self->{parent_document} = $doc;
}


sub get_parent_document {
        my $self = shift;

        if (not exists $self->{parent_document}) {
                die "Parent document has not been set.\n";
        }

        return $self->{parent_document};
}

sub tf {
    my $self = shift;
    my %params = @_;

    my $type = $params{type} || "stem";
    my $punc = $params{punc} || 0;

    my @words = $self->split_into_words( type => $type, punc=> $punc );
    my %tf;
    foreach my $word (@words) {
        $tf{$word}++;
    }
    return %tf;
}

sub filter_sents {

    my $self = shift;
    my %params = @_;
    unless ($params{matches} || $params{test}) {
        warn "No argument passed to Document::filter_sents";
        return $self;
    }
    my @sents = $self->split_into_sentences();

    my $test = $params{test};
    if ($params{matches}) {
        $test = sub { /$params{matches}/ };
    }
    my @filtered = grep { &$test($_) } @sents;
    my $text = join "", @filtered;
    my $id = $self->get_id();
    my $class = $self->get_class();
    my $result = Clair::Document->new(
        string => $text, type => "text", id => $id, class => $class );
    return $result;

}


# ------------------------------------------------------------
#  {tag,text} are auxiliary routines for parse_html()
# ------------------------------------------------------------


sub stem {
    my $self = shift;

    my $stemmer = Lingua::Stem->new(-locale => 'EN-US');
    $stemmer->stem_caching({ -level => 2 });
    my @words = split(/\s+/, $self->{text});

my @stemmed = @{$stemmer->stem(@words)};
    my $stem = join(" ",@stemmed);
    $self->{stem} = $stem;

        return $stem;
}

# Added by Mark Hodges because calculating the idf requires
# the newlines remain in place
# Note: this adds a newline to the end of the document
sub stem_keep_newlines {
    my $self = shift;

    my @lines = split(/\n/, $self->{text});
    my $stemmer = Lingua::Stem->new(-locale => 'EN-US');
    $stemmer->stem_caching({ -level => 2 });

    my $stem = "";

    foreach my $l (@lines) {
      my @words = split(/\s+/, $l);

      my @stemmed = @{$stemmer->stem(@words)};
      $stem .= join(" ",@stemmed) . "\n";
    }

    $self->{stem} = $stem;
    return $stem;
}


sub split_into_lines {
    my $self = shift;

    my $text = $self->{text};
    my @lines = split(/\n/, $text);

    return @lines;
}

sub xml_to_text {
    my $self = shift;

    my $xml = $self->{xml};

    my $xml_parser = new XML::Parser(Handlers => {
        Start => \&read_start,
        Char => \&read_char});

    $sid=1;

    @sentences = ();
    $r_text = "";

    $xml_parser->parse($self->{xml});

    $self->{sent} = \@sentences;
    $self->{text} = $r_text;

    return @sentences;
}

sub remove_whitespace {

    my $text = shift;
    $text =~ s/\s//g;
    return $text;

}

sub read_start {
    shift;
    my $element_name = shift;
    my %atts = @_;

    if ($element_name eq 'p') {
        $latest_tag = "p";
    }
    else {
        $latest_tag = $element_name;
    }
#    print "latest_tag= $latest_tag\n";
}

### The following two functions seem to not be used by anything.  Warning.

sub trim {

    my $text = shift;
    $text =~ s/^\s+//;
    $text =~ s/\s+$//;
    return $text;

}

sub read_char {
    shift;
    my $text = shift;

    if ($text =~ /\S/) {
        if ($latest_tag eq "p") {
#            push (@sentences, "$sid\t$latest_tag\t$text");
            push (@sentences, "$text");
            $r_text .= "$text\n";
            $sid++;
        }
        else {
#            push (@sentences, "$sid\t$latest_tag\t$text");
        }
    }
}


sub split_into_sentences {
     my $self = shift;
     my $text = $self->{text};
     my $sentences_ref = Lingua::EN::Sentence::get_sentences($text);
     my @sentences = @{$sentences_ref};
     $self->{sent} = \@sentences;
     return @sentences;
}

sub sentence_count {
    my $self = shift;
    return scalar $self->get_sentences();
}

sub sentence_index_in_range {
    my $self = shift;
    my $index = shift;
    my $total_sents = $self->sentence_count();
    return ($index >= 0 and $index < $total_sents);
}

sub set_sentence_feature {

    my $self = shift;
    my $index = shift;
    my %features = @_;

    return undef unless ($self->sentence_index_in_range($index));
    return undef unless (keys %features > 0);

    my $added = 0;
    foreach my $feature_name (keys %features) {
        if (defined $features{$feature_name}) {
            $self->{sent_feats}->[$index]->{$feature_name} =
                $features{$feature_name};
            $added++;
        }
    }
    return $added;

}


sub get_sentence_features {

    my $self = shift;
    my $index = shift;

    return undef unless $self->sentence_index_in_range($index);
    my $feat_ref = $self->{sent_feats}->[$index];
    return %$feat_ref;

}


sub get_sentence_feature {

    my $self = shift;
    my $index = shift;
    my $name = shift;

    return undef unless ($self->sentence_index_in_range($index));
    if (defined $self->{sent_feats}->[$index]->{$name}) {
        return $self->{sent_feats}->[$index]->{$name};
    } else {
        return undef;
    }
}

sub remove_sentence_features {
    my $self = shift;
    my @sents = $self->get_sentences();
    for (my $i = 0; $i < @sents; $i++) {
        my %features = $self->get_sentence_features($i);
        foreach my $name (keys %features) {
            $self->remove_sentence_feature($i, $name);
        }
    }
}

sub remove_sentence_feature {

    my $self = shift;
    my $index = shift;
    my $name = shift;

    return undef unless ($self->sentence_index_in_range($index));
    if (exists $self->{sent_feats}->[$index]->{$name}) {
        delete $self->{sent_feats}->[$index]->{$name};
        return 1;
    } else {
        return undef;
    }
}

sub score_sentences {

    my $self = shift;
    my %params = @_;

    my $combiner = $params{combiner};
    my $weights = $params{weights};
    my $normalize = $params{normalize};
    $normalize = 1 unless (defined $normalize);

    return undef unless (defined $combiner or defined $weights);

    # Use a regular linear combiner if weights are specified.
    if (defined $weights) {
        $combiner = sub {
            my %features = @_;
            my $score = 0;
            foreach my $name (keys %$weights) {
                if ($features{$name}) {
                    $score += $weights->{$name} * $features{$name};
                }
            }
            return $score;
        };
    }

    my @sents = $self->get_sentences();
    for (my $i = 0; $i < @sents; $i++) {

        my %features = $self->get_sentence_features($i);
        my $score;
        eval {
            $score = &$combiner(%features);
        };

        if ($@) {
            warn "Could not combine scores: $@";
            return undef;
        } elsif (not defined $score) {
            warn "Could not combine scores, combiner returned undef for sent$i";
            return undef;
        } elsif (not looks_like_number($score)) {
            warn "Could not combine scores, combiner returned non number $score"
               . " for sent $i";
            return undef;
        } else {
            $self->set_sentence_score($i, $score);
        }

    }

    $self->normalize_sentence_scores() if $normalize;
    $self->get_sentence_scores();

}

sub compute_sentence_features {
    my $self = shift;
    my %features = @_;

    foreach my $name (keys %features) {
        $self->compute_sentence_feature( name => $name,
            feature => $features{$name} );
    }

}

sub compute_sentence_feature {

    my $self = shift;
    my %params = @_;

    my ($name, $sub) = ($params{name}, $params{feature});
    return undef unless (defined $name and defined $sub);

    my $norm = $params{normalize};
    my @sents = $self->get_sentences();
    my $state = {};

    foreach my $i (0 .. $#sents) {

        my %params = (
            document => $self,
            sentence => $sents[$i],
            sentence_index => $i,
            state => $state
        );

        my $value;
        eval {
            $value = &$sub(%params);
        };

        my $did = $self->get_id() || "no id";
        if ($@) {
            warn "Feature $name died processing sent $i in document $did: $@";
        } elsif (not defined $value) {
            warn "Feature $name returned undef for sent $i in document $did";
        } else {
            $self->set_sentence_feature($i, $name => $value);
        }

    }

    if ($norm) {
        return $self->normalize_sentence_feature($name);
    }

    return 1;

}

sub normalize_sentence_features {
    my $self = shift;
    my @names = @_;

    return undef unless (scalar @names > 0);
    foreach my $name (@names) {
        $self->normalize_sentence_feature($name);
    }
}

sub normalize_sentence_feature {

    my $self = shift;
    my $name = shift;

    return undef unless (defined $name);

    my @sents = $self->get_sentences(0);
    if (@sents > 0) {

        my $min = $self->get_sentence_feature(0, $name);
        my $max = $min;
        my ($max_index, $min_index) = (0, 0);

        unless (looks_like_number($max) and looks_like_number($min)) {
            warn "Can't normalize feature $name: non-numeric";
            return undef;
        }

        for (my $i = 0; $i < @sents; $i++) {
            my $value = $self->get_sentence_feature($i, $name);
            if (looks_like_number($value)) {

                if ($value > $max) {
                    $max = $value;
                    $max_index = $i;
                }

                if ($value < $min) {
                    $min = $value;
                    $min_index = $i;
                }

            } else {

                warn "Can't normalize feature $name: non-numeric";
                return undef;

            }
        }

        for (my $i = 0; $i < @sents; $i++) {
            my $value = $self->get_sentence_feature($i, $name);
            my $new_value = 1;
            unless ($max == $min) {
                $new_value = ($value - $min) / ($max - $min);
            }
            $self->set_sentence_feature($i, $name => $new_value);
        }

    } else {
        return undef;
    }

}

sub get_sentence_score {
    my $self = shift;
    my $index = shift;
    my $scores = $self->{sent_scores};
    unless ($self->sentence_index_in_range($index) and defined $scores) {
        return undef;
    }
    return $scores->[$index];
}

sub get_sentence_scores {
    my $self = shift;
    my $scores = $self->{sent_scores};
    if (defined $scores) {
        return @$scores;
    } else {
        return undef;
    }
}

sub set_sentence_score {
    my $self = shift;
    my $index = shift;
    my $score = shift;
    my $scores = $self->{sent_scores};

    unless (defined $scores) {
        $scores = [];
        my @sents = $self->get_sentences();
        for (@sents) {
            push @$scores, 0;
        }
        $self->{sent_scores} = $scores;
    }

    unless ($self->sentence_index_in_range($index) and defined $score) {
        return undef;
    }
    $scores->[$index] = $score;
    return 1;
}


sub sentence_scores_computed {

    my $self = shift;
    my @scores = $self->get_sentence_scores();
    return @scores;

}


sub set_document_feature {

    my $self = shift;
    my %features = @_;

    return undef unless (keys %features > 0);

    my $added = 0;
    foreach my $feature_name (keys %features) {
        if (defined $features{$feature_name}) {
            $self->{doc_feats}->{$feature_name} =
                $features{$feature_name};
            $added++;
        }
    }

    return $added;

}


sub get_document_features {

    my $self = shift;

    my $feat_ref = $self->{doc_feats};
    return %$feat_ref;

}


sub get_document_feature {

    my $self = shift;
    my $name = shift;

    if (defined $self->{doc_feats}->{$name}) {
        return $self->{doc_feats}->{$name};
    } else {
        return undef;
    }

}

sub remove_document_features {

    my $self = shift;
    my %features = $self->get_document_features();

    foreach my $name (keys %features) {
                $self->remove_document_feature($name);
    }

}

sub remove_document_feature {

    my $self = shift;
    my $name = shift;

    if (exists $self->{doc_feats}->{$name}) {
        delete $self->{doc_feats}->{$name};
        return 1;
    } else {
        return undef;
    }

}


sub compute_document_features {

    my $self = shift;
    my %features = @_;

    foreach my $name (keys %features) {
        $self->compute_document_feature(
                    name => $name,
            feature => $features{$name} );
    }

}

sub compute_document_feature {

    my $self = shift;
    my %params = @_;

    my ($name, $sub) = ($params{name}, $params{feature});
    return undef unless (defined $name and defined $sub);

    my %sub_params = (
        document => $self,
    );

    my $value;
    eval {
        $value = &$sub(%sub_params);
    };

        my $did = $self->get_id() || "no id";
    if ($@) {
        warn "Feature $name died processing document $did: $@";
    } elsif (not defined $value) {
        warn "Feature $name returned undef document $did";
    } else {
        $self->set_document_feature($name => $value);
    }

    return 1;

}


sub get_summary {

    my $self = shift;
    my %params = @_;

    unless ($self->sentence_scores_computed()) {
        warn "get_summary called on document where scores not defined";
        return undef;
    }
    my @scores = $self->get_sentence_scores();
    my %score_map;
    for (my $i = 0; $i < @scores; $i++) {
        $score_map{$i} = $scores[$i];
    }
    my $size = $params{size};
    $size = scalar @scores unless (defined $size and $size > 0);

    # Get the top scoring sentences, will sort them later
    my @sents = $self->get_sentences();
    print scalar(@sents),"\n";
    my @summary;
    my $sortsub = sub { $score_map{$b} <=> $score_map{$a} };
    foreach my $i (sort $sortsub keys %score_map) {
        last if (scalar @summary == $size);
        my %feats = $self->get_sentence_features($i);
        my $sent = {
            'index' => $i,
            'text' => $sents[$i],
            'features' => \%feats,
            'score' => $self->get_sentence_score($i)
        };
        push @summary, $sent;
    }

    # Return the sentences according to their original position in the
    # document (unless the programmer explicitly says not to preserve
    # the order).
    if (defined $params{preserve_order}) {
        return @summary;
    } else {
        my $sortsub = sub { $a->{'index'} <=> $b->{'index'} };
        return sort $sortsub @summary;
    }

}

sub is_numeric_feature {

    my $self = shift;
    my $name = shift;
    my @sents = $self->get_sentences();
    foreach my $i (0 .. $#sents) {
        my $value = $self->get_sentence_feature($i, $name);
        unless (defined $value and looks_like_number($value)) {
            return 0;
        }
    }
    return scalar @sents;

}

# ***DEPRECATED (J. DePeri): use either Clair::Document::split_into_words, or Clair::Utils::TFIDFUtils::split_words
sub split_words {

    my $text = shift;
    my $punc = shift;

    return Clair::Utils::TFIDFUtils::split_words($text, $punc);

}

### The following old subroutine has been superseded by the above (J. DePeri)

sub split_words_deprecated {

    my $text = shift;

    my @words = split /\s|\,|\-|\(|\)|¡@|¡]|¡\^|¡A|¡B|¡C|¡u|¡m|¡n|¡F|¡þ|¡v|¡G|¡H|¡S|¡T|¡I|\?|\!|¡§|¡¨|¡y|¡z|\./, $text;

    my @ret = ();

    foreach my $w (@words) {
        next if $w =~ /^$/;
        push @ret, $w;
    }

    return @ret;

}

1;


=head1 NAME

Clair::Document - Document Class for the CLAIR Library

=head1 VERSION

Version 1.02

=head1 SYNOPSIS

This module is one of the core modules for the CLAIR library.  The Document
holds all of of the text of a file.  Different operations such as stemming,
stripping html, word counting, among others can be performed on a Document.

=head1 METHODS

=head2 new

$docref = new Clair::Document(string => 'Document text', type => 'text', id => 'doc' class => 'label');

Creates a new document from a filename or string and assigns it the specified
class label. First argument is either "string" or "file" to identify which
method will be used.  If "string" is used then the second argument should be
a string representing the full text or html content of the file.  If "file"
is used then the second argument should be the filename to be used for input.
The filename for a "string" input is undefined.  Use 'set_filename()' to define
this parameter.

=head2 count_words

Counts the number of words contained within the text of the document.  In order
to use properly first instantiate a Document object with a file or a string, then
call this method on it.

=head2 print

Prints the contents of Document to standard output

=head2 save

        save(file => 'out.txt', type => 'text')

Saves the contents of Document to a file.

=head2 strip_html

Removes all tags from html of Document.  Resulting string is saved as the text
of Document, then returned.

=head2 get_sent

Depricated. Use get_sentences instead. Returns sentences of the document

=head2 get_sentences

Returns the sentences of the document.

=head2 get_id

Returns the id of Document

=head2 get_class

$class = $docref->get_class()

Returns the class label of Document (for use in text classification).

=head2 get_parent_document

Returns the parent document of the document. Used if the document is a sentence
or line taken from another document to allow backtracking to the original document.

=head2 set_parent_document

Sets the parent document of the document. Used if the document is a sentence or
line taken from another document to allow backtracking to the original document.

=head2 split_into_words

Returns the list of words in the document.  Defaults to the text of the document
but can be set to stem or html by passing an optional type argument: split_into_words(type => 'stem')

=head2 get_unique_words(type => 'stem')

Returns a list of unique words in the document. Defaults to extracting these
words from the the stemmed version of the document, but can be set to text or
html by passing an optional type argument: get_unique_words(type => 'stem')

=head2 set_id

        set_id(id => 'new_id')

Sets the id of Document.

=head2 set_class

        $docref->set_class('label')

Sets the class label of Document.

=head2 get_xml

Returns the xml value of a document.

=head2 get_text

Returns the text value of a document.

=head2 get_html

Returns the html value of a document.

=head2 get_stem

Returns the stemmed version of the Document. If the text has not already been
stemmed, it will first call stem() and then save and return the results.

=head2 stem

Stems the Document text

=head2 stem_keep_newlines

Stems the document, but without removing the newlines.  This is needed by some
methods to track where a word came from or to treat lines individually.  Saves
the result as the stemmed version of the document, then returns it


=head2 split_into_lines

Splits the document into an array at newlines


=head2 split_into_sentences

Splits the document into an array of sentences (uses Text::Sentence to split the
document) (A future version will allow the user to specify via lib/Clair/Config.pm
whether they'd prefer to use MxTerminator over Text::Sentence.)

=head2 filter_sentences

        filter_sentences( matches => "regex" )
        filter_sentences( test => $sub )

Applies a filter to the sentences in this document and returns a new Clair::Document
containing the sentences that passed the filter. The filter can either be a
regular expression (with the matches parameter) or a subroutine references
(with the test parameter). The id of the new document will be the same as the
original document (if the original id is defined).


=head2 xml_to_text

Converts an XML document to text.

=head2 tf

        tf( type => "stem" )

Splits the document into terms of the given type, then returns a hash containing
the term frequencies.


=head2 sentence_count

Returns the total number of sentences in this document.


=head2 sentence_index_in_range($i)

Returns true of there is a sentence with index $i, false otherwise. Sentence
indexing starts at 0.


=head2 set_sentence_feature($i, %features)

Sets the given features for sentence with index $i. Returns undef if $i insn't
in the sentence range or if no features are given. Otherwise returns the number
of features added to the given sentence. %features should be a hash mapping names
to values. For example, set_sentence_feature(1, f1 => 1, f2 => 0.5, f3 => "red")
sets those features to the second sentence.


=head2 get_sentence_features($i)

Returns a hash mapping the feature names to values of the given sentence.
Returns undef if the sentence index is out of range.


=head2 get_sentence_feature($i, $name)

Returns the value of the given feature for the given sentence. Returns undef if
the index is out of range or if the feature isn't defined for the sentence.


=head2 remove_sentence_features()

Removes all features from every sentence.


=head2 remove_sentence_feature($i, $name)

Removes the given feature from the given sentence. Returns true if succesfully
removed, returns undef otherwise.


=head2 compute_sentence_features( f1 => $subref1, f2 => $subref2, ... )

Computes the specified features for each sentence in the document by calling
$self->compute_sentence_feature(fN => $subrefN) for each feature.


=head2 compute_sentence_feature( name => $name, feature => $subref, normalize => 1 )

Computes the given feature for each sentence in the document. The feature
parameter should be a reference to a subroutine. The subroutine will be called with the following parameters defined:

=over 8

=item * document - A reference to the document object

=item * sentence - The sentence text

=item * sentence_index - The index of the sentence

=item * state - A hash reference that is kept in memory between calls to the
subroutine. This lets $subref save precomputed values or keep track of inter-sentence
relationships.

=back

A feature subroutine should return a value. Any exceptions thrown by the feature
subroutine will be caught and a warning will be shown. If a feature subroutine
returns an undefined value, the feature will not be set and awarning will be shown.
This method returns undef if either name or feature are not defined.

The normalize parameter, if set to a true value, will scale the values of this
feature so that the minimum value is 0 and the maximum value is 1. Nothing will
happen if any of the feature values are non-numeric.


=head2 normalize_sentence_features(@names)

Scales the given features so that the minimum value is 0 and the maximum value
is 1 for each feature.



=head2 normalize_sentence_feature($name)

Scales the values of the given feature so that the minimum value is 0 and the
maximum value is 1. Nothing will happen if any of the feature values are non-numeric.


=head2 compute_sentence_features( %features );

Computes a set of features on each sentence. %features should be a hash mapping
names to sub references. See compute_sentence_feature for more information.


=head2 get_sentence_score($i)

Returns the score of the sentence with index $i. Returns undef if $i is out of
range or if the score has not been defined yet.


=head2 get_sentence_scores()

Returns an array of the sentence scores. If the scores haven't been set, returns
undef.


=head2 set_sentence_score($i, $score)

Sets the score of the sentence with the given index. Returns undef if $i is out
of range or if $score is undef. Otherwise returns 1.


=head2 normalize_sentence_scores

Scales the scores of the sentences so that the max score is 1 and the min score
is 1. If the max score is equal to the min score, then all of the scores are set
to 1. If the scores are undefined, then returns undef. Otherwise, returns 1.


=head2 score_sentences

        score_sentences( combiner => $subref, normalize => 0, weights => \%weights )

Scores the sentences using the given combiner. A combiner subroutine will be
passed a hash comtaining feature names mapped to values and should return a real
number. By default, the sentence scores will be normalized unless normalize is set
to 0. If the combiner does not return an appropriate value for each sentence,
score_sentences returns undef and the sentence scores are left uncomputed.

Alternatively, if a hash reference is specified for the parameter weights, then
the returned score will be a linear combination of the features specified in
weights according to their given weights. This option will override the combiner
parameter.


=head2 sentence_scores_computed

Returns true if each sentence has a score, false otherwise.

=head2 set_document_feature

        $docref->set_document_feature(%features)

Sets the specified features for the document. Returns undef if no features are given.
Otherwise returns the number of features added to the document. %features should
be a hash mapping feature names to values. For example,
set_document_feature(f1 => 1, f2 => 0.5, f3 => "red") sets those features for the document.


=head2 get_document_features()

        $features = $docref->get_document_features()

Returns a hash mapping the document's feature names to values.


=head2 get_document_feature($name)

        $val = $docref->get_document_feature($name)

Returns the value of the given feature for the document. Returns undef if the
feature isn't defined for the document.


=head2 remove_document_features

        $docref->remove_document_features()

Removes all features from the document.


=head2 remove_document_feature

        $docref->remove_document_feature($name)

Removes the given feature from the document Returns true if succesfully removed,
returns undef otherwise.


=head2 compute_document_features

        $docref->compute_document_features( f1 => $subref1, f2 => $subref2, ... )

Computes the specified features for the document by calling
$self->compute_document_feature(fN => $subrefN) for each feature.


=head2 compute_document_feature

        compute_document_feature( name => $name, feature => $subref );

Computes the given feature for the document. The feature parameter should be
a reference to a subroutine. The subroutine will be called with the following
parameter defined:

=over 8

=item * document - A reference to the document object

=back

A feature subroutine should return a value. Any exceptions thrown by the feature
subroutine will be caught and a warning will be shown. If a feature subroutine
returns an undefined value, the feature will not be set and a warning will be shown.
This method returns undef if either name or feature are not defined.


=head2 get_summary

        get_summary( size => 10, preserve_order => 0 )

Returns a summary of this document based on the sentence scores. If the scores
haven't been computed, returns undef. A summary is an array of hash references.
Each hash reference represents a sentence and contains the following key/value pairs:

=over 8

=item * index - The index of this sentence (starting at 0).

=item * text - The text of this sentence.

=item * features - A hash reference of this sentence's features.

=item * score - The score of this sentence.

=back

The size parameter to this method sets the maximum length of the summary in number
of sentences. The preserve_order parameter controls how the sentences are ordered.
If preserve_order is set to 0, then the sentences will be returned in descending
order by score. If preserve_order is set to a true value (or undefined), the original
order of the sentences from the document will be preserved. preserve_order => 1 is
 the default behavior.


Here is an example of the object returned by this method:

@summary = (
{ index => 0,
text => "Roses are red.",
features => { has_flower => 1, position => 1 },
score => 1 },
{ index => 2,
text => "Sugar is sweet.",
features => {has_flower => 0, position => 0.5 },
score => 0.75 }
);


=head2 is_numeric_feature

        is_numeric_feature($name)

Returns true if the given feature has a numeric value for all sentences.


=head1 AUTHOR

Dagitses, Michael << <clair at umich.edu> >>
Radev, Dragomir << <radev at umich.edu> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-clair-document at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=clairlib-dev>.
I will be notified, and then you will automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

perldoc Clair::Document

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/clairlib-dev>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/clairlib-dev>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=clairlib-dev>

=item * Search CPAN

L<http://search.cpan.org/dist/clairlib-dev>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 The University of Michigan, all rights reserved.

This program is free software; you can redistribute it and/or modify it  under
the same terms as Perl itself.

=cut

sub normalize_sentence_scores {

    my $self = shift;
    my $total = $self->sentence_count();
    my @scores = $self->get_sentence_scores();

    if (@scores) {

        my ($max, $min)  = ($scores[0], $scores[0]);
        my ($max_index, $min_index) = (0, 0);

        foreach my $i (0 .. $total - 1) {
            my $score = $scores[$i];
            if ($score > $max) {
                $max = $score;
                $max_index = $i;
            }
            if ($score < $min) {
                $min = $score;
                $min_index = $i;
            }
        }

        my @new_scores;
        if ($max == $min) {
            @new_scores = (1) x $total;
        } else {
            #@new_scores = map { ($_ - $min) / ($max - $min) } @scores;
        }

        foreach my $i (0 .. $total - 1) {
            $self->set_sentence_score($i, $new_scores[$i]);
        }
        return 1;

    } else {
        return undef;
    }

}

sub new {

        my $class = shift;

       # Clair::Utils::MxTerminator::init;

        my %parameters = @_;

        my $type = $parameters{type};

        if (!defined $type) {
                $type = "text";
        }

        if ($type ne 'html' && $type ne 'text' && $type ne 'stem' && $type ne 'xml') {
                die('Document::new1 - Illegal value of type parameter.');
        }

        my $file     = $parameters{file};
        my $string   = $parameters{string};
        my $id       = $parameters{id};
        my $language = $parameters{language};
        my $label    = $parameters{class};

        if (defined $file && defined $string) {
                die('Document::new - Both file and string defined.');
        }

        my $body;

        if (defined $file) {
                #print "file = $file\n";
                open FILE, "<$file"
                or die("Document::new - Could not open file: $file");

                $body = q{};
                while (my $line = <FILE>) {
                        $body .= $line;
                }
        }
        elsif (defined $string) {
                $body = $string;
        }
        else {
                die('Document::new - Neither file nor string defined.');
        }

        my $self = bless {
                $type    => $body,
                id       => $id,
                language => $language,
                class    => $label
        }, $class;

        return $self;
}