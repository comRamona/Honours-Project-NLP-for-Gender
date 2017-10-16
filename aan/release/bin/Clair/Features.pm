package Clair::Features;

=head1 NAME

 B<package> Clair::Features
 Carry out feature selection using Chi-squared algorithm with Clair::GenericDoc.pm
 objects as input.

=head1 AUTHOR

 JB Kim
 jbremnant@gmail.com
 20070407

=head1 SYNOPSIS

 We want to receive a collection of Clair::GenericDoc objects and convert the parsed
 and stemmed words as feature vectors. In addition, it should carry out feature
 selection using Chi-squared algorithm.

  use Clair::Features;

  my $fea = new Clair::Features(DEBUG => $DEBUG);

  my $gdoc = new Clair::GenericDoc( DEBUG => $DEBUG, content => "/some/doc");

  $fea->register($gdoc);
  
  ... insert more ...

  $fea->select();


=head1 DESCRIPTION

 This module should also provide the ability to output a feature_file containing
 the chi-square scores of all the words. One caveat about generating feature list
 with their associated weights is that unique id's need to be constructed for each
 feature. Afterwards, these id's need to be retained across both the training data
 and the test data. In other words, the test data should refer to the same feature
 as the training set when processing the generated feature id's.

=cut


# use FindBin;
# use lib "$FindBin::Bin/../lib/perl5/site_perl/5.8.5";
# use lib "$FindBin::Bin/lib/perl5/site_perl/5.8.5";

use strict;
use vars qw/$DEBUG/;

use Clair::Debug;
use Clair::GenericDoc;
use Data::Dumper;
use File::Path;


=head2 new

 The constructor. Initializes several container hashes for later use. 
 In case of $self->{mode} eq "test", it will attempt to read in the 
 features file and create a mapping between the feature id and the 
 actual word associated with it.

=cut

sub new
{
	my ($proto, %args) = @_;
	my $class = ref $proto || $proto;

	my $self = bless {}, $class;
	$DEBUG = $args{DEBUG} || $ENV{MYDEBUG};
	
	# necessary data struct
	$self->{features_global} = {};

	# to keep our scores
	$self->{feature_scores} = {};

	# for later lookup
	$self->{features_file} = ".features_lookup";
	$self->{features_map} = {};

	# class counter
	$self->{class_count} = {};

	# document counter : default (0) is unlimited
	$self->{document_limit} = 0;

	# defaults to train mode
	$self->{mode} = "train";

	# overrides
	while ( my($k, $v) = each %args )
	{
		$self->{$k} = $v if(defined $v);
	}

	# we only support two modes
	if($self->{mode} !~ /train|test/)
	{
		$self->errmsg("choose from one of the following modes: 'train' or 'test' (eg: mode => 'train')", 1);
	}

	if($self->{mode} eq "test") 
	{
		unless(scalar keys %{ $self->{features_map} })
		{
			if(-f $self->{features_file})
			{
				$self->debugmsg("initializing the features map for mode: $self->{mode}", 1);
				open M, $self->{features_file} or $self->errmsg("cannot open '$self->{features_file}: $!", 1);	
				my @tmp = <M>;
				close M;
				chomp @tmp;
		
				my $i = 1;
				$self->{features_map} = { map { $_ => $i++ } @tmp };
			}
			else
			{
				$self->errmsg("for the 'test' mode, you need a prior mapping of features to id's",1);
			}
		}
	}

  return $self;
}


=head2 register
 
 Takes the instantiated GenericDoc objects and stores the extracted features into
 internal data structures. It ensures that you are passing in the object that is
 blessed with the GenericDoc name. 

 If the $self->{document_limit} variable is set, the subroutine will simply return
 without adding the content to the internal hashes when the document registration
 limit is reached.

=cut

sub register
{
	my ($self, $doc_obj, $n) = @_;

	my $refname = ref $doc_obj;
	unless($refname eq "Clair::GenericDoc")
	{
		$self->errmsg("passed in object is not Clair::GenericDoc: $refname", 1);
	}

	$self->debugmsg("extracting content for Clair::GenericDoc object", 2);
	my $h = $doc_obj->extract()->[0];

	my @words = split /\s+/, $h->{parsed_content};
	my %features = ();
  map { $features{$_}++ } @words;

	my $group = $h->{GROUP};
	my $source = $h->{content_source};

	# skip if we are over the limit - inefficient since we have to parse the data anyway
	# to determine which group the document belongs to. Oh wells...
	return if($self->{document_limit} && $self->{class_count}->{$group} >= $self->{document_limit});

	# features_global => {
	#   group1 => {
	#     doc1 => {
	#       feature1 => 3, # count of occurence
	#       feature2 => 5,
	#       ...
	#     },
	#     doc2 => {
	#       feature2 => 8,
	#       feature9 => 3,
	#       ...
	#     },
	#   group2 => {
	#     doc1 => {
	#       feature1 => 3, # count of occurence
	#       feature2 => 5,
	#       ...
	#     },
	#   },
	#
	for (keys %features)
	{
		$self->{features_global}->{$group}->{$source} = \%features;
	}	

	$self->debugmsg("extracted features [$source]:\n" .
			Dumper($self->{features_global}->{$group}->{$source}), 3);
	
	$self->{class_count}->{$group}++;
}


