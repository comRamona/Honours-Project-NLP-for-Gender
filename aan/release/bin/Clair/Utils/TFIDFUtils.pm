package Clair::Utils::TFIDFUtils;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(split_words
	     uniq
	     count_hash
         position_hash
	     extract_text_from_html

	     lc_words

	     base10_to_base36

	     compress_docid
	     expand_id

	     url_to_docid
	     docid_to_url

	     document_contains

	     stem
	     strip
	     normalize_input);



=pod

=head1 NAME

TFIDFUtils.pm

=head1 SYNOPSIS

(See method descriptions for more information.)

    $res = base10_to_base36($num);
    $d = compress_docid($docid);
    %counthash = count_hash(@words);
    %positionhash = position_hash(@words);
    $url = docid_to_url($docid, $corpus);
    @urls = document_contains($word, $corpus, $stemmed, $min);
    $docid = expand_id($d);
    $text = extract_text_from_html($html);
    @lcwords = lc_words(@words);
    @words = split_words($text, $punc);
    @uniqwords = uniq(@allwords);
    $docid = url_to_docid($url, $corpus);


=head1 DESCRIPTION

A set of general purpose routines originally designed for use
in the TF and IDF building routines, but potentially useful
for other code systems.

Routines url_to_docid, docid_to_url, compress_docid, and expand_id require
that the database for these conversions be already built.  These can be
built with the method CorpusDownload::build_docno_dbm in module
CorpusDownload.pm

=head1 METHODS

=head2 split_words

@words = split_words($text, $punc);

Splits the text string into an array of word strings. Whether punctuation
should be preserved can be specified optionally by $punc.

=head2 uniq

@uniqwords = uniq(@allwords);

Removes duplicate words.  Retains original order of unique words.

=head2 count_hash

%counthash = count_hash(@words);

Computes and returns a hash with $counthash{$w} set to number of
occurrences of element $w in the array @words.

=head2 position_hash

%positionhash = position_hash(@words);

Computes and returns a position table with $positionhash{$w} set to
a reference to an array containing the positional indices of the
occurrences of $w in @words (positions start at 1, not 0)

=head2 extract_text_from_html

$text = extract_text_from_html($html);

Removes comments, scripts, stylesheets and other HTML tags and
returns remainder.

=head2 lc_words

@lcwords = lc_words(@words);

Makes all words in @words lower case.

=head2 base10_to_base36

$res = base10_to_base36($num);

Returns a string representing integer $num in base 36, with
a -> 10, b -> 11, ..., y -> 34, z -> 35.

=head2 compress_docid

$d = compress_docid($docid);

Looks this (ASCII) docid up in the compress-docid database and returns
the compressed form (i.e., the base36 unique form).

Assumes the compress-docid database is in
$TFIDF_DIR/$corpus-compress-docid.dir and
$TFIDF_DIR/$corpus-compress-docid.pag

Quits if it isn't.

Requires environment variable $TFIDF_DIR.

=head2 expand_id

$docid = expand_id($d);

Looks up this compressed docid (i.e., base36 unique form) and returns
its long (ASCII) form.

Assumes the expand-docid database is in
$TFIDF_DIR/$corpus-expand-docid.dir and
$TFIDF_DIR/$corpus-expand-docid.pag

Quits if it isn't.

Requires environment variable $TFIDF_DIR.

=head2 url_to_docid

$docid = url_to_docid($url, $corpus);

Looks this URL up in the url-to-docid database and returns
the associated document ID.

Assumes the url-to-docid database is in
$TFIDF_DIR/$corpus-url-to-docid.dir and
$TFIDF_DIR/$corpus-url-to-docid.pag

Quits if it isn't.

Requires environment variable $TFIDF_DIR.

=head2 docid_to_url

$url = docid_to_url($docid, $corpus);

Looks this doc ID up in the docid-to-url database and returns
the associated URL.

Assumes the docid-to-url database is in
$TFIDF_DIR/$corpus-docid-to-url.dir and
$TFIDF_DIR/$corpus-docid-to-url.pag

Quits if it isn't.

Requires environment variable $TFIDF_DIR.

=head2 document_contains

@urls = document_contains($word, $corpus, $stemmed, $min);

Returns a list of URLs or documents in $corpus that contain $word.
Parameters $word and $corpus are required.

