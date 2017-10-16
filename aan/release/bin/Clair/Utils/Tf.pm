package Clair::Utils::Tf;

use strict;

use File::Spec;
#use ALE::Stemmer qw(ale_stemsome);
use Lingua::Stem;
use Lingua::Stem::En;
use Clair::Config;

use vars qw($verbose);

$verbose = 0;

#--------------------------------------------------------------
=pod

=head1 NAME

Tf

=head1 SYNOPSIS

my $val = $tf->getTfForWord($word);

=head1 DESCRIPTION

The TF object is stored as a subdirectory of files.
Therefore, unlike the case of the IDF, there is no compelling
reason to maintain a TF object instantiation between
calls to the TF.  However, it was thought desirable to make the usage
of this module resemble the usage of the IDF module.

=head1 METHODS

=head2 $tfref = Clair::Utils::Tf::new($rootdir => "/data0/projects/tfidf", $corpusname => "mytf", $stemmed => 1);

=head3 $rootdir:

(optional) Directory in which the TF is stored.  Default is
"/data0/projects/tfidf"

=head3 $corpusname:

(required) Name of the corpus the TF was built from.

=head3 $stemmed:

(optional) Pass 1 to use the stemmed TF, 0 to use the
unstemmed TF.  If the TF requested does not exist, the

=head2 $count = $tfref->getNumDocsWithWord($word)

returns number of documents in corpus with this word

=head2 $count = $tfref->getNumDocsWithPhrase(@phrase)

returns number of documents in corpus with this phrase,
where phrase is an array the elements of which in order
constitute the words of the phrase

=head2 $count = $tfref->getFreqInDocument($word)

returns number of occurrences of this word in the
specified document

=head2 ($count, $pMatchingPositions) = $tfref->getPhraseFreqInDocument(\@phrase)

returns number of occurrences of this phrase in the
specified document ($count), as well as a reference
to a hash ($pMatchingPositions) whose keys are the
positions at which the phrase occurs

=head2 $count = $tfref->getFreq($word)

returns total number of occurrences of this word in all
documents in the corpus

=head2 $count = $tfref->getPhraseFreq(@phrase)

return total number of occurrences of this phrase in all
documents in the corpus

=head2 @urls = $tfref->getDocs($word)

returns an array containing the URLs of documents that have this word.

=head2 $refPosByUrl = $tfref->getDocsWithPhrase(@phrase)

returns a reference to a hash containing, for each document with this phrase,
a key equal to the document URL, with value equal to a
reference to an array containing all the positions at which
the phrase occurs in that document

=head2 %docScores = $tfref->getDocsMatchingFuzzyORQuery(\@terms, \@negTerms, \@phrases, \@negPhrases)

returns a hash with keys equal to the URLs of documents matching
a query specified with unnegated terms, negated terms,
unnegated phrases, and negated phrases, using fuzzy OR;
the value of a key is the corresponding document's score,
which is 1 point for each occurrence of each term matched, and
N points for each occurrence of each N-term phrase matched.

=cut

#--------------------------------------------------------------


my %basis = qw(0 0 1 1 2 2 3 3 4 4 5 5 6 6 7 7 8 8 9 9
               a 10 b 11 c 12 d 13 e 14 f 15 g 16 h 17
               i 18 j 19 k 20 l 21 m 22 n 23 o 24 p 25 q
               26 r 27 s 28 t 29 u 30 v 31 w 32 x 33 y 34 z 35);

sub new  {
   my $class = shift;
   my %args = @_;

   my $rootdir = "/data0/projects/tfidf";
   if ( $args{rootdir} )  {
      $rootdir = $args{rootdir};
   }

   if ( ! $args{corpusname} )  {
      print "Corpus name must be specified\n";
      return;
   }
   my $corpusname = $args{corpusname};
   my $stemmed = ( defined $args{stemmed} ? $args{stemmed} : 0 );

   my %self = ('rootdir' => $rootdir,
               'corpusname'  => $corpusname,
               'stemmed' => $stemmed);


   bless (\%self, $class);
   return (\%self);

}

