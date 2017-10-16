package Clair::SentenceFeatures;

=head1 NAME

Clair::SentenceFeatures - a collection of sentence feature subroutines

=head1 SYNOPSIS

    use Clair::SentenceFeatures qw(length_feature);
    use Clair::Document;
    my $doc = Clair::Document->new( ... );
    $doc->compute_sentence_feature(name => "length",
        length_feature => \&length_feature );

=head1 DESCRIPTION

This module contains sentence feature scripts to use with the
compute_sentence_feature methods in L<Clair::Document> and L<Clair::Cluster>.

=head1 METHODS

=over 4

=item * position_feature

Returns (T - i) / T, where T is the total number of sentences in the document
and i is the index of the sentence (starting at 0). Returns undef if T == 0.

=item * length_feature

Returns the length (number of words) of the sentence.

=item * centroid_feature

Returns the similarity of the sentence with the document or cluster centroid.

=item * sim_with_first_feature

Returns the similarity of the sentence with the first sentence in the
document.

=back

=head1 SEE ALSO

L<Clair::Document>, L<Clair::Cluster>.

=cut

use strict;
use Carp;
use Exporter;
use Clair::Config;
use Clair::IDF;
use Clair::Centroid;
use Clair::Utils::SimRoutines;

our (@ISA, @EXPORT_OK, %EXPORT_TAGS);
@ISA = qw(Exporter);
@EXPORT_OK = (
    "position_feature", "length_feature", "centroid_feature",
    "sim_with_first_feature"
);
%EXPORT_TAGS = (
    all => \@EXPORT_OK
);

sub position_feature {
    my %params = @_;
    my $total = scalar $params{document}->sentence_count();
    my $index = $params{sentence_index};
    if ($total > 0) {
        return ($total - $index) / $total;
    } else {
        return undef;
    }
}

sub length_feature {
    my %params = @_;
    my $sent_doc = Clair::Document->new(string => $params{sentence});
    my @words = $sent_doc->split_into_words();
    return scalar @words;
}

sub centroid_feature {

    my %params = @_;
    my $state = $params{state};

    # Pre-compute the centroid
    unless (defined $state->{initialized}) {

        my $text;
        if (defined $params{cluster}) {
            $text = $params{cluster}->get_text();
        } else {
            $text = $params{document}->get_text();
        }

        open_nidf("$MEAD_HOME/etc/enidf");
        my $centroid = Clair::Centroid->new();
        $centroid->add_document($text);
        $state->{centroid} = $centroid;

        $state->{initialized} = 1;
    }

    my $sent = $params{sentence};
    return $state->{centroid}->centroid_score($sent);


}

sub sim_with_first_feature {
    my %params = @_;
    my @sents = $params{document}->get_sentences();
    my $sent = $params{sentence};
    my $first_sent = $sents[0];

    return GetLexSim($sent, $first_sent);

}

1;