Pass -s to (optional) parameter $stemmed to stem the word before looking
for it, or pass nothing to supress stemming.  (Default is -s.)

Pass $min to (optional) parameter to set the minimum
number or occurrences of the $word that cause the URL to be
returned.  (Default is 1.)

Requires environment variable $TFIDF_DIR.

=head1 METHODS FROM Clair::StringManip

=head2 stem

Takes either the string or the arrayref and stems the tokens (words)
using Lingua::Stem module. Return value can be either string or arrayref
based on the last parameter.

=head2 strip

Strips meta charcters from the string.

=head2 normalize_input

Used for user query string processing. It parses and tokenizes the query 
string into appropriate segments.

=head1 ENVIRONMENT VARIABLES

The variable $TFIDF_DIR must be set prior to execution of
most routines in this module.

Environment variable $TFIDF_DIR should be set to the directory
above the TF is in.  For example, if the TF is in the directory
"/data0/projects/tfidf/corpus-data/kzoo-tf-s", $TFIDF_DIR
should be set to "/data0/projects/tfidf/corpus-data".

=cut

use strict;

use Env;
use Data::Dumper;
use Lingua::Stem;

#
# We now prepend the TFIDF directory to all of the
# "corpus" arguments given us.
#
#my $TFIDF_DIR = $ENV{'TFIDF_DIR'} or die "No TFIDF_DIR!!!";
#

my $TFIDF_DIR;

my @basis = qw(0 1 2 3 4 5 6 7 8 9 a b c d e f g h
	       i j k l m n o p q r s t u v w x y z);


# returns a list of URLS that contain the specified word.
sub document_contains {
    $TFIDF_DIR = $ENV{TFIDF_DIR};
    my $word = shift or die;
    my $corpus = shift or die;
    my $stemmed = shift;
    my $min = shift || 1; # min occurrences.

    $word = lc($word);
    $word =~ s|\'|~|;
    die if $word =~ m|[^a-z\~]|;

    # NEW!
    my $dir = "$TFIDF_DIR/$corpus-tf$stemmed";

    if (length($word) == 1) {
	$dir = "$dir/$word";
    } else {
	my $d1 = substr $word, 0, 1;
	my $d2 = substr $word, 0, 2;
	$dir = "$dir/$d1/$d2";
    }

    my $file = "$dir/$word.tf";

    my @urls = ();

    open TF, $file or return @urls;
    while (<TF>) {
        chop;
        my ($id,$ct) = split (/ /,$_);
        next if $ct < $min;

        my $docid = expand_id($id, $corpus);
	my $url = docid_to_url($docid, $corpus);
	push @urls, $url
    }
    close TF;

    return @urls;
}

#sub get_tf {
#    $TFIDF_DIR = $ENV{TFIDF_DIR};
#    # return the tf for docid/word pair.
#}

my %compress_docid_dbm = ();
my $compress_docid_dbm_name = "";

my %expand_docid_dbm = ();
my $expand_docid_dbm_name;

my %docid_to_url_dbm = ();
my $docid_to_url_dbm_name;

my %url_to_docid_dbm = ();
my $url_to_docid_dbm_name;



sub url_to_docid {
    $TFIDF_DIR = $ENV{TFIDF_DIR};
    my $url = shift;
    my $corpus = shift or die;

    # NEW!
    # $corpus = "$TFIDF_DIR/$corpus";

    print "dbm name is $url_to_docid_dbm_name\n";
    print "corpus name is $corpus\n";

    if ($url_to_docid_dbm_name ne "$corpus-url-to-docid") {
	dbmclose %url_to_docid_dbm if %url_to_docid_dbm;

	$url_to_docid_dbm_name = "$corpus-url-to-docid";
	die unless -s "$url_to_docid_dbm_name.dir";

	dbmopen %url_to_docid_dbm, $url_to_docid_dbm_name, 0444 or die;

	print "explicit call to dbmopen succeeded\n";
    }

    print "url is $url\n";

    foreach my $k (keys %url_to_docid_dbm)
    {
       print "$k $url_to_docid_dbm{$k}\n";
    }

    my $docid = $url_to_docid_dbm{$url};

    die unless defined $docid;

    return $docid;
}

