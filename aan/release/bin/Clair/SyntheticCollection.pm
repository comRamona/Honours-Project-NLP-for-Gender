package Clair::SyntheticCollection;
use Clair::RandomDistribution::RandomDistributionFromWeights;

=head1 NAME

Clair::SyntheticCollection  

=cut

=head1 new

SyntheticCollection
	- new (string Name, Distribution content_dist, 
 	                    Distribution length_dist,
 	                    integer number_of_docs)

 Some examples:
 my $a = SyntheticCollection->new (name => "name",
				    n_gram => 2,
				    ngram_map => \@bigrams_with_freqs,
				    doclen_dist => $doclen_dist,
				    doclen_map => \@doclen_map,
				    size => $number_of_docs);

 my $a = SyntheticCollection->new (name => "name",
				    term_map => \@ranks2terms,
				    term_dist => $term_dist,
				    doc_length => 100,
				    size => $number_of_docs);


 Needs:
 1. Base Dir
 2. Synthetic Collection Output Dir

 Sat Mar 12 19:37:19 EST 2005
 
 N-gram support added: Aug 2009

=cut

use strict;
use Carp;
#my $SYNTH_COL_BASE	= "$ENV{PERLTREE_HOME}/synth_collections";

sub new {
  my $class = shift;
  my %params = @_;
  my $self = bless { %params }, $class;

  # Verify params
  # Required arg: name, mode
  unless ((exists $params{mode}) && (exists $params{name})
	  && (exists $params{base})) {
    croak
      "SyntheticCollection ctor requires \"mode\", \"name\" and \"base\" arguments\n";
  }

  # SyntheticCollection currently only deals with unigrams, bigrams, 3-, and 4-grams
  if(exists($params{n_gram})){
      if($params{n_gram} < 5 && $params{n_gram} > 0){
	  $self->{n_gram} = $params{n_gram};
      }
      else{
	  croak "SyntheticCollection ctor requires that 1 <= \"n_gram\" <= 4";
      }

      if($params{n_gram} > 1 && exists($params{term_dist})){
	  print STDERR "Warning: term_dist will be ignored and RandomDistributionFromWeights " . 
	      "will be used because n_gram > 1\n";
      }
  }
  else{
      # if n_gram argument isn't passed, assume we're generating using unigrams
      $self->{n_gram} = 1;
  }

  # Populate a few essential fields
#  $self->{collection_base} = "$SYNTH_COL_BASE/$params{name}";
  $self->{collection_base} = $params{base};
  $self->{docs_dir}        = "$self->{collection_base}/raw_docs";
  $self->{stats_dir}       = "$self->{collection_base}/stats";
  $self->{cosine_file}     = "$self->{collection_base}/$self->{name}.cos";
  $self->{file_list}       = "$self->{collection_base}/$self->{name}.files";

  if(exists $params{ngram_map}){
      $self->{ngram_map} = $params{ngram_map};
  }

  # If read only, all we need is a collection name
  # To create new, we need much more
  unless ($params{mode} eq "read_only") {

    # Required args for creating a new collection: 
    #    size, (term_map, term_dist) or (n_gram > 1, ngram_map)
    unless ((exists $params{term_map}) &&
            (exists $params{term_dist}) &&
            (exists $params{size})) {

	my $error = 		"SyntheticCollection ctor requires the following args to create " .
         "a new synthetic collection:\n" .
	"n_gram         => an integer between [1, 4]\n" .
	"ngram_map      => array reference in no particular order, in format \"word_1 word_2 ... word_n freq\"\n" .
	"--OR--\n" .
	"term_map	=> array reference mapping ranks to terms\n" .
	"term_dist	=> a RandomDistribution object\n\n" .
	"size		=> number of documents to generate\n\n";

	if(!exists $params{size}){
	   croak $error;
	}

	# Mutually exclusively required args:
	#  (n_gram > 1, ngram_map) || (term_map, term_dist)
	if(!exists $params{term_map} || !exists $params{term_dist}){
	    if(!exists $params{ngram_map} || $params{n_gram} == 1){
		$error .= "Must specify (term_map, term_dist) OR (ngram_map, n_gram > 1)\n\n";
		croak $error;
	    }
	}
    }

    # Mutually Exclusively Required Args for creating new collection:
    #  (doclen_dist, doclen_map) || doc_length
    unless ((exists $params{doclen_dist}) &&
            (exists $params{doclen_map})) {
      unless (exists $params{doc_length}) {
        croak "Must specify (doclen_dist and doclen_map) OR doc_length\n";
      }
    } else {
      # make sure doc_length was not specified
      if (exists $params{doc_length}) {
        croak "Must specify (doclen_dist and doclen_map) OR doc_length\n" .
              "Not both.\n";
      }
    }

    # If we get here, we have all the parameters necessary to create
    #  a new collection.
    unless (-d $self->{collection_base}) {
      mkdir ($self->{collection_base}, 0775) ||
	croak "Could not create directory $self->{collection_base}\n";
    }
  } else {
    # Need to populate fields from file
    open (NUMDOCS, "$self->{stats_dir}/num_docs.txt") ||
      croak "Could not open file $self->{stats_dir}/num_docs.txt\n";
    $self->{size} = <NUMDOCS>;
    # DEBUG
    # print "Collection Size: $self->{size}\n";
    # /DEBUG
    close (NUMDOCS);
  }

  return $self;
}

