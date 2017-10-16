package Clair::LinkPolicy::ErdosRenyi;

use Clair::LinkPolicy::LinkPolicyBase;
@ISA = qw (Clair::LinkPolicy::LinkPolicyBase);

use strict;
use Carp;
use Math::Random;

=head1 NAME

Clair::LinkPolicy::ErdosRenyi - Class implementing the Erdos Renyi link model

=cut

=head1 SYNOPSIS

=cut

=head1 DESCRIPTION

METHODS IMPLEMENTED BY THIS CLASS:
  new                        Object Constructor
  create_corpus        Creates a corpus using this link policy.

=cut

=head2 new

Generic object constructor for all link policies. Should only be
called by subclass constructors.

  base_collection        => $collection_object
  base_dir                => $collection_directory
  type                => $name_of_this_linker_type

=cut

sub new {
  my $class = shift;

  my %params = @_;
  # Instantiate our base class/create representation
  $params{model_name} = "ErdosRenyi";
  my $self = $class->new_linker(%params);

  return $self;
}

=head2 create_corpus

Generates a corpus using the Erdos/Renyi model.

=cut

sub create_corpus {
  my $self = shift;
  my %params = @_;

  unless ((exists $params{corpus_name}) && (exists $params{link_prob})) {
    croak "ErdosRenyi->create_corpus requires the following arguments:
        corpus_name => name of new corpus
        link_prob   => probability of linking any two nodes\n";
  }
  my $download_dir = $self->{download_base} . "/" . $params{corpus_name};
  my $corpus_dir = $self->{corpus_data} . "/" . $params{corpus_name};
  my $doc_dir = $self->{base_collection}->{docs_dir};
  my $N = $self->{base_collection}->{size};

  $self->prepare_directories($params{corpus_name});

  open (LINKS, ">$corpus_dir/$params{corpus_name}.links");

  for my $i (0..$N-2) {
    for my $j ($i+1..$N-1) {
      if ((-e "$doc_dir/synth.$i") &&
          (-e "$doc_dir/synth.$j") &&
          (random_uniform() > $params{link_prob})) {
        print LINKS "synth.$i synth.$j\n";
        print LINKS "synth.$j synth.$i\n";
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

  # Call the superclass
  $self->SUPER::create_corpus($params{corpus_name}, $self->{base_dir});
}

1;
