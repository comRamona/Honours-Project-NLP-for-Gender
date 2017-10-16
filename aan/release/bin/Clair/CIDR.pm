package Clair::CIDR;

=head1 NAME

Clair::CIDR - single pass document clustering

=head1 SYNOPSIS

    my $cluster;
    # ...
    my $cidr = Clair::CIDR->new();
    my @results = $cidr->cluster($cluster);
    foreach my $result (@results) {
        my $subcluster = $result->{cluster};
        my $centroid = $result->{centroid};
    }

=head1 DESCRIPTION

This is a clairlib implementation of the version of CIDR described in
"A Description of the CIDR System as Used for TDT-2" (Radev, et al. 1999),
which is a single pass clustering algorithm with modifications used to reduce
running time. There are five parameters:

=over 4

=item decay_threshold

A positive integer such that only the first decay_threshold  words of each
document will be used in the similarity measure. The default value is 200.

=item idf_threshold

A positive real number such that words w with idf(w) < idf_threshold  will not
be considered in the similarity measure. The default value is 3.

=item keep_words

A positive integer such that cluster centroids will consist of at most
keep_words words (with the exception of the next point). The default value is
20.

=item keep_threshold

A positive real number such that words w satisfying tf*idf(w) >= keep_threshold
will be added to cluster centroids (even if this means the number of words in
the centroid is greater than K). The default value is 8.

=item sim_threshold

A number in [0,1] specifying the minimum similarity between a document and a
cluster centroid for the document to be added to the cluster. The default
value is 0.1.

=back

There is another version of CIDR in the Clair Library, L<CIDR::Wrapper> that
is a wrapper around an older perl script.

=head2 METHODS

=over 4

=item * new(%params)

Creates a new instance of CIDR with the given parameters from the
description section. An additional parameter, verbose, will print messages
to STDERR if set to a true value.

=item * param(%params)

Sets the given parameters.

=item * cluster($cluster)

Takes a Clair::Cluster object and runs the clustering algorithm on it. Returns
an array containing hash references. Each hash reference maps "cluster" to
a subcluster and "centroid" to that cluster's centroid (a hashref mapping
words to tf*idf values).

=back

=head1 AUTHOR

Tony Fader, afader@umich.edu

=head1 SEE ALSO

L<CIDR::Wrapper>

=cut

use strict;
use Carp;
use Clair::Document;
use Clair::Cluster;
use Clair::Utils::SimRoutines;
use Clair::IDF;
use Clair::Centroid;

sub new {
    my $class = shift;
    my %params = @_;

    # Set defaults if necessary
    my %defaults = (
        decay_threshold => 200,
        idf_threshold => 3,
        keep_words => 20,
        keep_threshold => 8,
        sim_threshold => 0.1,
        verbose => 0
    );
    foreach my $key (keys %defaults) {
        unless (defined $params{$key}) {
            $params{$key} = $defaults{$key};
        }
    }

    my $self = { _params => \%params };
    bless $self, $class;
    return $self;
}

sub param {
    my $self = shift;
    my %params = @_;
    foreach my $key (keys %params) {
        $self->{_params}->{$key} = $params{$key};
    }
}