sub create_documents {
  my $self = shift;

  # Only proceed if our mode is not "read_only"
  if ($self->{mode} eq "read_only") {
    croak "Cannot create documents: mode is \"read_only\"\n\n";
  }

  # Make sure there is not an existing synth collection with this name
  if (-d $self->{docs_dir}) {
    # report error
    croak "Collection $self->{name} already exists in $self->{docs_dir}\n";
  }

  # Create our document directory
  mkdir ($self->{docs_dir}, 0775) ||
    croak "Could not create directory $self->{docs_dir}\n";

  # create files by iterating from $self->{size} to 0
  my $docs_itor = $self->{size};
  my $cur_doclen;

  my $term_dist = $self->{term_dist};
  my $term_map = $self->{term_map};

  my $doclen_map = $self->{doclen_map};
  my ($uniform_doclen, $doclen_dist) =
     ($self->{doc_length}, $self->{doclen_dist});
  my $mirror_doclen = $self->{mirror_doclen};

  # Keep a list of filenames
  open (FILES, ">$self->{file_list}") ||
    croak "Could not create file $self->{file_list}\n";

  # Generate a hash to store n-grams if n_gram > 1
  # This is only used in get_next_state()
  # We expect an input in the format of CMU-LM: "word_1 word_2 ... word_n freq"

  if($self->{n_gram} > 1){
      $Clair::SyntheticCollection::public_ngram_map = ();
      $Clair::SyntheticCollection::n = $self->{n_gram};
      foreach my $ngram (@{$self->{ngram_map}}){
	  chomp($ngram);
	  # DEBUG
	  #print "$ngram: ";
	  # /DEBUG
	  
	  if($self->{n_gram} == 2){
	      if($ngram =~ /(.+?)\s(.+?)\s(\d+)/){
		  $Clair::SyntheticCollection::public_ngram_map->{$1}->{$2} = $3;
		  # DEBUG
		  #print "$1 - $2 - $3\n";
		  # /DEBUG
	      }
	      else{
		  print STDERR "Warning: n_gram = 2, but $ngram is not formatted [word1 word2 freq]\n";
	      }
	  }
	  elsif($self->{n_gram} == 3){
	      if($ngram =~ /(.+?)\s(.+?)\s(.+?)\s(\d+)/){
		  $Clair::SyntheticCollection::public_ngram_map->{$1}->{$2}->{$3} = $4;
		  # DEBUG
		  #print "$1 - $2 - $3 - $4\n";
		  # /DEBUG
	      }
	      else{
		  print STDERR "Warning: n_gram = 3, but $ngram is not formatted [word1 word2 word3 freq]\n";
	      }
	  }
	  elsif($self->{n_gram} == 4){
	      if($ngram =~ /(.+?)\s(.+?)\s(.+?)\s(.+?)\s(\d+)/){
		  $Clair::SyntheticCollection::public_ngram_map->{$1}->{$2}->{$3}->{$4} = $5;
		  # DEBUG
		  #print "$1 - $2 - $3 - $4 - $5\n";
		  # /DEBUG
	      }
	      else{
		  print STDERR "Warning: n_gram = 4, but $ngram is not formatted [word1 word2 word3 word4 freq]\n";
	      }
	  }
      }
  }

  # We need to use this block of code when n_gram > 1
  my $get_next_state = sub{
      my $current = $_[0];
      my $next = "";

      my @possible_next = ();
      my @weights = ();

      # build @possible_next based on size of n_gram
      # need n_gram-1 nested loops
      if($Clair::SyntheticCollection::n == 2){
	  @possible_next = sort keys %{$Clair::SyntheticCollection::public_ngram_map->{$current}};
      }
      elsif($Clair::SyntheticCollection::n == 3){
	  foreach my $temp1 (sort keys %{$Clair::SyntheticCollection::public_ngram_map->{$current}}){
	      foreach my $temp2 (sort keys %{$Clair::SyntheticCollection::public_ngram_map->{$current}->{$temp1}}){
		  push (@possible_next, "$temp1 $temp2");
		  push (@weights, $Clair::SyntheticCollection::public_ngram_map->{$current}->{$temp1}->{$temp2});
	      }
	  }
      }
      elsif($Clair::SyntheticCollection::n == 4){
	  foreach my $temp1 (sort keys %{$Clair::SyntheticCollection::public_ngram_map->{$current}}){
	      foreach my $temp2 (sort keys %{$Clair::SyntheticCollection::public_ngram_map->{$current}->{$temp1}}){
		  foreach my $temp3 (sort keys %{$Clair::SyntheticCollection::public_ngram_map->{$current}->{$temp1}->{$temp2}}){
		      push (@possible_next, "$temp1 $temp2 $temp3");
		      push (@weights, $Clair::SyntheticCollection::public_ngram_map->{$current}->{$temp1}->{$temp2}->{$temp3});
		  }
	      }
	  }
      }

      ## DEBUG
      #print "\nPOSSIBLE NEXT:\n";
      #foreach $a (@possible_next){print "\"$a\"\n";} sleep(5);
      ## /DEBUG

      if (scalar @possible_next == 1){
	  ## DEBUG
	  #print "Using only possibility: \"$possible_next[0]\"\n";
	  ## /DEBUG
	  return $possible_next[0];
      }
      elsif (scalar @possible_next == 0){
	  return " ";
	  ## DEBUG
	  #print "(No possibilities)\n";
	  ## /DEBUG
      }

      my $temp_freq;

      # The 0th element in the weights array has to be nonsense -- the RandomDist object disregards it
      unshift @weights, 0;

      # Get distribution array if n_gram == 2 (because we did it for n_gram > 2 earlier)
      if($Clair::SyntheticCollection::n == 2){
	  foreach my $temp_word (@possible_next){
	      $temp_freq = $Clair::SyntheticCollection::public_ngram_map->{$current}->{$temp_word};
	      push (@weights, $temp_freq);
	  }
      }

      my $distribution = Clair::RandomDistribution::RandomDistributionFromWeights->new(weights => \@weights);
      $next = $possible_next[$distribution->draw_rand_from_dist() - 1];
      return $next;
  };

  while ($docs_itor--) {
    # Get a document length for this doc
    if ($mirror_doclen) {
      # Mirror the existing document length distribution
      $cur_doclen = $doclen_map->[$docs_itor];
    } else {
      # Otherwise uniform document length or from distribution
      $cur_doclen = ($uniform_doclen ||
                     $doclen_map->[$doclen_dist->draw_rand_from_dist()]);
    }

    # Create the output file
    open (OUT, ">$self->{docs_dir}/synth.$docs_itor") ||
     croak "Could not create file $self->{docs_dir}/synth.$docs_itor\n";

    if($self->{n_gram} == 1){
	# Generate random terms based on term dist
	while ($cur_doclen--) {
	    my $r = $term_dist->draw_rand_from_dist();
	    my $term = $term_map->[$r-1];
	    print OUT $term;
	    print OUT " ";
#           print STDERR "r: $r, term: $term\n";
	}
	print OUT "\n";
    }
    else{
	my $start_token = "<START>";
	my $end_token = "<END>";
	my $sentence_token = "<S>";
	
	# As of Aug 7 2009, $smoothing can only be 1.
	# This is used to determine overlap between n-grams.
	# To bring smoothing to its full range (1 through n_grams-1),
	# modify get_next_state() to take n-grams as input, not just unigrams.
	my $smoothing = 1;
	
	my $current = $start_token;

	# Generate using n-grams

	my $quit = 0;
	my $counter = 0;
	while ($cur_doclen -= ($self->{n_gram}-$smoothing)){
	    last if($cur_doclen < ($self->{n_gram}-$smoothing));

	    # Output is ($n - $smoothing) terms long
	    my $temp_ngram = &$get_next_state($current);

	    my @temp_array = split(/ /, $temp_ngram);
	    if (scalar(@temp_array) == 0){
		# DEBUG
		#print "\nEnd of file $self->{docs_dir}/synth.$docs_itor\n\n";
		# /DEBUG

		print OUT "\n";
		last;
	    }


	    # DEBUG
	    #print "Picked: \"$temp_ngram\"\n";
	    # /DEBUG

	    foreach my $temp_term (@temp_array){
		if($temp_term eq " " || $temp_term eq $end_token){ $quit = 1; last; }
		elsif($temp_term eq $sentence_token){
		    print OUT "\n";
		}
		else{
		    print OUT "$temp_term ";
		}
	    }
	    
	    if($quit == 1){
		# DEBUG
		#print "\nEnd of file $self->{docs_dir}/synth.$docs_itor\n\n";
		# /DEBUG

		if ($counter == 0){ print STDERR "Warning: $self->{docs_dir}/synth.$docs_itor is empty"; }
		print OUT "\n";
		last;
	    }
	    
	    # Here is where smoothing comes into play (as of Aug 7 2009, not much use)
	    # to make $smoothing more useful, modify this line as well as get_next_state().
	    # This line should set $current to an n-gram of size $smoothing, and
	    # get_next_state() should be able to handle n-grams with n > 1
	    $current = $temp_array[0 - $smoothing];
	    $counter++;
	}
    }

    close (OUT);

    # Add this file to the list
    print FILES "synth.$docs_itor\n";
  }

  close (FILES);

  # Make sure stats dir exists
  unless (-d $self->{stats_dir}) {
    mkdir ($self->{stats_dir}, 0775) || 
      croak "Could not create directory $self->{stats_dir}\n";
  }

  # Store the file count
  open (NUMDOCS, ">$self->{stats_dir}/num_docs.txt") ||
    croak "Could not create file $self->{stats_dir}/num_docs.txt\n";
  print NUMDOCS $self->{size};
  close (NUMDOCS);
}

1;
