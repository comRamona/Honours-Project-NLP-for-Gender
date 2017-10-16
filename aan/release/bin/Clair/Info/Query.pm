package Clair::Info::Query;

=head1 NAME

B<package> Clair::Info::Query
A module that implements different types of queries.

=head1 AUTHOR

JB Kim
L<jbremnant@gmail.com>
20070407

=head1 SYNOPSIS

This module contains bulk of the query retrieval algorithm using the inverted index.
At the core, it initializes the necessary indexes from the Index.pm object, 
and keeps the perl hash data structures in memory for query processing.
if the instantiated Index.pm object is not supplied in the constructor, it will
attempt to instantiate it.

The constructor initializes these three indexes by default (can be overriden):

=over 8

=item document_index, document_meta_index

=back

The significant flags for constructor are:

=over 8

=item required_indexes - an array reference containing the names of indexes to initialize.

=item default_query_logic - defaults to fuzzy_or_merge, this is the name of the subroutine.

=back

Once the Clair::Info::Query object is instantiated, various queries are possible. For example:

	use Clair::Info::Query;
  
	my $q = Clair::Info::Query(DEBUG => $DEBUG);

	$tokens_string = '"juliet romeo"';
	my $output = $q->process_query($tokens_string);
	$output = $q->document_frequency("juliet")',
	$output = $q->words_frequency("romeo")',

Where, $output variable contains either ARRAY-ref or the HASH-ref of results.


=head1 DESCRIPTION

while some query functions can be taken off of this module and placed elsewhere, this module
implement standard query retrieval functions from inverted index. One highlight of this 
module is the fact that it supports N-gram tokens (phrases) search.

=cut


# use FindBin;
# use lib "$FindBin::Bin/../lib/perl5/site_perl/5.8.5";
# use lib "$FindBin::Bin/lib/perl5/site_perl/5.8.5";

use strict;
use vars qw/$DEBUG/;

use Clair::Debug;
use Clair::GenericDoc;
use Clair::StringManip;
use Clair::Index;
use Data::Dumper;


=head2 new

 The constructor. It instantiates the Clair::Index.pm object by default and initializes 
 various meta indexes, except the inverted index. The inverted index gets dynamically
 loaded on-demand, depending on the query.

=cut

sub new
{
	my ($proto, %args) = @_;
	my $class = ref $proto || $proto;

	my $self = bless {}, $class;
	$DEBUG = $args{DEBUG} || $ENV{MYDEBUG};

	$self->{index_obj} = "";
	$self->{required_indexes} = [ qw/document_index document_meta_index/ ];

	# word_index now deprecated
	# $self->{word_index} = {};
	$self->{document_index} = {};
	$self->{document_meta_index} = {};
	$self->{inverted_index} = {};

	$self->{stem_query} = 1;
	$self->{default_query_logic} = "fuzzy_or_merge";

	$self->{stop_word_list} = "";
	$self->{generic_doc_module_root} = "";

	# overrides
	while ( my($k, $v) = each %args )
	{
		$self->{$k} = $v if(defined $v);
	}

	# required indexes upon init.
	if(! $self->{index_object} || ! UNIVERSAL::isa($self->{index_object}, "Clair::Index"))
	{
		# force loading?
		$self->{index_object} = new	Clair::Index(DEBUG => $DEBUG);
	}
		
	my %info = $self->{index_object}->init(
		# word_index => "word_idx",
		document_index => 1,
		document_meta_index => 1,
	);
	$self->{$_} = $info{$_} for (keys %info);

	for my $ikey (@{$self->{required_indexes}})
	{
		unless($self->{$ikey} && scalar keys %{$self->{$ikey}})
		{
			$self->debugmsg("following indexes need to be initialized:", 0);
			$self->debugmsg($self->{required_indexes}, 0);
			exit;
		}
	}

	# initialize the stop word list
	if(-f $self->{stop_word_list})
  {
		open W, "< $self->{stop_word_list}" or $self->errmsg("cannot open $self->{stop_word_list}: $!", 1);
		my @lines = <W>;
		close W;
		chomp @lines;

		my $strmanip = new Clair::StringManip(DEBUG => $DEBUG);
		@lines = @{ $strmanip->stem(\@lines, 1) };

		$self->{stop_word_list_stemmed} = { map { $_ => 1 } grep { /\w+/ } @lines };
	}


  return $self;
}


