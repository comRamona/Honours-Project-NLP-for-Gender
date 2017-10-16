package Clair::LM::Ngram;

use warnings;
use strict;

require Exporter;
use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(load_ngramdict
                dump_ngramdict
                extract_ngrams
                write_ngram_counts
                enforce_count_thresholds
                traverse_ngramdict);

use Carp;
use Clair::Utils::TFIDFUtils qw(split_words
                                lc_words);
use Storable qw(nstore
                retrieve);

our $VERSION = '1.00';
our $SENTENCE_DELIMITER = '<s>';



sub load_ngramdict
{
    my %params = @_;

    my $file = $params{infile};

    my ($N, $r_ngramdict) = @{retrieve($file)} or croak "\nUnable to restore serialized n-gram dictionary from file $file";

    return ($N, $r_ngramdict);
}


sub dump_ngramdict
{
    my %params = @_;

    my $N           = $params{N};
    my $r_ngramdict = $params{ngramdict};
    my $file        = $params{outfile};

    nstore([$N, $r_ngramdict], $file) or croak "\nUnable to serialize n-gram dictionary to file $file";
}


sub extract_ngrams
{
    my %params = @_;

    my $r_cluster   = $params{cluster};
    my $r_ngramdict = $params{ngramdict};
    my $N           = $params{N};
    my $format      = $params{format};
    my $stem        = $params{stem};
    my $segment     = $params{segment};
    my $verbose     = $params{verbose};

    print "Stripping html markup ...\n" if ($verbose);
    $r_cluster->strip_all_documents() if ($verbose and ($format eq "html"));
    print "Stemming ...\n" if ($verbose and $stem);
    $r_cluster->stem_all_documents() if $stem;

    print $r_cluster->count_elements . " documents in cluster\n";
    my $cnt = 0;
    foreach my $r_doc (values %{$r_cluster->{documents}}) {
        #print "Extracting $N-grams from ", $r_doc->get_id(), " ...\n" if ($verbose);
      $cnt++;
      if (($cnt % 1000) == 0) {
        print "Extracted $N-grams from $cnt documents\n";
      }
        my @words;
        if ($segment) {

          my $type = ($stem ? 'stem' : 'text');
          my @sentences = $r_doc->split_into_sentences(type => $type);
            if (scalar @sentences) {
                # Pad with initial dummy sentence boundaries
                for (1..$N-1) {
                    push @words, $SENTENCE_DELIMITER;
                }
                foreach my $sentence (@sentences) {
                    my @sentence_words = lc_words(split_words($sentence, 0));
                    if (scalar @sentence_words) {
                        push @words, @sentence_words;
                        # Separate each sentence with a sentence boundary
                        push @words, $SENTENCE_DELIMITER if ($N > 1);
                    }
                }
                # Pad with final dummy sentence boundaries
                for (1..$N-2) {
                    push @words, $SENTENCE_DELIMITER;
                }
            }
        }
        else {
            # Split document text directly into words
            my $type = ($stem ? 'stem' : 'text');
            @words = lc_words($r_doc->split_into_words(type => $type,
                                                       punc => 0));
        }

        for (my $i = 0; $i < scalar @words - $N + 1; $i++) {
            my @ngram = @words[$i..$i+$N-1];

            my $r_entry = $r_ngramdict;
            for (my $j = 0; $j < $N; $j++) {
                my $term = $ngram[$j];
                if ($j < $N - 1) {
                    # Autovivify to extend hash table a level deeper
                    $r_entry->{$term} = {} if not defined $r_entry->{$term};
                    $r_entry = $r_entry->{$term};
                } else {
                    # Increment the current N-gram's occurrence count (value paired with $Nth-level key)
                    $r_entry->{$term}++;
                }
            }
        }
    }
}

sub write_ngram_counts
{
    my %params = @_;

    my $r_ngramdict = $params{ngramdict};
    my $N           = $params{N};
    my $file        = $params{outfile};
    my $sort        = $params{sort};

    open(local *fh, '>', $file) or croak "\nUnable to open $file for writing.";
    my @ngram;
    if ($sort) {
        my @ngrams;
        # Get list of N-gram counts
        traverse_ngramdict($N, $r_ngramdict, \@ngram, \&sort_ngrams, [\@ngrams]);
        # Sort N-grams in decreasing order by number of occurrences
        @ngrams = sort { $b->[1] <=> $a->[1] } @ngrams;
        @ngrams = map(join(" ", (@$_, $/)), @ngrams);
        print { *fh } @ngrams;
    } else {
        # Write N-gram counts to file
        traverse_ngramdict($N, $r_ngramdict, \@ngram, \&write_ngrams_fromdict, [\*fh]);
    }
    close(*fh);
}


