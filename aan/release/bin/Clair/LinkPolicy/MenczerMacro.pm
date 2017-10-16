package Clair::LinkPolicy::MenczerMacro;

use Clair::LinkPolicy::LinkPolicyBase;
@ISA = qw (Clair::LinkPolicy::LinkPolicyBase);

use Math::Random;
use strict;
use Carp;

=head1 NAME

Clair::LinkPolicy::MenczerMacro - Class implementing the Menczer Micro link model

=cut

=head1 SYNOPSIS

=cut

=head1 DESCRIPTION

INHERITS FROM:
  LinkPolicy

METHODS IMPLEMENTED BY THIS CLASS:
  new			Object Constructor
  create_corpus	Creates a corpus using this link policy.

=cut

=head2 new

Generic object constructor for all link policies. Should
  only be called by subclass constructors.

  base_collection	=> $collection_object
  base_dir	        => $collection_directory
  type		=> $name_of_this_linker_type

=cut

sub new {
  my $class = shift;

  my %params = @_;
  # Instantiate our base class/create representation
  $params{model_name} = "MenczerMacro";
  my $self = $class->new_linker(%params);

  return $self;
}

=head2 create_corpus 

Generates a corpus using the Menczer Micro model.

REQUIRED ARGS:

corpus_name
sigmoid_threshold
sigmoid_steepness

=cut

#
# XXX Make this return a Corpus object once Corpus class is implemented XXX
#
sub create_corpus {
  my $self = shift;
  my %params = @_;

  my $N = $self->{base_collection}->{size};
  my $doc_dir = $self->{base_collection}->{docs_dir};
  my $download_dir = $self->{download_base} . "/" . $params{corpus_name};
  my $corpus_dir = $self->{corpus_data} . "/" . $params{corpus_name};

  $self->prepare_directories($params{corpus_name});

  # Generate our link specification
  open (LINKS, ">$corpus_dir/$params{corpus_name}.links") ||
    croak "Could not create file $corpus_dir/$params{corpus_name}.links\n";

  open (COS, $self->{base_collection}->{cosine_file}) ||
    croak "Could not open file $self->{base_collection}->{cosine_file}\n";

  my ($steepness, $thresh) = ($params{sigmoid_steepness}, 
                              $params{sigmoid_threshold});

  my ($src, $tgt, $cos);
  while (<COS>) {
    chomp;
    ($src, $tgt, $cos) = split;

    if (logistic ($cos, $steepness, $thresh) >= random_uniform()) {
      print LINKS "$src $tgt\n";
      print LINKS "$tgt $src\n";
    }
  }
  close (LINKS);
  close (COS);

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

# CONSTANT
my $e = 2.718281828;

=head2 logistic

Takes a cosine value "x", a threshold steepness "s", and a threshold
 center "c"

=cut

sub logistic ($$$) {
  my ($x, $s, $c) = @_;
  $x += (0.5 - $c);
  return 1 / (1 + ($e ** ((-$s * $x) + ($s / 2))));
}

1;