sub docid_to_url {
    $TFIDF_DIR = $ENV{TFIDF_DIR};
    my $docid = shift;
    my $corpus = shift or die;

    # NEW!
    $corpus = "$TFIDF_DIR/$corpus";

    if ($docid_to_url_dbm_name ne "$corpus-docid-to-url") {
        dbmclose %docid_to_url_dbm if %docid_to_url_dbm;

        $docid_to_url_dbm_name = "$corpus-docid-to-url";
        die unless -s "$docid_to_url_dbm_name.dir";

        dbmopen %docid_to_url_dbm, $docid_to_url_dbm_name, 0444 or die;
    }

    my $url = $docid_to_url_dbm{$docid};

    die unless defined $url;

    return $url;
}

# docid's are the things in the actual wtXXg BXXX files:
# WT01-B01-203, for example.
sub compress_docid {

    my $docid = shift;
    my $corpus = shift or die;

    $TFIDF_DIR = $ENV{TFIDF_DIR};

    # NEW!
    $corpus = "$TFIDF_DIR/$corpus";

    if ($compress_docid_dbm_name ne "$corpus-compress-docid") {
	dbmclose %compress_docid_dbm if (%compress_docid_dbm and $compress_docid_dbm_name ne "");

	$compress_docid_dbm_name = "$corpus-compress-docid";
	# print "##$compress_docid_dbm_name\n";

	print "yes\n" if -s "$compress_docid_dbm_name.dir";

	dbmopen %compress_docid_dbm, $compress_docid_dbm_name, 0444 or
           die "Unable to open $compress_docid_dbm_name\n";
    }

    my $id = $compress_docid_dbm{$docid};

    die "<$id,$docid> not defined" unless defined $id;

    return $id;
}

# id's are the base-36 uniq id's of each docno.
sub expand_id {
    $TFIDF_DIR = $ENV{TFIDF_DIR};
    my $id = shift;
    my $corpus = shift or die;

    # NEW!
    $corpus = "$TFIDF_DIR/$corpus";

    if ($expand_docid_dbm_name ne "$corpus-expand-docid") {
        dbmclose %expand_docid_dbm if %expand_docid_dbm;

        $expand_docid_dbm_name = "$corpus-expand-docid";
        die "Can't find dbm '$expand_docid_dbm_name.dir'" unless -s "$expand_docid_dbm_name.dir";

        dbmopen %expand_docid_dbm, $expand_docid_dbm_name, 0444 or die;
    }

    my $docid = $expand_docid_dbm{$id};

    die unless defined $docid;

    return $docid;
}

sub base10_to_base36 {
    $TFIDF_DIR = $ENV{TFIDF_DIR};
    my $num = shift;

    die unless defined $num;

    if ($num == 0) {
	return "0";
    }

    my $res = "";
    while ($num > 0) {
	my $r = $num % 36; # 0 - 35.
	$res = $basis[$r] . $res;
	$num = ($num - $r) / 36;
    }

    return $res;
}

sub lc_words {
    $TFIDF_DIR = $ENV{TFIDF_DIR};
    my @res = ();
    foreach my $w (@_) {
	push @res, lc($w);
    }
    return @res;
}

# obviously, this is just a temp...
# gibsonb: added include puctuation flag
# split_words( $text, $punc )
sub split_words {
    $TFIDF_DIR = $ENV{TFIDF_DIR};
    my $text = shift;
    my $punc = shift;

    if( $punc ){
      $text =~ s/^M/ /g;
      $text =~ s/(\w)\'(\w)/$1~$2/g;
      $text =~ s/[\\\/]//g;
      $text =~ s/\./ p_period\ /g;
      $text =~ s/\'/ p_apostrophe\ /g;
      $text =~ s/\,/ p_comma\ /g;
      $text =~ s/\?/ p_question\ /g;
      $text =~ s/\!/ p_exclamation\ /g;
      $text =~ s/\;/ p_semicolon\ /g;
      $text =~ s/\:/ p_colon\ /g;
      $text =~ s/\"/ p_dblquote\ /g;
      $text =~ s/\*/ p_star\ /g;
      $text =~ s/\(/ p_Lparen\ /g;
      $text =~ s/\)/ p_Rparen\ /g;
      $text =~ s/\[/ p_Lbracket\ /g;
      $text =~ s/\]/ p_Rbracket\ /g;
      $text =~ s/\{/ p_Lbrace\ /g;
      $text =~ s/\}/ p_Rbrace\ /g;
      $text =~ s/\}/ p_Rbrace\ /g;
      $text =~ s/\|/ p_pipe\ /g;
      $text =~ s/\&/ p_amperand\ /g;
      $text =~ s/\@/ p_at\ /g;
      #$text =~ s/([',.!?;:"\*\(\)\[\]])/\ $1\ /g;
    }else{
      $text =~ s/[^A-Za-z\']/ /g;
      $text =~ s/(\w)\'(\w)/$1~$2/g;
      $text =~ s/\'/ /g;
    }
    my @words = split /\s+/, $text;

    return @words;
}