=head2 normalize_input

 Just a wrapper around the real subroutine implemented under StringManip package.
 Also, if the index is created without the stop_words, the query string should
 also omit the stop words. The stop word list is supplied the same way as it did
 on Clair/Index.pm, via the constructor.

=cut

sub normalize_input
{
	my ($self, $input, $no_stem) = @_;

	my $strmanip = new Clair::StringManip(DEBUG => $DEBUG);

	my $tokens = $strmanip->normalize_input($input, $no_stem);

	if(UNIVERSAL::isa($self->{stop_word_list_stemmed}, "HASH"))
	{
		my @tmp = grep { ! $self->{stop_word_list_stemmed}->{$_} } @$tokens;
		$tokens = \@tmp;
	}

	return $tokens;
}


=head2 process_query
 
 This subroutine is the entry point for "normal" query strings. Multi-word phrase
 queries are supported, as well as negation of the query using various private
 routines.

 The only required input parameter is the actual query string supplied by the user.
 The output is either a reference to an array or a reference to a hash, which can
 be specified by a second boolean input parameter.

=cut


sub process_query
{
	my ($self, $input, $return_hash) = @_;
	
	my $tokens = $self->normalize_input($input);

	my %collection;
	# for every token
	for my $token (@$tokens)
	{
		my $char = substr $token, 0, 1;
		my $negation = 0;

		if($char eq '!')
		{
			# do negation here
			$char = substr $token, 1, 1; # take out the first char after !
			$token = substr $token, 1; 
			$negation = 1;
		}
		
		my $docs = $self->_return_doc_for_token($token, $negation);

		$collection{$token} = {
			negation => $negation,
			results => $docs,
		} if(scalar keys %$docs);

	}
	
	# score the documents based on the logic chosen
	my $scored = $self->result_logic($self->{default_query_logic}, \%collection);

	# for additional info about the doc
	my $doc_meta = $self->{document_meta_index};

	return \%collection if($return_hash);

	# do sorting based on the scoring of docs
	my @output = reverse map {
			sprintf '%-8s : %-8s  [%-20s] %s', $_, $scored->{$_}, $doc_meta->{$_}->{filename},  $doc_meta->{$_}->{title}
		} sort { $scored->{$a} <=> $scored->{$b} } keys %$scored;

	unshift @output, sprintf '%-8s : %-8s  [%-20s] %s', "doc_id", "score", "play", "document title" if(scalar @output);

	return \@output;	
}


=head2 result_logic

 Again, a wrapper subroutine that runs one of the underlying subroutines
 that operate on returned result set from the query. The default query
 result set processing is "fuzzy or" logic.

=cut

sub result_logic
{
	my ($self, $method, $collection) = @_;

	# implements different ways to score and prioritize query result
	unless($self->can($method))
	{
		$self->errmsg("method $method not implemented", 1);
	}
	return $self->$method($collection);
}


=head2 fuzzy_or_merge

 Implements "fuzzy or" logic by returning all documents pertaining to query
 tokens. A very rudimentary document scoring is done by simply counting the
 number of times a particular token occurs in the document. The counting uses
 the number of existing positions recorded in the second tier of the inverted
 hash.

=cut

sub fuzzy_or_merge
{
	my ($self, $collection) = @_;

	my %scored;
	for my $tok (keys %$collection)
	{
		my $docs = $collection->{$tok}->{results};
		$scored{$_} += $docs->{$_} for (keys %$docs); # merge scores
	}

	return \%scored;
}