sub enforce_count_thresholds {
    my %params = @_;

    my $N           = $params{N};
    my $r_ngramdict = $params{ngramdict};
    my $mincount    = $params{mincount};
    my $topcount    = $params{topcount};

    my @counts;
    # Prune away N-grams below minmum count threshold
    traverse_ngramdict($N, $r_ngramdict, undef, \&delete_belowthresholds, [$mincount, $topcount, \@counts]);

    # If top K criterion is specified ...
    if (defined $topcount and $topcount < scalar @counts) {
        @counts = sort { $b <=> $a} @counts;

        # Determine cutoff for top K and prune away N-grams below
        my $cutoff = $counts[$topcount - 1];
        traverse_ngramdict($N, $r_ngramdict, undef, \&delete_belowthresholds, [$cutoff, undef, undef])
    }
}


# ----------------------------------------------------------------------------------------
#  sub traverse_ngramdict (private)  : tail-recursively traverse an N-gram dictionary hash
#                                      down to its leaves, applying a hook function
#                                      to each leaf key
#
#  Parameters:
#    $N           => : N
#    $r_ngramdict => : hashref reference to some level of the N-gram dictionary
#    $r_ngram     => : arrayref to the part of the N-gram constructed so far
#                      (at the current level of the dictionary)
#    $r_hook      => : coderef to hook function to apply at each dictionary leaf
#    $r_args      => : arrayref to array of arguments to the hook function
# ----------------------------------------------------------------------------------------
sub traverse_ngramdict
{
    my $N           = shift;
    my $r_ngramdict = shift;
    my $r_ngram     = shift;
    my $r_hook      = shift;
    my $r_args      = shift;

    # At inner levels ...
    if ($N > 1) {
        foreach my $term (keys %$r_ngramdict) {
            # [Stack idiom]
            push @$r_ngram, $term if defined $r_ngram;
            traverse_ngramdict($N-1, $r_ngramdict->{$term}, $r_ngram, $r_hook, $r_args);
            pop @$r_ngram if defined $r_ngram;
        }
    }
    # At leaf level ...
    else {
        &$r_hook($r_ngramdict, $r_ngram, $r_args);
    }
}


# ----------------------------------------------------------------------------------------
#  sub delete_belowthresholds (private)  : hook function to delete from dictionary N-grams
#                                          that fail to satisfy count thresholds
#
#  Parameters:
#    $r_ngramdict => : hashref reference to some level of the N-gram dictionary
#    $r_ngram     => : arrayref to the part of the N-gram constructed so far
#                      (at the current level of the dictionary)
#    $r_args      => : arrayref to array of arguments
# ----------------------------------------------------------------------------------------
sub delete_belowthresholds {
    my $r_ngramdict = shift;
    my $r_ngram = shift;
    my $r_args = shift;

    my ($mincount, $topcount, $r_counts) = @$r_args;

    foreach my $term (keys %$r_ngramdict) {
        if (defined $mincount and $mincount > 1 and $r_ngramdict->{$term} < $mincount) {
            delete $r_ngramdict->{$term};
        } elsif (defined $topcount) {
            push @$r_counts, $r_ngramdict->{$term}
        }
    }
}


# -----------------------------------------------------------------------------
#  sub sort_ngrams (private)  : hook function to add N-grams at current leaf
#                               to unordered list of N-grams for later sorting
#
#  Parameters:
#    $r_ngramdict => : hashref reference to some level of the N-gram dictionary
#    $r_ngram     => : arrayref to the part of the N-gram constructed so far
#                      (at the current level of the dictionary)
#    $r_args      => : arrayref to array of arguments
# -----------------------------------------------------------------------------
sub sort_ngrams
{
    my $r_ngramdict = shift;
    my $r_ngram = shift;
    my $r_args = shift;

    my ($r_ngrams) = @$r_args;

    foreach my $term (keys %$r_ngramdict) {
        push @$r_ngrams, [join(" ", (@$r_ngram, $term)), $r_ngramdict->{$term}];
    }
}


# ----------------------------------------------------------------------------------------
#  sub delete_belowthresholds (private)  : hook function to delete from dictionary N-grams
#                                          that fail to satisfy count thresholds
#
#  Parameters:
#    $r_ngramdict => : hashref reference to some level of the N-gram dictionary
#    $r_ngram     => : arrayref to the N-gram constructed so far
#                      (at the current level of the dictionary)
#    $r_args      => : arrayref to array of arguments
# ----------------------------------------------------------------------------------------
sub write_ngrams_fromdict {
    my $r_ngramdict = shift;
    my $r_ngram = shift;
    my $r_args = shift;

    my ($r_fh) = @$r_args;

    my $buffer = "";
    foreach my $term (keys %$r_ngramdict) {
        $buffer .= (join(" ", (@$r_ngram, $term, $r_ngramdict->{$term})) . $/);
    }
    print $r_fh $buffer;
}



1;
__END__


=head1 NAME

Ngram - extract and prune N-grams from documents

=head1 VERSION

This documentation refers to Clair::LM::Ngram version 1.0.