# if the word is not in the dbm, return this value.
my $DEFAULT_UNKNOWN_IDF = -1;


# --------------------------------------------------------------
#   Returns number of documents in corpus with the word
# --------------------------------------------------------------
sub getNumDocsWithWord {
  my $self = shift();
  my $word = shift();

  my $rootdir    = $self->{rootdir};
  my $corpusname = $self->{corpusname};
  my $stemmed    = $self->{stemmed};

  $word = lc($word);

  if ( $stemmed )  {
      my $stemmer = Lingua::Stem->new(-locale => 'EN-US');
      $stemmer->stem_caching({-level => 2});
      my @temp0;
      push (@temp0, $word);
      my $temp1 = $stemmer->stem(@temp0);
      $word = pop(@$temp1);
  }

    my $workdir = "$rootdir/corpus-data";
  my $tfdir = ( $stemmed ? "$workdir/$corpusname-tf-s" : "$workdir/$corpusname-tf" );

  my $w1 = substr($word,0,1);
  my $w2 = substr($word,1,1);
  my $w3 = substr($word,2);

  # If the term is not in the index, behave gracefully
  my $file = ((length $word > 1) ? "$tfdir/$w1/$w1$w2/$word.tf" : "$tfdir/$w1/$word.tf");
  return 0 if (!open(FILE, $file));
  close (FILE);

  my $result = `wc -l $file`;
  chomp($result);

  $result =~ m/(\d+)/;
  return $1;
}


# --------------------------------------------------------------
#   Returns number of documents in corpus with the phrase
# --------------------------------------------------------------
sub getNumDocsWithPhrase {
   my $self = shift;

   return scalar keys %{$self->getDocsWithPhrase(@_)};
}


