package Clair::LinkPolicy::WattsStrogatz;

use Clair::LinkPolicy::LinkPolicyBase;
@ISA = qw (Clair::LinkPolicy::LinkPolicyBase);

use strict;
use Carp;
use Math::Random;

=head1 NAME

Clair::LinkPolicy::WattsStrogatz - Class implementing the Watts/Strogatz link model

=cut

=head1 SYNOPSIS

=cut

=head1 DESCRIPTION

INHERITS FROM:
  LinkPolicy

METHODS IMPLEMENTED BY THIS CLASS:
  new                        Object Constructor
  create_corpus        Creates a corpus using this link policy.

=cut

=head2 new

Generic object constructor for all link policies. Should
  only be called by subclass constructors.

  base_collection        => $collection_object
  base_dir                => $collection_directory
  type                => $name_of_this_linker_type

=cut

sub new {
  my $class = shift;

  my %params = @_;
  # Instantiate our base class/create representation
  $params{model_name} = "WattsStrogatz";
  my $self = $class->new_linker(%params);

  return $self;
}

=head2 create_corpus

Generates a corpus using the Watts Strogatz model.

=cut

# XXX Make this return a Corpus object once Corpus class is implemented XXX
#
sub create_corpus {
  my $self = shift;
  my %params = @_;

  unless ((exists $params{corpus_name}) && (exists $params{link_prob}) &&
          (exists $params{num_neighbors})) {
    croak "WattsStrogatz->create_corpus requires the following arguments:
    corpus_name         => name of new corpus
    num_neighbors         => name of new corpus
    link_prob           => probability of linking any two nodes\n";
  }

  my $download_dir = $self->{download_base} . "/" . $params{corpus_name};
  my $corpus_dir = $self->{corpus_data} . "/" . $params{corpus_name};
  my $doc_dir = $self->{base_collection}->{docs_dir};
  my $N = $self->{base_collection}->{size};

  $self->prepare_directories($params{corpus_name});

  open (LINKS, ">$corpus_dir/$params{corpus_name}.links");

  # We do not use the cosine file for its cosine computations,
  #  but we exploit it as a list of (n^2-n)/2 pairs
  open (FILELIST, $self->{base_collection}->{file_list}) ||
    croak "Could not open file $self->{base_collection}->{file_list}\n";

  my @nodes;

  while (<FILELIST>) {
    chomp;
    push(@nodes, $_);
  }

  close FILELIST;

  if (@nodes > $N) {
    croak "Cluster size and the number of documents do not match\n";
  }

  for my $k (1..$params{num_neighbors}) {
    for my $i (0..$N-1) {
      my $j = ($i+$k)%$N;
      if (random_uniform() > $params{link_prob}) {
        my $relink = int(random_uniform()*$N);
#        if (-e "$doc_dir/synth.$i" && -e "$doc_dir/synth.$relink") {
          print LINKS "$nodes[$i] $nodes[$relink]\n";
          print LINKS "$nodes[$relink] $nodes[$i]\n";
#        }
      } else {
#        if (-e "$doc_dir/synth.$i" && -e "$doc_dir/synth.$j") {
          print LINKS "$nodes[$i] $nodes[$j]\n";
          print LINKS "$nodes[$j] $nodes[$i]\n";
#        }
      }
    }
  }

  close LINKS;

  # Now, generate the html docs and the url2file map, which is
  #  needed for indexing the corpus.
  my $url2file = $self->create_html_no_anchors
    (src_doc_dir => $self->{base_collection}->{docs_dir},
     html_dir =>
       "$download_dir/www.$params{corpus_name}.com",
        links_file  => "$corpus_dir/$params{corpus_name}.links",
        base_url    => "www.$params{corpus_name}.com");

  my $uniq_file = $self->{base_dir} . "/$params{corpus_name}.download.uniq";
  open (LINKSUNIQ, ">$uniq_file") ||
    croak "Cannot create file $uniq_file\n";

  for (my $i = 0; $i < @$url2file; $i++) {
    print LINKSUNIQ $url2file->[$i] . "\n";
  }

  close (LINKSUNIQ);
}

1;
