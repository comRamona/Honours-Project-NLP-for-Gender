package Clair::Algorithm::LSI;

use strict;
use warnings;

use Clair::Document;
use Lingua::Stem;
use Lingua::Stem::En;
use PDL::Basic;
use PDL::IO::Storable;
use PDL::Lite;
use PDL::Matrix;
use PDL::MatrixOps;
use PDL::Ufunc;
use Storable;


=pod

=head1 NAME

Clair::Algorithm::LSI

=head1 SYNOPSIS

Provides latent semantic indexing interfacing with Clair::Cluster. The interface provides
functionality for the construction of the index, which consist of the singular value
decomposition of the document-term matrix underlying the cluster, as well as for the
mapping and ranking of terms, documents, and queries into latent semantic space. Envisioned
for this package are further functionalities, as well as their refinements and optimizations.

=head1 METHODS


=head2 new

$index = Clair::Algorithm::LSI->new(type => "stem")

(public) Instantiates a new latent semantic index (LSI) from
         either an existing Clair::Cluster object or by loading
         a previously saved index from file. In the latter case,
         the originally associated cluster may have been saved
         together with the index or may not have been so saved.
         In the latter case, the user has the option of specifying
         an existing cluster to be (re-)associated with the index.

<B file>
A path to a file containing a previously saved index.

<B cluster>
A reference to a cluster to be newly associated to the index
to be built or reassociated to the existing index being loaded.

<B type>
(optional) the type of index (stemmed is the default)

=cut


=head2 build_index

$index->build_index();

(public) Constructs the latent semantic index, which is defined by
         the singular value decomposition of the associated cluster's
         document-term matrix. Sets the initial approximation to full
         rank (K = N).

=cut


=head2 get_approx_rank

$approx_rank = $index->get_approx_rank();

(public) Returns the rank K of the current approximation;
        where K <= N, the full rank of the approximation.

=cut


=head2 set_approx_rank

$index->set_approx_rank($K);

(public) Sets the rank K of the current approximation,
         where K <= N, the full rank of the approximation. If some
         K > N is specified, the rank K retains its previous value.

B<K>
The desired rank of the approximation.

=cut


=head2 term_to_latent_space

$v = $index->term_to_latent_space($term);

(public) Maps the specified term to its position vector in latent
         semantic space.

B<term>
The (unstemmed) term.

=cut


=head2 query_to_latent_space

$v = $index->query_to_latent_space($querystring);

(public) Maps the specified query to its position vector in latent
         semantic space. The query is treated exactly like a
         document the text of which is precisely the query text.

B<query>
The (unstemmed) query string.

=cut


=head2 doc_to_latent_space

$v = $index->doc_to_latent_space($docref);

(public) Maps the specified document to its position vector in
         latent semantic space.

B<docref>
A reference to a Clair::Document object.

=cut


=head2 rank_terms

(public) Compute the distance from the origin term of each of the
         specified terms, in latent semantic space. If no terms
         beside the origin term are specified, then the distance
         of each term occurring in the underlying cluster is computed.

%term_distances = $index->rank_terms($origin_term);

B<origin_term>
The "origin term" (from which distances are to be computed).

B<terms (optional)>
A list of (unstemmed) terms.

=cut


=head2 rank_queries

(public) Compute the distance from the origin query of each of the
         specified queries, in latent semantic space.

%query_distances = $index->rank_queries($origin_query);

B<origin_query>
The "origin query" (from which distances are to be computed).

B<queries>
A list of query strings

=cut


=head2 rank_docs

(public) Compute the distance from the origin document of each
         of the specified documents, in latent semantic space.
         If no documents beside the origin document are specified,
         then the distance of each document in the underlying
         cluster is computed.

B<origin_docref>
A reference to the "origin document" (from which distances are to be computed).

B<docrefs (optional)>
A list of other document references.

=cut


=head2 save_to_file

(public) Dump the latent semantic index to file as a Storable object.
#        Only dump the associated cluster as well if the user so
#        specifies.

