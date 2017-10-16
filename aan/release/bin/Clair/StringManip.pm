package Clair::StringManip;

=head1 NAME

B<package> Clair::StringManip
Majority of the string manipulation routines required by other packages
are here.
This is mostly a wrapper for Clair::Utils::TFIDFUtils.

=head1 AUTHOR

JB Kim
L<jbremnant@gmail.com>
20070407

=head1 SYNOPSIS

Necessary string manipulations such as stripping of meta characters, and
word stemming is implemented here. You can try putting in arbitrary string
and see how it works by:

	use Clair::StringManip;

	my $strmanip = new Clair::StringManip();
	my $return $strmanip->stem("operational operations operator");
	print $return . "\n";

=head1 DESCRIPTION

Other string-related functions will be implemented here. The subroutines should
be able to handle both SCALAR or ARRAY-ref as input param and return values
should also be arbitrated between SCALAR and ARRAY-ref.

=cut


# use FindBin;
# use lib "$FindBin::Bin/../lib/perl5/site_perl/5.8.5";
# use lib "$FindBin::Bin/perl5/site_perl/5.8.5";

use strict;
use vars qw/$DEBUG/;

use Clair::Debug;
use Data::Dumper;
use Lingua::Stem;
use Clair::Utils::TFIDFUtils qw();


=head2 new

The constructor. As with other modules, make sure you specify the DEBUG flag
for standardized debug printing:

	my $obj = new StringManip(DEBUG => $DEBUG);
 
=cut

sub new
{
	my ($proto, %args) = @_;
	my $class = ref $proto || $proto;

	my $self = bless {}, $class;
	$DEBUG = $args{DEBUG} || $ENV{MYDEBUG};

	$self->{lowercase} = 1;
	$self->{tokenize} = 1;
	$self->{stem} = 1;

	# overrides
	while ( my($k, $v) = each %args )
	{
		$self->{$k} = $v if(defined $v);
	}

  return $self;
}

=head2 lowercase

Lowercases the string.

=cut

sub lowercase
{
	my ($self, $string) = @_;
	
	my @result = Clair::Utils::TFIDFUtils::lc_words($string);
	return $result[0];
}


=head2 stem

Takes either the string or the arrayref and stems the tokens (words)
using Lingua::Stem module. Return value can be either string or arrayref
based on the last parameter.

=cut

sub stem
{
	my ($self, $items, $return_array) = @_;

	return Clair::Utils::TFIDFUtils::stem($items, $return_array);
    
#	# stem the words
#	my $stemmer = Lingua::Stem->new(-locale => 'EN-US');
#	$stemmer->stem_caching({ -level => 2 });
#	my @words;
#
#	if(UNIVERSAL::isa($items, "ARRAY"))
#	{
#		@words = @$items;
#	}
#	else
#	{
#		@words = split /\s+/, $items;
#	}
#    
#	my @stemmed = @{$stemmer->stem(@words)};
#	undef @words; # conserv mem
#	@stemmed = grep { ! /^\s*$/ } @stemmed;
#
#	return ($return_array) ? \@stemmed : join " ", @stemmed;	
}


=head2 tokenize

Tokenizes the words, effectively getting rid of all the extra empty spaces.
return values can be either string or arrayref depending on the last input param.

=cut

sub tokenize
{
	my ($self, $string, $return_array) = @_;

	# tokenize all the words - split by empty spaces
	$string =~ s/\s+/ /gs;
	
	if($return_array)
	{
#		my @tokens = split /\s+/, $string;
#		return \@tokens;
	        my @tokens = Clair::Utils::TFIDFUtils::split_words($string, 0);
	        return \@tokens;
	}
	else
	{
		return $string;
	}
}

=head2 strip

Strips meta charcters from the string.

=cut

sub strip
{
	my ($self, $string) = @_;

	return Clair::Utils::TFIDFUtils::strip($string);

#	# strip all special chars - anything other than alpha-numeric or spaces
#	$string =~ s/[^\w\s]//gs;

#	return $string;
}


=head2 normalize_input

Used for user query string processing. It parses and tokenizes the query 
string into appropriate segments.

=cut

sub normalize_input
{
	my ($self, $input, $no_stem) = @_;
	my $result = Clair::Utils::TFIDFUtils::normalize_input($input, $no_stem);
	
	unless($no_stem)
	{
	    $self->debugmsg("normalized query input after stemming:", 1);
	    $self->debugmsg($result, 1);
	}

	return $result;

#	my @tokens = $input =~ m/(!{0,1}\w+|!{0,1}"[\w\s]+")/gs;
#	$_ =~ s/["']//g for @tokens;
#	$_ =~ s/^\s*|\s*$//g for @tokens;
#
#	# parse the query and then stem
#	unless($no_stem)
#	{
#		my @prepend = ();
#		my @tokens_no_neg = ();
#		for my $t (@tokens)
#		{
#			my $first = substr $t, 0, 1;
#			my $rest = substr $t, 1;
#			# my $prepend = ($first eq '!') ? '!' : '';
#			push @prepend, ($first eq '!') ? '!' : '';
#			push @tokens_no_neg, ($first eq '!') ? $rest : $t;
#		}
#		@tokens_no_neg = @{ $self->stem(\@tokens_no_neg, 1) };	
#
#		for my $i (0..$#tokens_no_neg)
#		{
#			$tokens[$i] = $prepend[$i] . $tokens_no_neg[$i];
#		}
#		$self->debugmsg("normalized query input after stemming:", 1);
#		$self->debugmsg(\@tokens, 1);
#	}

}

=head1 TODOS

=over

=item Migrate the input normalizing function from Info::Query into this module.

=back

=cut

1;