# The clustering happens in here
#
sub cluster {

    my $self = shift;
    my $cluster = shift;
    my $verbose = $self->{_params}->{verbose};

    # Cluster size must be > 1
    if ($cluster->count_elements() <= 1) {
        print STDERR "Cluster must be >= 2 docs\n" if $verbose;
        return undef;
    }

    my $docsref = $cluster->documents();
    my @docs = values %$docsref;

    # Keep track of three things: clusters, clusters of sketches, and centroids
    my @cluster_sketches;
    my @clusters;
    my @centroids;

    for (my $i = 0; $i < @docs; $i++) {

        my $doc = $docs[$i];
        my $did = $doc->get_id();
        print STDERR "Sketching document $did\n" if $verbose;
        my $sketch = $self->_sketch_document($doc);

        # If this is the first document, make a new cluster
        if ($i == 0) {

            print STDERR "First document, making new cluster\n" if $verbose;

            my $sclust = Clair::Cluster->new();
            my %centroid = $self->_insert_into_sketch_cluster($sketch, $sclust);
            my $clust = Clair::Cluster->new();
            $clust->insert($doc->get_id(), $doc);

            push @cluster_sketches, $sclust;
            push @clusters, $clust;
            push @centroids, \%centroid;

        # Otherwise, find the cluster with the maximum similarity to the doc.
        # If it is >= sim_threshold, add the doc to the cluster.
        } else {

            my $max_sim = 0;
            my $max_index = 0;
            for (my $j = 0; $j < @centroids; $j++) {
                my $sim = $self->_sim_centroid_doc($centroids[$j], $sketch);

                print STDERR "Document $did vs. cluster $j: $sim\n" if $verbose;

                if ($sim > $max_sim) {
                    $max_sim = $sim;
                    $max_index = $j;
                }
            }

            my $sim_threshold = $self->{_params}->{sim_threshold};
            if ($max_sim >= $sim_threshold) {

                # Insert the document sketch into the cluster and update
                # the centroid.
                my $max_scluster = $cluster_sketches[$max_index];
                my $max_cluster = $clusters[$max_index];
                my %centroid = $self->_insert_into_sketch_cluster(
                    $sketch, $max_scluster);
                $centroids[$max_index] = \%centroid;
                $max_cluster->insert($doc->get_id(), $doc);

                print STDERR "Added document $did to $max_index\n" if $verbose;

            } else {

                # Create a new cluster and get its centroid.
                my $scluster = Clair::Cluster->new();
                my %centroid = $self->_insert_into_sketch_cluster(
                    $sketch, $scluster);
                my $cluster = Clair::Cluster->new();
                $cluster->insert($doc->get_id(), $doc);
                push @clusters, $cluster;
                push @cluster_sketches, $scluster;
                push @centroids, \%centroid;

                print STDERR "Created new cluster for doc $did\n" if $verbose;
            }

        }

    }

    # Return a list of hashrefs
    my @results;
    for (my $k = 0; $k < @clusters; $k++) {
        push @results, {
            cluster => $clusters[$k],
            centroid => $centroids[$k]
        };
    }
    return @results;

}

# Returns the cosine similarity between a centroid (hashref) and a
# Clair::Document.
#
sub _sim_centroid_doc {

    my $self = shift;
    my $centroid = shift;
    my $doc = shift;

    my $doc_text = $doc->get_text();
    my $centroid_text = join " ", keys %$centroid;

    my $sim = GetLexSim($doc_text, $centroid_text);

    return $sim;

}

# Returns the "sketch" of a given document. The sketch is obtained by
#  1) taking the first $decay_threshold words
#  2) removing words w such that idf(w) < $idf_threshold
#
sub _sketch_document {

    my $self = shift;
    my $doc = shift;
    my $decay_threshold = $self->{_params}->{decay_threshold};
    my $idf_threshold = $self->{_params}->{idf_threshold};

    # get the first decay_threshold words in lowercase
    my @words = map lc, $doc->split_into_words();
    @words = splice @words, 0, $decay_threshold;

    # filter out low idf words
    my @result_words;
    for (my $i = 0; $i < @words; $i++) {
        my $word = $words[$i];
        my $idf = get_nidf($word);
        if ($idf >= $idf_threshold) {
            push @result_words, $word;
        }
    }

    my $text = join " ", @result_words;

    my $sketch = Clair::Document->new(
        type => "text",
        string => $text,
        id => $doc->get_id()
    );

    return $sketch;

}

# This sub does the following:
#  - inserts the given sketch document into the given sketch cluster
#  - computes the centroid for the sketch cluster
#  - returns the centroid as a hash
#
sub _insert_into_sketch_cluster {

    my $self = shift;
    my $doc = shift;
    my $cluster = shift;

    $cluster->insert($doc->get_id(), $doc);

    # compute the new centroid for the cluster
    my $cluster_centroid_obj = Clair::Centroid->new();
    my $docs = $cluster->documents();
    foreach my $did (keys %$docs) {
        $cluster_centroid_obj->add_documents( $docs->{$did}->get_text() );
    }

    # TODO: make it so these private methods don't have to be called
    # in Clair::Centroid.
    $cluster_centroid_obj->_build_centroid();
    my $cluster_centroid = $cluster_centroid_obj->{centroid};

    # now make the cluster centroid the appropriate number of words,
    # allowing for high tfidf words to be added
    my @sorted_words =
        sort { $cluster_centroid->{$b} <=> $cluster_centroid->{$a} }
        keys %$cluster_centroid;

    my $keep_words = $self->{_params}->{keep_words};
    my $keep_threshold = $self->{_params}->{keep_threshold};
    my %final_centroid = ();
    my $size = 0;
    foreach my $word (@sorted_words) {
        if ($size < $keep_words) {
            $final_centroid{$word} = $cluster_centroid->{$word};
            $size++;
        } else {
            my $tfidf = $cluster_centroid->{$word};
            if ($tfidf >= $keep_threshold) {
                $final_centroid{$word} = $cluster_centroid->{$word};
                $size++;
            }
        }
    }

    return %final_centroid;

}

1;