=head2 _load_index_for_word

 This function is used to load a chunk of of the entire inverted index on
 demand. The segmentation of the index is dependent on the Index/<format>.pm
 sub-module. Thus, we blindely trust the subset of the inverted index returned
 by the call B<index_read> within Index.pm module.

 The actual word being searched is passed into the method. The underlying 
 index submodule should have a corresponding index_read function that takes
 care of returning the appropriate data in a hash.

=cut

sub _load_index_for_word
{
	my ($self, $word) = @_;
	
	if(exists $self->{inverted_index}->{$word})
	{
		$self->debugmsg("already loaded index for word '$word'", 1);
		return { $word => $self->{inverted_index}->{$word} };
	}

	my $index_chunk = $self->{index_object}->index_read($self->{index_object}->{index_file_format}, $word);

	# add onto our index.
	map { $self->{inverted_index}->{$_} = $index_chunk->{$_} } keys %{$index_chunk};

	return { $word => $self->{inverted_index}->{$word} };
}


=head2 _return_doc_for_token

 This subroutine, by default, handles combinations of single word queries. If it 
 encounters query token containing phrases, it will run another private subroutine
 B<_return_doc_for_ngram> to handle it.

 The input parameters are 1) the query token (single word or phrase), 2) the associated
 subset of inverted index, 3) and a boolean flag indicating whether it's a negation
 or not.

 The return value is a hash reference containing the document id's and their 
 scores.

=cut

sub _return_doc_for_token
{
	my ($self, $token, $negation) = @_;

	$self->debugmsg("searching '$token' in the index:", 1);

	my %docs = ();
	# my @words = split /\s+/, $token;
	my @words = @{ $self->normalize_input($token) };
	# $self->debugmsg(\@words, 2);

	# do N-gram search
	if(scalar @words > 1)
	{
		# we obviously can scale more
		# if(scalar @words > 5)
		# {
			# $self->debugmsg("n-gram of size 5 is not supported",0);
			# return {};
		# }
		# support for n-gram is here with positional index algo
		%docs = %{ $self->_return_doc_for_ngram(\@words) };
	}
	# single word lookup
	else
	{
		my $word = shift @words;
		my $index = $self->_load_index_for_word($word);
		$self->debugmsg($index, 2);

		if(exists $index->{$word})
		{
			for my $doc_id (keys %{ $index->{$word} })
			{
				my $score = scalar keys %{ $index->{$word}->{$doc_id} };
				$docs{$doc_id} = $score;
			}
		}
	}

	# all the ones that are _not_ in %doc. And give all of them score = 0.
	if($negation)
	{
		my %temp = map{ $_ => 0 } grep { ! $docs{$_} } keys %{$self->{document_meta_index}};
		%docs = %temp;
	}

	return \%docs;
}


=head2 _return_doc_for_ngram

 This private routine does several things to narrow down and speed up our 
 n-gram (phrase) search. Here is the flow of the algorithm:
 
 1) checks if all the words in the phrase are found in the inverted index-es.
    If not all words are found, it simply returns an empty hash ref.

 2) determines the word that has the least frequency in the given phrase.

 3) retrieves the list of documents for the least frequent word.

 4) finds the "lowest common denominator" list of documents that intersect
    for all words in the phrase. If no intersecting documents are found,
    it simply returns an empty hash ref.

 5) passes the common list of documents and their associated indexes to
    another private subroutine called B<_match_word_positions>. This private
    subroutine resolves the positional dependency among the list of words.

=cut