=head2 select

 Takes the internal data structures and then extracts desired features using 
 default (Chi-squared) feature selection algorithm. 

=cut

sub select
{
	my ($self, $limit, $algo) = @_;

	$algo = "chi_squared" unless($algo);
	
	unless($self->can($algo))
	{
		$self->errmsg("necessary func '$algo()' does not exist in this module", 1);
	}

	$self->{feature_scores} = $self->$algo();	
	my @ordered_features = reverse
			sort { $self->{feature_scores}->{$a} <=> $self->{feature_scores}->{$b}	}
			keys %{$self->{feature_scores}};		

	if($limit)
	{
		splice @ordered_features, $limit;
	}

	# in case of train mode, you will need to save the features.
	$self->save_features(\@ordered_features) if($self->{mode} ne "test");
	return \@ordered_features;
}


=head2 chi_squared

 Implements Chi-squared feature selection algorithm. Here are the definitions
 for the values in the contingency table:

  k00 = number of docs in class 0 not containing term t
  k01 = number of docs in class 0 containing term t
  k10 = number of docs in class 1 not containing term t
  k11 = number of docs in class 1 containing term t

  The contingency table per feature (word).

         I_t
      |  0   1  
    ------------
  C 0 |  k00 k01
    1 |  k10 k11 

 The following routine loops through the nested hashes in $self->{features_global}
 and constructs the variables mentioned above.

=cut