B<file>
Path where the index is to be saved.

B<savecluster (optional)>
1 if the associated cluster is to be dumped together with the index;
0 if not to be dumped

=cut



# --------------------------------------------------------------
#  sub new (public) :
#        Instantiates a new latent semantic index (LSI) from
#        either an existing Clair::Cluster object or by loading
#        a previously saved index from file. In the latter case,
#        the originally associated cluster may have been saved
#        together with the index or may not have been so saved.
#        In the latter case, the user has the option of specifying
#        an existing cluster to be (re-)associated with the index.
#
#  Parameters:
#       file => : path to a file containing a previously saved index
#    cluster => : a reference to a cluster to be newly associated to
#                 the index to be built or reassociated to the existing
#                 index being loaded
#       type => : (optional) the type of index (stemmed is the default)
# --------------------------------------------------------------
sub new {
    my $class  = shift;
    my %params = @_;

    my $file    = $params{file};
    my $cluster = $params{cluster};

    my $hashref;
    # If file specified...
    if (defined $file) {
        # Load latent semantic index (as a Storable object)
        $hashref = retrieve($file);
        # If cluster also specified, (re-?)attach that cluster to the loaded index
        if (not defined $hashref->{cluster}) {
            $hashref->{cluster} = $cluster;
        }
    } # If only cluster specified...
    elsif (defined $cluster) {
        my $type = $params{type} || "stem";
        $hashref = {cluster => $cluster, type => $type};
    } else {
        die('Clair::Algorithm::LSI - Neither file nor cluster defined.');
    }

    my $self = bless $hashref, $class;
}


# --------------------------------------------------------------
#  sub build_index (public) :
#        Constructs the latent semantic index, which is defined by
#        the singular value decomposition of the associated cluster's
#        document-term matrix. Sets the initial approximation to full
#        rank (K = N).
#
#  Parameters:
#        none
# --------------------------------------------------------------
sub build_index {
    my $self = shift;
    my $c     = $self->{cluster};
    my $type  = $self->{type};

    # Avoid unnecessarily rebuilding index
    return if (defined $self->{m} && $self->{type} eq $type);

    # Get document-term matrix, together with ordered lists of docids and terms,
    # from the cluster
    my ($m_arr, $p_docids_arr, $p_terms_arr) = $c->docterm_matrix(type => $type);
    my $m = mpdl($m_arr);
    my ($r1, $s, $r2) = svd($m);

    # Hash positions of docids and terms into the ordered lists for speedy lookup
    my %docids_hsh;
    for (my $i=0; $i < scalar @$p_docids_arr; $i++) {
        $docids_hsh{$p_docids_arr->[$i]} = $i;
    }
    my %terms_hsh;
    for (my $i=0; $i < scalar @$p_terms_arr; $i++) {
        $terms_hsh{$p_terms_arr->[$i]} = $i;
    }

    $self->{docids_arr}  = $p_docids_arr;
    $self->{docids_hsh}  = \%docids_hsh;
    $self->{terms_arr}   = $p_terms_arr;
    $self->{terms_hsh}   = \%terms_hsh;
    $self->{m}           = $m;
    $self->{r1}          = $r1;
    $self->{s}           = $s;
    $self->{r2}          = $r2;
    $self->{orig_rank}   = $s->getdim(0);
    $self->{type}        = $type;
    $self->set_approx_rank($self->{orig_rank});  # Currently approximation K = N (full rank)
}


# --------------------------------------------------------------
#  sub get_approx_rank (public) :
#        Returns the rank K of the current approximation;
#        where K <= N, the full rank of the approximation.
#
#  Parameters:
#        none
# --------------------------------------------------------------
sub get_approx_rank {
    my $self = shift;

    return $self->{rank};
}