sub _return_doc_for_ngram
{
	my ($self, $words) = @_;

	# get the document list from the least frequent word
	my %words_freq = ();
	for my $w (@$words)
	{
		my $index = $self->_load_index_for_word($w);
		my $w_count = 0;

		# loop through each doc that contains the word and count the positions.
		for my $d (keys %{ $index->{$w} })
		{
			$w_count += scalar keys %{ $index->{$w}->{$d} }; # add the positions
		}

		# word_index is deprecated now - there's no need for that index anymore
		# my $testcount = $self->{word_index}->{$w}->{count};
		# print "$w_count =? $testcount\n";
		$words_freq{$w} = $w_count;	
	}
	
	$self->debugmsg(\%words_freq, 2);

	# all the words need to exist in our index to find a doc
	if(scalar @$words > scalar keys %words_freq)
	{
		return {};
	}

	# determine the least frequent word - the one that appears in the fewest docs
	my @sorted_freq = sort { $words_freq{$a} <=> $words_freq{$b} } @$words;
	my $least_freq = shift @sorted_freq;
	$self->debugmsg("least frequent word in n-gram: $least_freq", 1);

	# get the document list for each word from our inverted index
	my %docs;
	for my $w (@$words) 
	{
		my $char = substr $w, 0, 1;			
		my $index = $self->_load_index_for_word($w);
		# my $index = $self->{index_object}->index_read($self->{index_object}->{index_file_format}, $w);
		
		$docs{$w} = $index->{$w};
	}	
	my $lowest_common_denom = $docs{$least_freq};

	# get the docs that intersect on all words, looping with the lowest commond denominator
	my %doc_intersect;	
	for my $doc_from_lcd (keys %$lowest_common_denom)
	{
		for my $w (keys %docs)
		{
			map { $doc_intersect{$_}++ if $doc_from_lcd eq $_ } keys %{ $docs{$w} };
			# my @ds = keys %{ $docs{$d} };
			# $doc_count{$_}++ 
		}	
	}
	my @common_docs = grep { $doc_intersect{$_} == scalar @$words } keys %doc_intersect;
	$self->debugmsg("common documents for n-gram token:",1);
	$self->debugmsg(\@common_docs,1);
	
	# no common docs? easy. just return
	return {} unless(scalar @common_docs);

	# now get the positions of words in these common documents
	# my %doc_pos;
	for my $w (keys %docs)
	{
		my %tmp = map { $_ => $docs{$w}{$_} } @common_docs;
		$docs{$w} = \%tmp;
	}

	# now we work with the trimmed-down index of word/doc/position
	$self->debugmsg(\%docs, 2);

	# now the difficult part
	return $self->_match_word_positions($words, \%docs);
}


=head2 _match_word_positions

 This subroutine has the heart of the n-gram match algorithm. The input parameters
 are 1) list of words in the phrase (ordered), and 2) documents that are common
 for all the words in the phrase.

 The algorithm for determining the phrase existency is relatively simple.
 Since the positions for the words in the phrase have to be all next to one another,
 the offset between each word is just 1.

 Thus, by anchoring all the preceding words against the position of the last word
 in the phrase, you can determine the relative offset that a word in the phrase will
 have against the last word in the phrase. For example, consider this phrase:

          "jbkim likes search engine class" 
 
  index:     0     1     2      3     4
  offset:    4     3     2      1     0

 By adding the index for each word against the offset, the matching documents will 
 have a value of "4" for all words in the phrase. From there, we simply count the
 documents that satisfy this condition. This subroutine implements the algorithem
 exactly as described above.

=cut

sub _match_word_positions
{
	my ($self, $words, $docs) = @_;

	my $word_count = scalar @$words;
	my $last_index = scalar @$words - 1;
	my %pos_matrix;

	# the main algorithm for n-gram positional matching
	for my $i (0..scalar @$words - 1)
	{
		# we anchor the position indexes to the last word in the n-gram
		my $diff_pos = $last_index - $i;
		my $w = $words->[$i];

		for my $d (keys %{ $docs->{$w} })
		{
			for my $pos (keys %{ $docs->{$w}->{$d} })
			{
				my $target_pos = $pos + $diff_pos;
				$pos_matrix{$d}{$target_pos}++;
			}
		}
	}

	$self->debugmsg("the positional matrix is:", 1);
	$self->debugmsg(\%pos_matrix, 1);

	my %doc_score;
	for my $d (keys %pos_matrix)
	{
		# for every position recorded, does it match the number of words we have?
		map { $doc_score{$d}++ } grep { $word_count eq $pos_matrix{$d}{$_} } keys %{ $pos_matrix{$d} };
	}
	
	$self->debugmsg(\%doc_score, 1);
	
	return \%doc_score;
}



