package Clair::LinkPolicy::RadevMicro;

use Clair::LinkPolicy::LinkPolicyBase;
@ISA = qw (Clair::LinkPolicy::LinkPolicyBase);

use Clair::Utils::porter;
use Math::Random;
use strict;
use Carp;

=head1 NAME

Clair::LinkPolicy::RadevMicro - Class implementing the Radev Micro link model

=cut

=head1 SYNOPSIS

=cut

=head1 DESCRIPTION

INHERITS FROM:
  LinkPolicy

METHODS IMPLEMENTED BY THIS CLASS:
  new			Object Constructor
  create_corpus	        Creates a corpus using this link policy.

=cut

=head2 new

Generic object constructor for all link policies. Should
  only be called by subclass constructors.

  base_collection	=> $collection_object
  base_dir	        => $collection_directory
  type	        	=> $name_of_this_linker_type

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

Generates a corpus using the Radev Micro model.

REQUIRED ARGUMENTS:
 corpus_name
 term_weights
 sigmoid_steepness
 sigmoid_threshold
 prob_reserve

=cut

#
# XXX Make this return a Corpus object once Corpus class is implemented XXX
#
sub create_corpus {
  my $self = shift;
  my %params = @_;

  my $tf_dir = "$self->{base_collection}->{collection_base}/tf_docs";
  my $weight_file = $params{term_weights};
  my $reserve = $params{prob_reserve};
  my $thresh = $params{sigmoid_threshold};
  my $steepness = $params{sigmoid_steepness};

  my $download_dir = $self->{download_base} . "/" . $params{corpus_name};
  my $corpus_dir = $self->{corpus_data} . "/" . $params{corpus_name};
  
  $self->prepare_directories($params{corpus_name});

  # Create our links specification
  open (LINKS, ">$corpus_dir/$params{corpus_name}.links") ||
    croak "Could not create file $corpus_dir/$params{corpus_name}.links\n";


  # Read-in weight model
  my $weight_model = read_model_from_file ($weight_file);
  
  # Load filenames into memory
  unless (-d $tf_dir) { die "$tf_dir is not a directory\n" }
  my $src_file;
  my $term;
  my $tfw_model;
  my @tf_files;
  my %tfw_models;
  my $terms_not_in_model = 0;
  my $terms_in_model = 0;
  opendir (TFDIR, $tf_dir) || die "Cant open $tf_dir\n";
  while (defined ($src_file = readdir (TFDIR))) {
    next if $src_file =~ /^\.+/;  # Strip out dotfiles
    push (@tf_files, $src_file);  # Store filename
  
    # Read TF model and weight by term weight model
    $tfw_model = read_model_from_file ("$tf_dir/$src_file");
    foreach $term (keys %$tfw_model) {
      # Do we have a weight for this term?
      if (exists $weight_model->{$term}) {
        # Weight exists - modify model
        $tfw_model->{$term} = $weight_model->{$term} * $tfw_model->{$term};
        $terms_in_model++;
  
        # print STDERR $tfw_model->{$term} . "\n";
  
      } elsif (exists $weight_model->{Clair::Utils::porter(lc $term)}) {
        # Weight exists for stemmed term- modify model
        $tfw_model->{$term} =
          $weight_model->{Clair::Utils::porter(lc $term)} * $tfw_model->{$term};
        $terms_in_model++;
  
        # print STDERR $tfw_model->{$term} . "\n";
      } else {
        # Weight does not exist - remove term from model
        delete $tfw_model->{$term};
        $terms_not_in_model++;
      }
    }
  
    # Save weighted model.
    $tfw_models{$src_file} = $tfw_model;
  }
  closedir (TFDIR);

  # Now determine links based on probabilities
  my $tgt_file;
  my $link_prob;
  my $cur_reserve;
  my $rank_itor;
  foreach $tgt_file (@tf_files) {
    foreach $src_file (@tf_files) {
      next if $src_file eq $tgt_file;     # Skip self-links
      # Refill our reserve for this pair of docs
      $cur_reserve = $reserve;
      $rank_itor = 0;
  
      # Iterate over terms from greatest to least weights in $tgt_file
      TERMS: foreach $term (sort
        {$tfw_models{$tgt_file}->{$b} <=> $tfw_models{$tgt_file}->{$a}}
        keys %{$tfw_models{$tgt_file}}) {
        $rank_itor++;
        # Proceed iff we have reserve to spare
        last TERMS if ($cur_reserve <= 0);
  
        # See if this term exists in src-doc
        if (exists $tfw_models{$src_file}->{$term}) {
          # It exists. Compute link probability
          $link_prob = logistic ($tfw_models{$tgt_file}->{$term} +
                                 $tfw_models{$tgt_file}->{$term},
                                 $steepness, $thresh);
  
          # Given the probability, do we output a link?
          if ($link_prob >= random_uniform (1, 0, 1)) {
            print LINKS "$src_file $tgt_file $term\n";
            #print "$src_file $tgt_file $term $link_prob RANK:$rank_itor\n";
          }
  
          # Draw from our reserve
          $cur_reserve -= $link_prob;
        } # If term is in both documents
      } # foreach $term
    } # foreach source doc
  } # foreach target doc

  close (LINKS);

  # Now, generate the html docs and the url2file map, which is
  #  needed for indexing the corpus.
  my $url2file = $self->create_html_with_anchors
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

=head2 read_model_from_file

Takes a filename, returns a model as a hash ref.

=cut

sub read_model_from_file ($) {
  my $file = shift;
  my %model;
  my ($term, $weight);
  open (MF, $file) || die "Cant open $file\n";
  while (<MF>) {
    chomp;
    ($term, $weight) = split;
    $model{$term} = $weight;
  }
  close (MF);
  return \%model;
}

# CONSTANT
my $e = 2.718281828;

=head2 logistic

Takes a TF*W value "x", a threshold steepness "s",
and a threshold center "c"

=cut

sub logistic ($$$) {
  my ($x, $s, $c) = @_;
  $x += (0.5 - $c);
  return 1 / (1 + ($e ** ((-$s * $x) + ($s / 2))));
}

1;