# --------------------------------------------------------------
#  sub set_approx_rank (public) :
#        Sets the rank K of the current approximation,
#        where K <= N, the full rank of the approximation. If some
#        K > N is specified, the rank K retains its previous value.
#
#  Parameters:
#       $K : the desired rank of the approximation
# --------------------------------------------------------------
sub set_approx_rank {
    my $self = shift;
    my $K    = shift;

    my $N = $self->{orig_rank};
    return if ($K >= $N && defined $self->{ess});  # Cannot set approximation K > N
    my $s = $self->{s};
    my $upper = $K - 1;

    my $all_svals  = $s->copy;
    my $reduc_svals = $all_svals->slice("0:$upper");

    my $reduc_vect  = PDL->zeroes($N);
    $reduc_vect->slice("0:$upper") .= $reduc_svals;
    my $ess = PDL->zeroes($N, $N);
    $ess->diagonal(0,1) .= $reduc_vect;
    $self->{ess} = $ess;
}


# --------------------------------------------------------------
#  sub term_to_latent_space (public) :
#        Maps the specified term to its position vector in latent
#        semantic space.
#
#  Parameters:
#       $term : the (unstemmed) term
# --------------------------------------------------------------
sub term_to_latent_space {
    my $self = shift;
    my $term = shift;

    my $c = $self->{cluster};
    my ($m, $r1, $ess, $r2, $p_terms_hsh, $p_docids_arr, $type, $N) = ($self->{m},
                                                                       $self->{r1},
                                                                       $self->{ess},
                                                                       $self->{r2},
                                                                       $self->{terms_hsh},
                                                                       $self->{docids_arr},
                                                                       $self->{type},
                                                                       $self->{orig_rank});
    my $D = scalar @$p_docids_arr;

    # Stem term if the index is of the stemmed type
    if ($type eq "stem") {
        my $stemmer = Lingua::Stem->new(-locale => 'EN-US');
        $stemmer->stem_caching({ -level => 2 });
        my @words = ($term);
        $term = $stemmer->stem(@words)->[0];
    }

    # Compute term's mapping into latent semantic space
    my $v;
    if (defined $p_terms_hsh->{$term}) {
        $v = $m->slice(":,$p_terms_hsh->{$term}")
    } else {
        my @term_vect = split //, ("0" x $D);
        $v = vpdl(\@term_vect);
    }
    my $w = $ess x transpose($r2 x $v);

    return $w;
}


# --------------------------------------------------------------
#  sub query_to_latent_space (public) :
#        Maps the specified query to its position vector in latent
#        semantic space. The query is treated exactly like a
#        document the text of which is precisely the query text.
#
#  Parameters:
#       $query : the (unstemmed) query string
# --------------------------------------------------------------
sub query_to_latent_space {
    my $self = shift;
    my $query = shift;

    # Construct a document the text of which consists precisely of the query text
    my $docref = new Clair::Document(string => $query,
                                     type   => 'text',
                                     id     => $query);

    # Treat a query exactly like a document with respect to mapping into latent semantic space
    return $self->doc_to_latent_space($docref);
}


# --------------------------------------------------------------
#  sub doc_to_latent_space (public) :
#        Maps the specified document to its position vector in
#        latent semantic space.
#
#  Parameters:
#       $docref : a reference to the Clair::Document object
# --------------------------------------------------------------
sub doc_to_latent_space {
    my $self = shift;
    my $docref = shift;

    my $c = $self->{cluster};
    my ($r1, $ess, $r2, $p_terms_arr, $N, $type) = ($self->{r1},
                                                    $self->{ess},
                                                    $self->{r2},
                                                    $self->{terms_arr},
                                                    $self->{orig_rank},
                                                    $self->{type});

    # Compute term's mapping into latent semantic space
    my %tf = $docref->tf(type => $type);
    my @doc_vect;
    foreach my $term (@$p_terms_arr) {
        push @doc_vect, $tf{$term} || 0;
    }
    my $v = vpdl(\@doc_vect);
    my $w = $ess x transpose($r1 x $v);
    return $w;
}