sub uniq {

    $TFIDF_DIR = $ENV{TFIDF_DIR};
    my @in = sort @_;

    my @out = ();
    my $last = "";
    foreach my $w (@in) {
        next if $w eq $last;
        push @out, $w;
        $last = $w;
    }

    return @out;
}


sub count_hash {

    $TFIDF_DIR = $ENV{TFIDF_DIR};
    my @words = @_;

    my %hash = ();
    foreach my $w (@words) {
        if (exists $hash{$w}) {
            $hash{$w}++;
        } else {
            $hash{$w} = 1;
        }
    }

    return %hash;
}


# Builds a position table from an array of words
sub position_hash {
    $TFIDF_DIR = $ENV{TFIDF_DIR};
    my @words = @_;

    my %hash = ();
    for (my $i = 0; $i < scalar @words; $i++) {
        my $w = $words[$i];
        if (exists $hash{$w}) {
            push @{$hash{$w}}, $i+1;
        } else {
            $hash{$w} = [$i+1];
        }
    }

    return %hash;
}


sub extract_text_from_html {

    $TFIDF_DIR = $ENV{TFIDF_DIR};
    my $html = shift;

    # remove comments, scripts, and stylesheets.
    $html =~ s|<!--.*?-->| |gis;
    $html =~ s|<script.*?>.*?</script>| |gis;
    $html =~ s|<style.*?>.*?</script>| |gis;

    # remove the rest of the tags, leaving everything else behind.
    $html =~ s|<.*?>| |gis;

    return $html;
}

sub stem{

    $TFIDF_DIR = $ENV{TFIDF_DIR};
    my ($items, $return_array) = @_;
    
    # stem the words
    my $stemmer = Lingua::Stem->new(-locale => 'EN-US');
    $stemmer->stem_caching({ -level => 2 });
    my @words;

    if(UNIVERSAL::isa($items, "ARRAY"))
    {
	@words = @$items;
    }
    else
    {
	@words = split_words($items, 0);
    }
    
    my @stemmed = @{$stemmer->stem(@words)};
    undef @words; # conserv mem
    @stemmed = grep { ! /^\s*$/ } @stemmed;

    return ($return_array) ? \@stemmed : join " ", @stemmed;
}

sub strip{
    
    $TFIDF_DIR = $ENV{TFIDF_DIR};
    my ($string) = @_;

    # strip all special chars - anything other than alpha-numeric or spaces
    $string =~ s/[^\w\s]//gs;

    return $string;
}

sub normalize_input{

    $TFIDF_DIR = $ENV{TFIDF_DIR};
    my ($input, $no_stem) = @_;

    my @tokens = $input =~ m/(!{0,1}\w+|!{0,1}"[\w\s]+")/gs;
    $_ =~ s/["']//g for @tokens;
    $_ =~ s/^\s*|\s*$//g for @tokens;

    # parse the query and then stem
    unless($no_stem)
    {
        my @prepend = ();
        my @tokens_no_neg = ();
        for my $t (@tokens)
        {
    	    my $first = substr $t, 0, 1;
	    my $rest = substr $t, 1;
	    # my $prepend = ($first eq '!') ? '!' : '';
	    push @prepend, ($first eq '!') ? '!' : '';
	    push @tokens_no_neg, ($first eq '!') ? $rest : $t;
        }
        @tokens_no_neg = @{ stem(\@tokens_no_neg, 1) };

        for my $i (0..$#tokens_no_neg)
        {
	    $tokens[$i] = $prepend[$i] . $tokens_no_neg[$i];
        }
       # $self->debugmsg("normalized query input after stemming:", 1);
       # $self->debugmsg(\@tokens, 1);
    }

    return \@tokens;
}


1;