sub chi_squared
{
	my ($self, $limit) = @_;

	unless($self->{features_global})
	{
		$self->errmsg("necessary \$self->{features_global} struct does not exist. Please 'register()' Clair::GenericDoc objects", 1);
	}
	
	my @classes = sort keys %{ $self->{features_global} };

	my %counts = ();
	my %k_val = (); # will contain values of the contingency table for all features

	for my $i (0..$#classes)
	{
		my $class = $classes[$i];

		for my $doc ( keys %{ $self->{features_global}->{$class} } )
		{
			$counts{$i}++;
			$counts{n}++;

			for my $feature ( keys %{ $self->{features_global}->{$class}->{$doc} } )
			{
				$k_val{$feature}{$i}{1}++;
			}
		}
	}

	# backfill the values to make this a complete matrix of contingency tables.
	for my $feature (keys %k_val)
	{
		for my $i (0..$#classes)
		{
			unless(exists $k_val{$feature}{$i})
			{
				$k_val{$feature}{$i}{1} = 0;
				$k_val{$feature}{$i}{0} = $counts{$i};
			}
			$k_val{$feature}{$i}{0} = $counts{$i} - $k_val{$feature}{$i}{1};
		}
		$self->debugmsg("feature: $feature\n" . Dumper($k_val{$feature}), 2);
	}


	my %feature_scores = ();
	for my $feature (keys %k_val)
	{
		my $k_values = $k_val{$feature};
		my $chi_sq_score = $self->_chi_squared_binary($k_values, $counts{n}, $feature);
		$feature_scores{$feature} = $chi_sq_score;
		
		$self->debugmsg("feature $feature has score $chi_sq_score", 1);
	}

	return \%feature_scores;
}


=head2 _chi_squared_binary

 An implementation of Chi-squared computation assuming the binary classification.
 This subroutine is called by chi_squared public subroutine. Another private
 routine of this type can be implemented for multivariate chi-squared feature
 weight calculation.

=cut

sub _chi_squared_binary
{
	my ($self, $k_ref, $n, $feature) = @_;

	unless(UNIVERSAL::isa($k_ref, "HASH"))
	{
		$self->errmsg("the first param has to be a hash ref containing values of the contingency table", 1);
	}

	my %k = %{$k_ref};
	my $numerator = $n * ( $k{1}{1} * $k{0}{0} - $k{1}{0} * $k{0}{1} ) ** 2;
	my $denominator = ($k{1}{1} + $k{1}{0}) * ($k{0}{1} + $k{0}{0}) *
										($k{1}{1} + $k{0}{1}) * ($k{1}{0} + $k{0}{0});

	# this means ($k{1}{0} + $k{0}{0}) == 0. In other words, all documents of both classes have this word. 
	# since such feature is pretty useless in classifying data, we give it a score of 0.
	if($denominator == 0)
	{
		$self->debugmsg("'$feature' has denom = $denominator, ($k{1}{1} + $k{1}{0}) * ($k{0}{1} + $k{0}{0}) * ($k{1}{1} + $k{0}{1}) * ($k{1}{0} + $k{0}{0})", 1);
		return 0;
	}

	my $chi_sq = $numerator / $denominator;

	return sprintf("%.5f", $chi_sq);
}


=head2 save_features

 For training mode, you need to save the features into a file so that the mapping of
 features to numeric ID's can be retained for the test data. This subroutine drops a file
 for later use. Each line number is the id for the feature.

=cut

sub save_features
{
	my ($self, $features, $features_file) = @_;

	unless($features)
	{
		$self->errmsg("requires arrayref of features", 1);
	}
	$features_file = $self->{features_file} unless($features_file);

	open F, "> $features_file" or $self->errmsg("cannot open '$features_file' for writing: $!", 1);
	print F "$_\n" for (@$features);
	close F;

	my $i = 1;
	$self->{features_map} = { map { $_ => $i++ } @$features };

	return $self->{features_map};
}


=head2 output

 This subroutine outputs the necessary feature vectors into specified text files.
 Default method is to use the SVM light format. 

 In case of test dataset, it will use the prior feature name => id mapping from the
 train data to make the feature id's consistent.

=cut

sub output
{
	my ($self, $file, $features_map, $algo) = @_;

	$algo = "_output_svm_light_format" unless($algo);

	unless($self->can($algo))
	{
		$self->errmsg("necessary func '$algo()' does not exist in this module", 1);
	}

	$self->$algo($file, $features_map);	

}


=head2 _output_svm_light_format

 Prints the lines in this format:

  <line> .=. <target> <feature>:<value> <feature>:<value> ... <feature>:<value> # <info>
  <target> .=. +1 | -1 | 0 | <float> 
  <feature> .=. <integer> | "qid"
  <value> .=. <float>
  <info> .=. <string> 

  e.g: -1 1:0.43 3:0.12 9284:0.2 # abcdef 

=cut

sub _output_svm_light_format
{
	my ($self, $file, $features_map) = @_;

	# print "entering output with $file\n";
	$features_map = $self->{features_map} unless($features_map);
	$file = "output.$self->{mode}" unless($file);
	# my @feature_ordered_by_id = sort { $self->{features_map}->{$a} <=> $self->{features_map}->{$b} } keys %{$self->{features_map}};

	# print Dumper($features_map);
	my @targets = ("-1", "+1");
	my @classes = sort keys %{ $self->{features_global} };
	
	open OUTF, "> $file" or $self->errmsg("cannot open '$file: $!", 1);

	for my $i (0..$#classes)
  {
		my $target = $targets[$i];
		my $class = $classes[$i];

		for my $doc  (keys %{$self->{features_global}->{$class}})
		{
			my @existing = grep { exists $self->{features_map}->{$_} } keys %{ $self->{features_global}->{$class}->{$doc} };
			my @features = sort { $self->{features_map}->{$a} <=> $self->{features_map}->{$b} } @existing;
			
			next unless(scalar @features);

			# print Dumper(\@features);
			my @items = ();
			for my $f (@features)
			{
				my $f_id = $self->{features_map}->{$f};
				my $f_score = $self->{feature_scores}->{$f};
				push @items, "$f_id:$f_score";
			}
			my $feature_val_str = join ' ', @items;

			my $line = "$target $feature_val_str # [$class] $doc\n";
			# my $line = "$target $feature_val_str\n";
			# print $line;
			print OUTF $line;
		}

	}
	close OUTF;
}


=head2 input

 Reads in the document feature vector file generated

=cut

sub input
{
	my ($self, $file, $algo) = @_;

	$algo = "_input_svm_light_format" unless($algo);

	unless($self->can($algo))
	{
		$self->errmsg("necessary func '$algo()' does not exist in this module", 1);
	}

	$self->$algo($file);	
}


=head2 _input_svm_light_format

 The exact opposite of output method. It reads in the svm_light data and constructs
 a perl data structure.

=cut

sub _input_svm_light_format
{
	my ($self, $file) = @_;

	open INF, "< $file" or $self->errmsg("cannot open '$file: $!", 1);
	my @vectors = <INF>;
	close INF;

	chomp @vectors;

	my @data = ();
	for my $v (@vectors)
	{
		if($v =~ /^([^#]+)\s*(#{0,1}.*)$/)
		{
			my ($dataline, $comment) = ($1, $2);
			my ($class_id, @feature_value) = split /\s+/, $dataline;

			my %hash;
			for my $fv (@feature_value) 
			{
				my ($feature_id, $score) = split ":", $fv;
				$hash{$feature_id} = $score;	
			}

			push @data, { class => $class_id, comment => $comment, features => \%hash };
		}
	}

	$self->debugmsg(\@data, 1);

	return \@data;
}


1;