# --------------------------------------------------------------
#  sub rank_terms(public) :
#        Compute the distance from the origin term of each of the
#        specified terms, in latent semantic space. If no terms
#        beside the origin term are specified, then the distance
#        of each term occurring in the underlying cluster is computed.
#
#  Parameters:
#    $origin_term : the "origin term" (from which distances are to be
#                   computed
#          @terms : list of (unstemmed) terms
# --------------------------------------------------------------
sub rank_terms {
    my $self        = shift;
    my $origin_term = shift;
    my @terms       = @_;

    # If no list of terms to rank is specified, simply rank all terms occurring in the index itself,
    # i.e. occurring in the cluster from which the latent semantic index was built
    my $c = $self->{cluster};
    if (scalar @terms == 0) {
        @terms = @{$self->{terms_arr}};
    }

    # Compute each term's distance in latent semantic space from the specified "origin" term
    my $v = $self->term_to_latent_space($origin_term);
    my %term_dists;
    foreach my $term (@terms) {
        my $diff = $v - $self->term_to_latent_space($term);
        $term_dists{$term} = sqrt(sum($diff * $diff));
    }

    return %term_dists
}


# --------------------------------------------------------------
#  sub rank_queries(public) :
#        Compute the distance from the origin query of each of the
#        specified queries, in latent semantic space.
#  Parameters:
#    $origin_query : the "origin query" (from which distances are
#                    to be computed
#         @queries : list of query strings
# --------------------------------------------------------------
sub rank_queries {
    my $self         = shift;
    my $origin_query = shift;
    my @queries      = @_;

    my $c = $self->{cluster};

    # Compute each query's distance in latent semantic space from the specified "origin" query
    my $v = $self->query_to_latent_space($origin_query);
    my %query_dists;
    foreach my $query (@queries) {
        my $diff = $v - $self->query_to_latent_space($query);
        $query_dists{$query} = sqrt(sum($diff * $diff));
    }

    return %query_dists;
}


# --------------------------------------------------------------
#  sub rank_docs(public) :
#        Compute the distance from the origin document of each
#        of the specified documents, in latent semantic space.
#        If no documents beside the origin document are specified,
#        then the distance of each document in the underlying
#        cluster is computed.
#  Parameters:
#   $origin_docref : a reference to the "origin document" (from
#                    which distances are to be computed
#         @docrefs : list of other document references
# --------------------------------------------------------------
sub rank_docs {
    my $self          = shift;
    my $origin_docref = shift;
    my @docrefs       = @_;

    my $c = $self->{cluster};

    # If no list of documents to rank is specified, simply rank all documents occurring in the index itself,
    # i.e. occurring in the cluster from which the latent semantic index was built
    if (scalar @docrefs == 0) {
        @docrefs = map $c->get($_), @{$self->{docids_arr}};
    }

    # Compute each document's distance in latent semantic space from the specified "origin" document
    my $v = $self->doc_to_latent_space($origin_docref);
    my %doc_dists;
    foreach my $docref (@docrefs) {
        my $diff = $v - $self->doc_to_latent_space($docref);
        $doc_dists{$docref->get_id()} = sqrt(sum($diff * $diff));
    }

    return %doc_dists;
}


# --------------------------------------------------------------
#  sub save_to_file (public) :
#        Dump the latent semantic index to file as a Storable object.
#        Only dump the associated cluster as well if the user so
#        specifies.
#  Parameters:
#            $file : where the index is to be saved
#   savecluster => : (optional) 1 if the associated cluster is to be dumped
#                    together with the index; 0 if not to be dumped
# --------------------------------------------------------------
sub save_to_file {
    my $self = shift;
    my $file = shift;
    my %params = @_;

    my $save_cluster = $params{savecluster} || 0;
    if ($save_cluster) {
        store $self, $file;
    } else {
        my $c = $self->{cluster};
        undef $self->{cluster};
        store $self, $file;
        $self->{cluster} = $c;
    }
}


1;