=head2 term_frequency

 Given user input, returns the number of time a particular term occurs in a document.

=cut

sub term_frequency
{
	my ($self, $input) = @_;

	my ($doc, $term) = split /\s+/, $input;
	my $tokens = $self->normalize_input($term);
	$term = shift @$tokens;

	return [ "provide doc_id and term (eg: tf 4562 rat)" ] if(! $doc || ! $term);

	my $d_index = $self->{document_index};
	# print Dumper($d_index);

	return [ "document with doc_id '$doc' does not exist" ] unless(exists $d_index->{$doc});
	return [ "term '$term' does not exist in document '$doc'" ] unless(exists $d_index->{$doc}->{$term});
	
	$self->debugmsg($d_index->{$doc}->{$term}, 1);

	return [ "term '$term' frequency in doc '$doc' : " . scalar keys %{$d_index->{$doc}->{$term}} ];
}


=head2 words_frequency

 Given user input, either a single term or a phrase, determines the number of times the queried string
 appears in the entire index.

=cut

sub words_frequency
{
	my ($self, $input) = @_;

	my $tokens = $self->normalize_input($input);
	$input = $tokens->[0];

	my $char = substr $input, 0, 1;
	my $index = $self->_load_index_for_word($input);
	my $docs = $self->_return_doc_for_token($input, $index);

	$self->debugmsg($docs, 2);

	my $freq_count = 0;
	for my $d (keys %$docs)
	{
		$freq_count += $docs->{$d};	
	}

	return [ "frequency of token '$input':  $freq_count" ];
}


=head2 document_frequency

 Given user input, either a single term or a phrase, returns the number of documents
 containing it.

=cut

sub document_frequency
{
	my ($self, $input) = @_;

	my $tokens = $self->normalize_input($input);
	$input = $tokens->[0];
	
	my $char = substr $input, 0, 1;
	my $index = $self->_load_index_for_word($input);
	my $docs = $self->_return_doc_for_token($input, $index);

	$self->debugmsg($docs, 2);

	return [ "document frequency: " . scalar keys %$docs ];
}


=head2 document_title

 Given a document ID, returns the document title.

=cut

sub document_title
{
	my ($self, $input) = @_;

	my ($errcode, $di) = $self->_document_info($input);
	return $di unless($errcode); # $di in case of error is the errormsg;
	my $str = "[$di->{filename}] $di->{title}  path: $di->{path}";
	return [$str];
}


=head2 document_content

 Given a document ID, returns the document content, either stemmed or unstemmed.

=cut

sub document_content
{
	my ($self, $input, $strip_and_stem) = @_;

	my ($errcode, $di) = $self->_document_info($input);
	return $di unless($errcode); # $di in case of error is the errormsg;

	my $path = $di->{path};
	my $stem = ($strip_and_stem) ? 1 : 0;
	my $strip = ($strip_and_stem) ? 1 : 0;

	my $gdoc = new Clair::GenericDoc(
		DEBUG => $DEBUG,
		module_root => $self->{generic_doc_module_root} || undef,
		content => $path,
		stem => $stem, strip => $strip
	);
	my $aref = $gdoc->extract();

	return $aref->[0]->{parsed_content};
}


=head2 _document_info

 A private subroutine that actually looks up the doc meta data against the document_meta_index.

=cut

sub _document_info
{
	my ($self, $input) = @_;

	my @tokens = $input =~ m/(!{0,1}\w+|!{0,1}"[\w\s]+")/gs;
	$_ =~ s/["']//g for @tokens;
	$_ =~ s/^\s*|\s*$//g for @tokens;
	
	my $doc_id = shift @tokens;

	unless(exists $self->{document_meta_index}->{$doc_id})
	{
		return (0, "document with id '$doc_id' does not exist");
	}

	my $document_info = $self->{document_meta_index}->{$doc_id};

	$self->debugmsg("document info for doc_id '$doc_id':", 1);
	$self->debugmsg($document_info, 1);

	return (1, $document_info);
}


1;
