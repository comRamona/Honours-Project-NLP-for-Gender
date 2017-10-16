package Clair::LinkPolicy::MenczerPAMixed;

use Clair::LinkPolicy::LinkPolicyBase;
@ISA = qw (Clair::LinkPolicy::LinkPolicyBase);

use Math::Random;
use strict;
use Carp;

=head1 NAME

MenczerPAMixed - Class implementing the MenczerPAMixed Micro link model

=cut

=head1 SYNOPSIS

=cut

=head1 DESCRIPTION

INHERITS FROM:
  LinkPolicy

REQUIRED RESOURCES:
  XXX

METHODS IMPLEMENTED BY THIS CLASS:
  new			Object Constructor
  create_corpus	Creates a corpus using this link policy.

=cut

=head2 new

Generic object constructor for all link policies. Should
  only be called by subclass constructors.

  base_collection	=> $collection_object
  base_dir	        => $collection_directory
  type  		=> $name_of_this_linker_type

=cut

sub new {
  my $class = shift;

  my %params = @_;
  # Instantiate our base class/create representation
  $params{model_name} = "MenczerPAMixed";
  my $self = $class->new_linker(%params);

  return $self;
}


=head2 create_corpus 

XXX Make this return a Corpus object once Corpus class is implemented XXX

Generates a corpus using the MenczerPAMixed Micro model.

REQUIRED ARGS:
 corpus_name
 num_neighbors
 mixture_probability
 sigmoid_threshold
 sigmoid_steepness

=cut

sub create_corpus {
  my $self = shift;
  my %params = @_;

  my $cosP = $params{mix_probability};
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

#  my ($steepness, $thresh) = ($params{sigmoid_steepness}, 
#                              $params{sigmoid_threshold});

  my ($tgt, $src, $cos);
  my %degree = ();
  my $desired_links = $params{desired_links};

  print "Desired Edges: $desired_links\n";

  # Create bags of nodes  
  my %nodes = ();
  my @input_nodes = ();
  my @added_nodes = ();
  my %cosines = ();
  my $cos_sum = 0;

  while (<COS>) {
    chomp;
    ($tgt, $src, $cos) = split;
    $nodes{$tgt}++;
    $nodes{$src}++;
    $cosines{"$src $tgt"} = $cos;
    $cos_sum += $cos;
  }
  close (COS);

  # Randomize input node traversal order
  @input_nodes = keys %nodes;
  fisher_yates_shuffle (\@input_nodes);

  # Compute the probability of linking for PA as a function of the
  # rough number of links we want in the final graph
  my $num_links = round ($desired_links / scalar (@input_nodes)) * 2;
  #my $num_links = 5;

  my $prob;		# Temp var for storing probabilities
  my $total_degree;	# Store total degree for graph as we add edges
  my $node_itor;	# Index iterator over newly added nodes

  my $coslink_count = 0;
  my $palink_count = 0;
  my $initlink_count = 0;
  # Iterate over the randomized input nodes
  for ($node_itor = 0; $node_itor < @input_nodes; $node_itor++) {
    $src = $input_nodes[$node_itor];

    # store link data as a hash of node indices (indices into input_nodes)
    my %link_hash = ();

    # Do we need to initialize the graph?
    if ($node_itor < $num_links) {
      # Initialize graph with fully-connected component
      for (my $init_itor = 0; $init_itor < $node_itor; $init_itor++) {
        print LINKS "$src $input_nodes[$init_itor]\n";
        #print "$src $input_nodes[$init_itor]\n";
        $link_hash{$init_itor} = 1;
        $initlink_count++;
      }
    } else {

      # Graph initialized....Select Cosine or PA
      if (random_uniform() <= $cosP) {
        # Using cosine for this node
        # Examine all cosines betwen $src and nodes in the graph
        foreach $tgt (0 .. $node_itor - 1) {
          if (exists $cosines{"$src $input_nodes[$tgt]"}) {
            $prob = $cosines{"$src $input_nodes[$tgt]"};
          } elsif (exists $cosines{"$input_nodes[$tgt] $src"}) {
            $prob = $cosines{"$input_nodes[$tgt] $src"};
          } else {
            croak "Cosine between $src and $input_nodes[$tgt] not available!\n";
          }

          # Do we create our link?
          if (random_uniform() <= $prob / $cos_sum * $desired_links) {
            print LINKS "$src $input_nodes[$tgt]\n";
            $link_hash{$tgt} = 1;
            $coslink_count++;
          }
        }
      } else {
        # Use Pref attach for this node
        foreach (1 .. $num_links) {
          foreach $tgt (0 .. $node_itor - 1) {
            $prob = $degree{$tgt}/$total_degree;

            # Do we create a link?
            if (random_uniform() <= $prob) {
              print LINKS "$src $input_nodes[$tgt]\n";
              $palink_count++;
            }
          }
        }
      }
      # Update Degree counter for nodes we've linked to
      foreach my $linked_to_node (keys %link_hash) {
        $degree{$linked_to_node}++;
      }
    }

    # We've created (scalar keys %link_hash) links to our new node
    $degree{$node_itor} = scalar keys %link_hash;

    # Total added degree is 2 X the number of edges added
    $total_degree += $degree{$node_itor} * 2;

  }
  print "Initialization Links Created: $initlink_count\n";
  print "Cosine Links Created: $coslink_count\n";
  print "PA Links Created: $palink_count\n";
  print "Total Links Created: " . 
    ($palink_count + $coslink_count + $initlink_count) . "\n";
  close (LINKS);

  unless ($params{no_html}) {
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

sub cosine ($$) {
  my ($doc1, $doc2) = @_;
  my $sum = 0;
  my ($short_norm, $long_norm) = (0, 0);

  # Keep the shorter of the two docs in $short
  my ($short, $long) =
    (keys %$doc1 < keys %$doc2) ? ($doc1, $doc2) : ($doc2, $doc1);

  # Iterate over the smaller one
  foreach (keys %$short) {
    if (exists $long->{$_}) {
      $sum += $short->{$_} * $long->{$_};
    }
    $short_norm += $short->{$_} ** 2;
  }

  foreach (keys %$long) {
    $long_norm += $long->{$_} ** 2;
  }

  unless ($long_norm * $short_norm == 0) {
    return $sum / sqrt ($long_norm * $short_norm);
  } else {
    return 0;
  }
}

=head2 get_doc_vector

Get a tf vector from a file

=cut

sub get_doc_vector ($) {
  my $file = shift;
  my %model;

  open (F, $file)
    || croak "Cant open $file\n";

  while (<F>) {
    foreach my $term (split /\s+/) {
      $model{$term}++;
    }
  }
  close (F);

  return \%model;
}

sub fisher_yates_shuffle {
  my $array = shift;
  my $i;
  for ($i = @$array; --$i; ) {
    my $j = int rand ($i+1);
    next if $i == $j;
    @$array[$i,$j] = @$array[$j,$i];
  }
}

sub round {
  my $v = shift;
  if ($v - int ($v) >= 0.5) {
    return int ($v) + 1;
  }
  return int ($v);
}

1;