# --------------------------------------------------------------
#   Returns the number of occurrences of the word in the
#   specified document
# --------------------------------------------------------------
sub getFreqInDocument {
	my $self = shift;
	my $word = shift;

	my %parameters = @_;

	my $rootdir = $self->{rootdir};
	my $corpusname = $self->{corpusname};
	my $stemmed = $self->{stemmed};

        $word = lc($word);

	if ($stemmed) {
             my $stemmer = Lingua::Stem->new(-locale => 'EN-US');
             $stemmer->stem_caching({-level => 2});
             my @temp0;
             push (@temp0, $word);
             my $temp1 = $stemmer->stem(@temp0);
             $word = pop(@$temp1);
	}

	if ( (defined $parameters{url} and defined $parameters{docid}) or
	     (not defined $parameters{url} and not defined $parameters{docid}) ) {
		die "Must specify either url or docid.";
	}

        my $workdir = "$rootdir/corpus-data";
	my $tfdir = ($stemmed ? "$workdir/$corpusname-tf-s" : "$workdir/$corpusname-tf" );

	my $COMPRESS_DBM_NAME = "$workdir/$corpusname/$corpusname-compress-docid";
	my $TO_DOCID_DBM_NAME = "$workdir/$corpusname/$corpusname-url-to-docid";

	# Get the docid
	my $docid = $parameters{docid};
	if (defined $parameters{url}) {
	    my $url = $parameters{url};
	    my %to_docids = ();
	    dbmopen %to_docids, $TO_DOCID_DBM_NAME, 0666 or
	       die "Can't open '$TO_DOCID_DBM_NAME'";

	    $docid = $to_docids{$url};
	    dbmclose %to_docids;
	}


	# Get the compressed id
	my $comp_id;
	my %compress = ();
	dbmopen %compress, $COMPRESS_DBM_NAME, 0666 or
	    die "Can't open '$COMPRESS_DBM_NAME'";

	$comp_id = $compress{$docid};
	dbmclose %compress;

	# Open the tf file
	my @parts = split(//, $word);

	my $numdirs = 2;
	my $dir1 = $parts[0];
	my $dir2 = $parts[1] or $numdirs = 1;

        # If the term is not in the index, behave gracefully
        my $file = ($numdirs == 1 ? "$tfdir/$dir1/$word.tf" : "$tfdir/$dir1/$dir1$dir2/$word.tf");
        return 0 if (!open(FILE, $file));

	foreach (<FILE>) {
	    chomp;

	    # See if the first item (the id) matches the compressed id
	    # And, if so, return the second item (the frequency)
	    my @parts=split;
	    if ($parts[0] eq $comp_id) {
	       close FILE;
	       return $parts[1];
	    }
	}

	close FILE;

	return 0;
}


# --------------------------------------------------------------
#   Returns the number of occurrences of the phrase in the
#   specified document, as well as a reference to a hash
#   whose keys are the positions at which the phrase occurs
# --------------------------------------------------------------
sub getPhraseFreqInDocument {
   my $self = shift;
   my $pTerms = shift;
   my @terms = map(lc($_), @{$pTerms});

   my %params = @_;

   my $stemmed = $self->{stemmed};

   if ( $stemmed ) {
      my $stemmer = Lingua::Stem->new(-locale => 'EN-US');
      $stemmer->stem_caching({-level => 2});
      my @temp0 = @terms;
      my $temp1 = $stemmer->stem(@temp0);
      @terms = @$temp1;
  }

   if ( (defined $params{url} and defined $params{docid}) or
        (not defined $params{url} and not defined $params{docid}) ) {
            die "Must specify either url or docid.";
   }

   # If phrase contains only 1 term...
   if (scalar @terms == 1) {
      my $rootdir = $self->{rootdir};
      my $corpusname = $self->{corpusname};

        my $workdir = "$rootdir/corpus-data";
      my $tfdir = ($stemmed ? "$workdir/$corpusname-tf-s" : "$workdir/$corpusname-tf" );
      my $COMPRESS_DBM_NAME = "$workdir/$corpusname/$corpusname-compress-docid";
      my $TO_DOCID_DBM_NAME = "$workdir/$corpusname/$corpusname-url-to-docid";

      # Get the docid
      my $docid = $params{docid};
      if (defined $params{url}) {
         my $url = $params{url};
         my %to_docids = ();
	 dbmopen %to_docids, $TO_DOCID_DBM_NAME, 0666 or
            die "Can't open '$TO_DOCID_DBM_NAME'";
         $docid = $to_docids{$url};
         dbmclose %to_docids;
      }

      # Get the compressed id
      my $comp_id;
      my %compress = ();
      dbmopen %compress, $COMPRESS_DBM_NAME, 0666 or
	 die "Can't open '$COMPRESS_DBM_NAME'";
      $comp_id = $compress{$docid};
      dbmclose %compress;

      my $word = $terms[0];
      # Open the tf file
      my @parts = split(//, $word);
      my $numdirs = 2;
      my $dir1 = $parts[0];
      my $dir2 = $parts[1] or $numdirs = 1;

      my %matchingPositions = ();  # Store term occurrence positions

      # If the term is not in the index, behave gracefully
      my $file = ($numdirs == 1 ? "$tfdir/$dir1/$word.tf" : "$tfdir/$dir1/$dir1$dir2/$word.tf");


      return (scalar keys %matchingPositions, \%matchingPositions) if (!open(FILE, $file));

      foreach (<FILE>) {
	 chomp;
	 # See if the first item (the id) matches the compressed id
         # And, if so, return the second item (the frequency)
	 my @parts=split;
	 if ($parts[0] eq $comp_id) {
            close FILE;
            die "Index is not positional--rebuild index to obtain phrase query support" if (scalar @parts < 3);
            my @matchingPositions = @parts[2..$#parts];  # Grab term occurrence positions
            foreach (@matchingPositions) { $matchingPositions{base36_to_base10($_)} = 1; }
	    return (scalar keys %matchingPositions, \%matchingPositions);
	 }
      }
      close FILE;

      return (scalar keys %matchingPositions, \%matchingPositions);
   }
   # If phrase contains more than 1 term...
   elsif (scalar @terms > 1) {
      my @freqByTerm = ();
      my @posByTerm = ();
      my $minIdx = 0;

      my %matchingPositions = ();

      for (my $i = 0; $i < scalar @terms; $i++) {
         ($freqByTerm[$i], $posByTerm[$i]) = $self->getPhraseFreqInDocument([$terms[$i]], url => $params{url});
         return (scalar keys %matchingPositions, \%matchingPositions) if ($freqByTerm[$i] == 0);
         # Determine the least frequently occurring term in the phrase
         $minIdx = ($freqByTerm[$i] < $freqByTerm[$minIdx] ? $i : $minIdx);
      }

      # Find positions of occurrence of entire phrase...
      # Store positions of occurrence of most frequently occurring term (middle of potential phrase)
      my @middlePositions = keys %{$posByTerm[$minIdx]};
      # At each position where middle term occurs, attempt to match rest of phrase
      for (my $i = 0; $i < scalar @middlePositions; $i++) {
         my $match = 1;
         for (my $j = 0; $j < scalar @posByTerm; $j++) {
            $match = 0 if (!defined $posByTerm[$j]->{$middlePositions[$i]+$j-$minIdx});
            last if (!$match);
         }
         # Record initial term position of matching term
         $matchingPositions{$middlePositions[$i]-$minIdx} = 1 if ($match);
      }

      return (scalar keys %matchingPositions, \%matchingPositions);
   }
}


# --------------------------------------------------------------
#   Returns total number of occurrences of the word in all
#   documents in the corpus
# --------------------------------------------------------------
sub getFreq {
  my $self = shift();
  my $word = shift();

  my $rootdir    = $self->{rootdir};
  my $corpusname = $self->{corpusname};
  my $stemmed    = $self->{stemmed};

  $word = lc($word);

  if ( $stemmed )  {
      my $stemmer = Lingua::Stem->new(-locale => 'EN-US');
      $stemmer->stem_caching({-level => 2});
      my @temp0;
      push (@temp0, $word);
      my $temp1 = $stemmer->stem(@temp0);
      $word = pop(@$temp1);
  }

    my $workdir = "$rootdir/corpus-data";
  my $tfdir = ( $stemmed ? "$workdir/$corpusname-tf-s" : "$workdir/$corpusname-tf" );

  my $w1 = substr($word,0,1);
  my $w2 = substr($word,1,1);
  my $w3 = substr($word,2);

  # If the term is not in the index, behave gracefully
  my $file = ((length $word > 1) ? "$tfdir/$w1/$w1$w2/$word.tf" : "$tfdir/$w1/$word.tf");
  return 0 if (!open(FILE, $file));

  my $result = 0;
  foreach (<FILE>)  {
    chomp;
    my @parts=split(/ /, $_);
    $result += $parts[1];
  }
  close FILE;

  return $result;
}


# --------------------------------------------------------------
#   Returns total number of occurrences of the phrase in all
#   documents in the corpus
# --------------------------------------------------------------
sub getPhraseFreq {
   my $self = shift;
   my @terms = map(lc($_), @_);

   my $stemmed = $self->{stemmed};

   if ( $stemmed ) {
      my $stemmer = Lingua::Stem->new(-locale => 'EN-US');
      $stemmer->stem_caching({-level => 2});
      my @temp0 = @terms;
      my $temp1 = $stemmer->stem(@temp0);
      @terms = @$temp1;
   }

   # If phrase contains only 1 term...
   if (scalar @terms == 1) {
      return $self->getFreq($terms[0]);
   }
   # If phrase contains more than 1 term...
   elsif (scalar @terms > 1) {
      my $pMatchingPositionsByUrl = $self->getDocsWithPhrase(@terms);
      my $total = 0;
      foreach my $url (keys %$pMatchingPositionsByUrl) {
         $total += scalar keys %{$pMatchingPositionsByUrl->{$url}};
      }

      return $total;
   }
}


# --------------------------------------------------------------
#   Returns an array containing URLs of documents
#   that have this word
# --------------------------------------------------------------
sub getDocs {
  my $self = shift();
  my $word = shift();

  my $rootdir    = $self->{rootdir};
  my $corpusname = $self->{corpusname};
  my $stemmed    = $self->{stemmed};

  $word = lc($word);

  if ( $stemmed )  {
      my $stemmer = Lingua::Stem->new(-locale => 'EN-US');
      $stemmer->stem_caching({-level => 2});
      my @temp0;
      push (@temp0, $word);
      my $temp1 = $stemmer->stem(@temp0);
      $word = pop(@$temp1);
  }

    my $workdir = "$rootdir/corpus-data";
  my $tfdir = ( $stemmed ? "$workdir/$corpusname-tf-s" : "$workdir/$corpusname-tf" );

  my $EXPAND_DBM_NAME = "$workdir/$corpusname/$corpusname-expand-docid";
  my $TO_URL_DBM_NAME = "$workdir/$corpusname/$corpusname-docid-to-url";

  my $w1 = substr($word,0,1);
  my $w2 = substr($word,1,1);
  my $w3 = substr($word,2);

  my @urls = ();

  # If the term is not in the index, behave gracefully
  my $file = ((length $word > 1) ? "$tfdir/$w1/$w1$w2/$word.tf" : "$tfdir/$w1/$word.tf");
  open(FILE, $file) or return @urls;
  close(FILE);
  my @matches = `cat $file`;

   my %to_urls = ();
  dbmopen %to_urls, $TO_URL_DBM_NAME, 0666 or
        die "Can't open '$TO_URL_DBM_NAME'";


 my %expand = ();
  dbmopen %expand, $EXPAND_DBM_NAME, 0666 or
        die "Can't open '$EXPAND_DBM_NAME'";

  foreach (@matches) {
    chop;
    my ($id,$ct) = split (/ /,$_);
     push (@urls, "$to_urls{$expand{$id}}");
  }

  dbmclose %to_urls;
  dbmclose %expand;

  return @urls;
}


# --------------------------------------------------------------
#   Returns a reference to a hash containing, for each document
#   with this phrase, a key equal to the document URL, with
#   value equal to a reference to an array containing all the
#   positions at which the phrase occurs in that document
# --------------------------------------------------------------
sub getDocsWithPhrase {
   my $self = shift;
   my @terms =  map(lc($_), @_);
   my $stemmed = $self->{stemmed};

   if ( $stemmed ) {
      my $stemmer = Lingua::Stem->new(-locale => 'EN-US');
      $stemmer->stem_caching({-level => 2});
      my @temp0 = @terms;
      my $temp1 = $stemmer->stem(@temp0);
      @terms = @$temp1;
   }

   # If phrase contains only 1 term...
   if (scalar @terms == 1) {
      my $rootdir    = $self->{rootdir};
      my $corpusname = $self->{corpusname};

        my $workdir = "$rootdir/corpus-data";
      my $tfdir = ( $stemmed ? "$workdir/$corpusname-tf-s" : "$workdir/$corpusname-tf" );
      my $EXPAND_DBM_NAME = "$workdir/$corpusname/$corpusname-expand-docid";
      my $TO_URL_DBM_NAME = "$workdir/$corpusname/$corpusname-docid-to-url";

      my $word = $terms[0];
      my $w1 = substr($word,0,1);
      my $w2 = substr($word,1,1);
      my $w3 = substr($word,2);

      my %matchingPositionsByUrl = ();

      # If the term is not in the index, behave gracefully
      my $file = ((length $word > 1) ? "$tfdir/$w1/$w1$w2/$word.tf" : "$tfdir/$w1/$word.tf");
      my @matches = `cat $file` or return \%matchingPositionsByUrl;

      my %to_urls = ();
      dbmopen %to_urls, $TO_URL_DBM_NAME, 0666 or
         die "Can't open '$TO_URL_DBM_NAME'";
      my %expand = ();
      dbmopen %expand, $EXPAND_DBM_NAME, 0666 or
         die "Can't open '$EXPAND_DBM_NAME'";

      foreach (@matches) {  # For each document containing the term...
         chop;
         my ($id,$ct,@matchingPositions) = split (/ /,$_);  # Get docid, tf, and list of positions of occurrence
         die "Index is not positional--rebuild index to obtain phrase query support" if (scalar @matchingPositions < 1);
         my %matchingPositions = ();
         foreach (@matchingPositions) { $matchingPositions{base36_to_base10($_)} = 1; }
         # Store list of matching positions by document URL
         $matchingPositionsByUrl{"$to_urls{$expand{$id}}"} = \%matchingPositions if (scalar keys %matchingPositions > 0);
      }
      dbmclose %to_urls;
      dbmclose %expand;

      return \%matchingPositionsByUrl;
   }
   # If phrase contains more than 1 term...
   elsif (scalar @terms > 1) {
      my @posByUrlByTerm = ();
      my $minIdx = 0;
      for (my $i = 0; $i < scalar @terms; $i++) {
         # For each term in the phrase, get list of matching positions by document URL
         $posByUrlByTerm[$i] = $self->getDocsWithPhrase($terms[$i]);
         # Determine which term in the phrase occurs in the least number of documents
         $minIdx = (scalar keys %{$posByUrlByTerm[$i]} < scalar keys %{$posByUrlByTerm[$minIdx]} ? $i : $minIdx);
      }

      # Attempt to match each document to phrase via most selective access path
      my %matchingPositionsByUrl = ();
      foreach my $url (keys %{$posByUrlByTerm[$minIdx]}) {
         my $possibleMatch = 1;
         for (my $i = 0; $i < scalar @terms; $i++) {  # A matching document must at least contain each term in phrase
            $possibleMatch = 0 if (!defined $posByUrlByTerm[$i]->{$url});
            last if not $possibleMatch;
         }
         if ($possibleMatch) {  # If document matches all individual terms, attempt to match entire phrase
            my $minMiddleIdx = 0;
            for (my $i = 0; $i < scalar @terms; $i++) {
               # Determine which term in the phrase occurs the least frequently in the current document
               $minMiddleIdx = (scalar keys %{$posByUrlByTerm[$i]->{$url}}
                                  < scalar keys %{$posByUrlByTerm[$minMiddleIdx]->{$url}} ? $i : $minMiddleIdx);
            }
            # Store positions of occurrence of most frequently occurring term (middle of potential phrase)
            my @middlePositions = keys %{$posByUrlByTerm[$minMiddleIdx]->{$url}};
            # At each position where middle term occurs, attempt to match rest of phrase
            my %matchingPositions = ();
            for (my $i = 0; $i < scalar @middlePositions; $i++) {
               my $match = 1;
               for (my $j = 0; $j < scalar @posByUrlByTerm; $j++) {
                  $match = 0 if (!defined $posByUrlByTerm[$j]->{$url}->{$middlePositions[$i]+$j-$minMiddleIdx});
                  last if not $match;
               }
               # Record initial term position of matching term
               $matchingPositions{$middlePositions[$i]-$minMiddleIdx} = 1 if ($match);
            }
            # For each document matching the phrase, store initial term position for each occurrence of term
            $matchingPositionsByUrl{$url} = \%matchingPositions if (scalar keys %matchingPositions > 0);
         }
      }

      return \%matchingPositionsByUrl;
   }
}


# --------------------------------------------------------------
#   Returns a hash with keys equal to the URLs of documents matching
#   a query specified with unnegated terms, negated terms,
#   unnegated phrases, and negated phrases, using fuzzy OR;
#   the value of a key in that hash is the corresponding document's
#   score, which is 1 point for each term matched, and N points for
#   each N-term phrase matched.
# --------------------------------------------------------------
sub getDocsMatchingFuzzyORQuery {
   my $self = shift;
   my ($pTerms, $pNegTerms, $pPhrasePtrs, $pNegPhrasePtrs) = @_;

   my $rootdir = $self->{rootdir};
   my $corpusname = $self->{corpusname};
   my $stemmed = $self->{stemmed};

   # Prepare stemmer (but only use if tf is stemmed)
   my $stemmer = Lingua::Stem->new(-locale => 'EN-US');
   $stemmer->stem_caching({-level => 2});

    my $workdir = "$rootdir/corpus-data";
   my $tfdir = ($stemmed ? "$workdir/$corpusname-tf-s" : "$workdir/$corpusname-tf" );
   my $TO_DOCID_DBM_NAME = "$workdir/$corpusname/$corpusname-url-to-docid";

   # Get a list of all document URLs
   my %to_docids = ();
   dbmopen %to_docids, $TO_DOCID_DBM_NAME, 0666 or die "Can't open '$TO_DOCID_DBM_NAME'";
   my %allUrls = %to_docids;
   dbmclose %to_docids;

    my %docScores = ();
    my @individualTerms = ();
    # Score documents matching unnegated terms
    foreach my $term (($stemmed ? @{$stemmer->stem(@$pTerms)} : @$pTerms)) {
        push @individualTerms, $term;
        foreach ($self->getDocs($term)) {
            # Award 1 point to each matching document for each occurrence of the term
            my $occurrences = $self->getFreqInDocument($term, url => $_);
            $docScores{$_} = (defined $docScores{$_} ? $docScores{$_} + $occurrences : $occurrences);
        }
    }
# Score documents matching negated terms (by computing complement of matches to unnegated terms)
    foreach my $negTerm (($stemmed ? @{$stemmer->stem(@$pNegTerms)} : @$pNegTerms)) {
	    my %docUrls = %allUrls;
	    foreach ($self->getDocs($negTerm)) {
		    delete $docUrls{$_};
	    }
	    foreach (keys %docUrls) {
# Award 0 points to each matching document
		    $docScores{$_} = (defined $docScores{$_} ? $docScores{$_} + 0 : 0);
	    }
    }
# Score documents matching unnegated phrases
    foreach my $pPhrase (@$pPhrasePtrs) {
	    foreach (keys %{$self->getDocsWithPhrase(($stemmed ? @{$stemmer->stem(@$pPhrase)} : @$pPhrase))}) {
# Award N points to each matching document for each occurrence of the length-N phrase
		    my ($occurrences) = $self->getPhraseFreqInDocument($pPhrase, url => $_);
		    $docScores{$_} = (defined $docScores{$_} ? $docScores{$_} + $occurrences * scalar @$pPhrase
				    : $occurrences * scalar @$pPhrase);
	    }
    }
# Score documents matching negated phrases (by computing complement of matches to unnegated phrases)
    foreach my $pNegPhrase (@$pNegPhrasePtrs) {
	    my %docUrls = %allUrls;
	    foreach (keys %{$self->getDocsWithPhrase(($stemmed ? @{$stemmer->stem(@$pNegPhrase)} : @$pNegPhrase))}) {
		    delete $docUrls{$_};
	    }
	    foreach (keys %docUrls) {
		    $docScores{$_} = (defined $docScores{$_} ? $docScores{$_} + 0 : 0);
	    }
    }

    return \%docScores;
}


sub base36_to_base10 {
	my ($input) = @_;

	my $result = 0;
	my $length = length $input;
#    print "$length\n";

	foreach my $i (0..$length-1){
		$result += $basis{substr($input,$i,1)}*(36**($length-$i-1));
	}

	return $result;
}



1;