=head1 SYNOPSIS

    use Clair::Cluster
    use Clair::Utils::Ngram qw(load_ngramdict
                               dump_ngramdict
                               extract_ngrams
                               write_ngram_counts
                               enforce_count_thresholds);

    # Read in documents
    my $r_cluster = Clair::Cluster->new;
    $r_cluster->load_documents("*.html",
                               type => 'html',
                               filename_id => 1);

    # Strip markup and stem resulting document contents, segment into sentences,
    #   and extract bigrams, storing the bigram dictionary in $r_ngramdict
    my $r_ngramdict = {};
    extract_ngrams(cluster   => $r_cluster,
                   N         => 2,
                   ngramdict => $r_ngramdict,
                   format    => 'html',
                   stem      => 1,
                   segment   => 1,
                   verbose   => 1 );

    # Remove all bigrams having fewer than 2 occurrences and/or not occurring
    #   in the top 100 most frequent
    enforce_count_thresholds(N => 2,
                             ngramdict => $r_ngramdict,
                             mincount  => 2,
                             topcount  => 100 );

    # Sort bigrams in descending order by count and write bigram dictionary to file
    write_ngram_counts(N         => 2,
                       ngramdict => $r_ngramdict,
                       outfile   => 'test.2grams',
                       sort      => 1 );

    # Serialize bigram dictionary to (network-ordered) Storable file
    dump_ngramdict(N         => 2,
                   ngramdict => $r_ngramdict,
                   outfile   => 'test.2grams.dump' );

    # Restore N-gram dictionary from Storable file
    my $N;
    ($N, $r_ngramdict2) = load_ngramdict(infile => 'test.2grams.dump');


=head1 DESCRIPTION

The Ngram package provides functionality for the extraction of N-grams from text and HTML
documents. The resulting N-gram dictionary can optionally be pruned of low-frequency
N-grams before being written to a human-readable text file and/or serialized to a
network-ordered Storable file.

=head1 FUNCTIONS

=over 4

=item extract_ngrams(cluster => I<CLUSTERREF>, N => I<INTEGER>, ngramdict => I<HASHREF>,
format => I<SCALAR>, stem => I<BOOL>, segment => I<BOOL>)

Extracts N-grams from the cluster of documents referenced by I<CLUSTERREF>, storing them
in an N-level-deep hash referenced by I<HASHREF>. The documents' format can be HTML ('html'),
in which case the documents are stripped of HTML markup, or text (the default). Setting
stem to 1 turns stemming on; setting segment to 1 turns sentence segmentation on. With
sentence segmentation on, the text of document is split into sentences prior to each
individual word's being lowercased and (optionally) stemmed.

If sentence segmentation is specified, then terms denoting sentence boundaries occur in N-grams
straddling sentence boundaries and are denoted by E<lt>sE<gt>. The first N-gram in a document
then contains N - 1 sentence boundary terms, followed by the first term occurring in the document
itself. The last N-gram in a document contains the last term occurring in the document itself,
followed by N - 1 sentence boundary terms. Such padded N-grams are counted with sentence
segmentation in order that, from a generative standpoint, the probabilies of occurrence from all
possible documents generated from the extracted N-gram language model sum to 1.

=item write_ngram_counts(N => I<INTEGER>, ngramdict => I<NGRAMDICTREF>, outfile => I<SCALAR>, sort => I<BOOL>)

Writes the N-gram dictionary referenced by I<NGRAMDICTREF> to file I<SCALAR>. If I<BOOL> is true, then
the N-grams are written in decreasing order by number of occurrences.

=item (I<SCALAR>, I<HASHREF>) = load_ngramdict(infile => I<SCALAR>)

Restores the N-gram dictionary in (network-ordered) Storable file I<SCALAR>. Sets I<SCALAR> equal to N
and stores a reference to the restored dictionary in I<HASHREF>.

=item dump_ngramdict(N => I<INTEGER>, ngramdict => I<NGRAMDICTREF>, outfile => I<SCALAR>)

Serializes the N-gram dictionary referenced by I<NGRAMDICTREF>, together with the value of N,
to (network-ordered) Storable file I<SCALAR>.

=item enforce_count_thresholds(N => I<INTEGER>, ngramdict => I<NGRAMDICTREF>,
mincount => I<INTEGER_1>, topcount => I<INTEGER_2>)

Prunes the N-gram dictionary referenced by I<NGRAMDICTREF> of all N-grams not among the top I<INTEGER_2>
in occurrences or having fewer than I<INTEGER_1> occurrences. The order of application of these two
constraints is immaterial.

=back

=head1 DEPENDENCIES

Clair::Cluster, Carp, Exporter, Storable

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Please report problems to Dragomir Radev << <radev at umich.edu> >>.
Patches are welcome.

=head1 AUTHOR

Jonathan DePeri << <jmd2118 at columbia.edu> >>

=head1 LICENSE AND COPYRIGHT

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Copyright 2007 the Clair group, all rights reserved.

=cut
