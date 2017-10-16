package Clair::Index;

=head1 NAME

B<package> Clair::Index
Creates various indexes from supplied Clair::GenericDoc objects.

=head1 AUTHOR

JB Kim
jbremnant@gmail.com
20070407

=head1 SYNOPSIS

This is the module that builds positional inverted index for documents.
The inverted index uses the terms in the document as the "key" for looking
up documents that contain them. Once the index is built, it can be used for
various IR purposes. To build the index, you require the following calls:

	use Clair::Index;
	
	my $idx = new Clair::Index(DEBUG => $DEBUG, stop_word_list => $stop_word_list);
	
	my $gdoc = new Clair::GenericDoc( DEBUG => $DEBUG, content => "/some/doc");

	$idx->insert($gdoc);
  
	... insert more ...

	$idx->build();

By default, it will choose "mldbm" to store the constructed index hashes. 
if you want to store the index into a different format / layout, you need to
implement a sub-module under B<$self->{rw_modules_root}> (defaults to ./Index),
and then specify B<$self->{index_file_format}>. For example:
 
	my $idx = new Clair::Index(
		DEBUG => $DEBUG,
		stop_word_list => $stop_word_list
		index_file_format => "your_module_name",
	);


=head1 DESCRIPTION

This package also uses runtime loaded sub-modules to implement index writing 
and reading. The index writing should take the perl hash structure and layout
the contents in the file system in module-specific way. Similarly, the index
reading should make it transparent to the API user on how the index content is
read from the filesystem.

See B<./Index/mldbm.pm> for example.

This Index.pm module also supports a list of stop words when constructing the index.
In case the list of file containing stop words is supplied, all the words that
appear in that list will be excluded from the index construction.

The inverted index is created from extracted content from Clair::GenericDoc objects. 
The document_id is assigned with auto-increment counter, and the positions of 
each stemmed word will be registered for each document in the index. Thus, this
module implements the construction of full positional inverted index.

=cut


# use FindBin;
# use lib "$FindBin::Bin/../lib/perl5/site_perl/5.8.5";
# use lib "$FindBin::Bin/lib/perl5/site_perl/5.8.5";

use strict;
use vars qw/$DEBUG/;

use Clair::Config;
use Clair::Debug;
use Clair::GenericDoc;
use Data::Dumper;
use File::Path;

=head2 new

 The constructor understands the following significant hash key-values:

=over 8

=item index_root - creates the index files into this specified directory.

=item stop_word_list - path to a file containing the list of stop words.

=item rw_modules_root - path to where sub-modules are contained.

=item index_file_format - specify the name of the module you want to use for index r/w.

=item stem_docs - causes all Clair::GenericDoc object content to be stemmed.

=back

 Most of the constructor keys specified above has defaults.

=cut

sub new
{
	my ($proto, %args) = @_;
	my $class = ref $proto || $proto;

	my $self = bless {}, $class;
	$DEBUG = $args{DEBUG} || $ENV{MYDEBUG};
	
	$self->{stem_docs} = 1;
	$self->{documents} = [];	
	$self->{last_doc_id_filename} = "last_doc_id";

	# indexes
	$self->{inverted_index} = {};
	# $self->{word_index} = {}; # now deprecated
	$self->{document_index} = {};
	$self->{document_meta_index} = {};

	$self->{index_root} = "$FindBin::Bin/indexed";
	$self->{stop_word_list} = "";

	# path finding a bit more resilient..
	# $self->{rw_modules_root} = (-d "$FindBin::Bin/../Clair/Index") ? "$FindBin::Bin/../Clair/Index" : "$FindBin::Bin/Clair/Index";
	$self->{rw_modules_root} = "$Clair::Config::CLAIRLIB_HOME/lib/Clair/Index";
	$self->{index_file_format} = "mldbm";
	# $self->{index_name_append} = "_idx";
	$self->{loaded_modules} = {};


	# overrides
	while ( my($k, $v) = each %args )
	{
		$self->{$k} = $v if(defined $v);
	}

	# this is requred
	unless(-d $self->{rw_modules_root})
	{
		$self->errmsg("the Index building submodule directory should be properly specified",1);
	}

	if(-f $self->{stop_word_list})
	{
		open W, "< $self->{stop_word_list}" or $self->errmsg("cannot open $self->{stop_word_list}: $!", 1);
		my @lines = <W>;
		close W;
		chomp @lines;
		$self->{stop_word_list} = { map { $_ => 1 } grep { /\w+/ } @lines };
	}

  return $self;
}


=head2 insert
 
 Takes the instantiated Clair::GenericDoc objects and stores them into the internal
 array. It ensures that you are passing in the object that is blessed with the
 Clair::GenericDoc name.

 The internal array of Clair::GenericDoc objects is later used to construct various index
 hashes.

=cut

sub insert
{
	my ($self, $doc_obj) = @_;
	
	my $refname = ref $doc_obj;
	unless($refname eq "Clair::GenericDoc")
	{
		$self->errmsg("passed in object is not Clair::GenericDoc: $refname", 1);
	}

	if($DEBUG)
	{
		my $src = $doc_obj->{content};
		# my $length = length $doc_obj->{content};
		$self->debugmsg("inserting doc '$src'", 1);
	}
	push @{$self->{documents}}, $doc_obj;
}


=head2 build

 This subroutine loops through the B<$self->{documents}> array, and for each
 registered Clair::GenericDoc object, it extracts the content and passes it to 
 a private subroutine called B<$self->_add_to_index()>.

=cut

sub build
{
	my ($self) = @_;

	$self->{current_doc_id} = 1;

	# if we are adding onto the same index, we need the last doc_id.
	my $last_file = "$self->{index_root}/$self->{last_doc_id_filename}";
	if(-f $last_file)
	{
		open LF, "< $last_file" or die $self->errmsg("cannot open $last_file: $!", 1);	
		my @a = <LF>;
		chomp @a;
		close LF;
		$self->{current_doc_id} = shift @a;
		$self->{is_incremental} = ($self->{current_doc_id} > 1) ? 1 : 0;
	}	

	# this is incremental update then
	if($self->{is_incremental})
	{
		$self->debugmsg("loading existing meta indexes for incremental update", 1);
		$self->init(
			# word_index => "word_idx", # now deprecated
			document_index => 1,
			document_meta_index => 1,
		);
	}


	# take the objects registered and then build the index hash
	for my $g (@{$self->{documents}})
	{
		next unless($g);

		$g->{stem} = $self->{stem_docs};
		my $subdocs = $g->extract(undef, { return_array => 1 });
		$self->debugmsg("extracted ". scalar @$subdocs . " subdocs", 2);
		$self->_add_to_index($subdocs);

		# destroy the object to conserve memory.
		undef $g;	
	}
	# return ($self->{inverted_index}, $self->{document_meta_index}, $self->{word_index});
	return ($self->{inverted_index}, $self->{document_meta_index});
}


=head2 _add_to_index

 This subroutine where the actual index construction happens. For each
 subdocument returned by the extract function of Clair::GenericDoc object,
 it takes the contents and builds the internal hash structure. 

 The internal hash structures are:

=over 8

=item inverted_index - our major index that contains positional info on words.

=item document_meta_index - contains meta data for each doc, such as title, etc..

=item document_index - it's a regular index (opposite of inverted)

=item word_index - index containing the word frequency. (probably redundant, and yes it is)

=back

 The document id as well as the token positions are auto-incremented 
 integers.

 This method supports incremetal update to the index. If the 

=cut

sub _add_to_index
{
	my ($self, $subdocs) = @_;

# Inverted Index looks like: 
#
# {
#   word1 => {
#      doc_id1 => {
#         position1 => true, 
#         position2 => true, 
#         position2 => true, 
#      },
#      doc_id2 => {
#         position1 => true, 
#         position2 => true, 
#         position2 => true, 
#      },
#   },
#   word2 => {
#      doc_id1 => {
#         position1 => true, 
#         position2 => true, 
#         position2 => true, 
#      },
#      doc_id2 => ...
#   },
#   ...
# }

	# for each document
	for my $h (@$subdocs)
	{
		my $doc_id = $self->{current_doc_id};
		my $tokens = $h->{parsed_content};	
		my $token_count = scalar @$tokens;	
		$self->debugmsg("processing document id: $doc_id", 1);
		$self->debugmsg("tokens for document $h->{content_source}", 3);
		$self->debugmsg($tokens, 3);

		# document meta index - new documents get a new hash with a new id.
		$self->{document_meta_index}->{$doc_id} = {
			title => $h->{title},
			path => $h->{path},
			filename => $h->{filename},
			stemmed_token_count => $token_count,
		};

		for my $i (0..scalar @$tokens - 1)
		{
			my $token = $tokens->[$i];
			next if(ref $token); # we want scalar!

			# index reduction by taking out words in our stop list
			if(UNIVERSAL::isa($self->{stop_word_list}, "HASH"))
			{
				next if($self->{stop_word_list}->{$token}); 
			}

			if($self->{is_incremental})
			{
				# add onto our index.
				unless(exists $self->{inverted_index}->{$token})
				{
					$self->debugmsg("loading current index chunk for $token for incremental update", 1);
					my $index_chunk = $self->index_read($self->{index_file_format}, $token);
					for my $k (keys %{$index_chunk})
					{	
						# prevent it from being overwritten again
						next if(exists $self->{inverted_index}->{$k});
						$self->{inverted_index}->{$k} = $index_chunk->{$k};
					}
				}	
				else
				{
					$self->debugmsg("index key for $token already loaded", 1);
				}
			}

			$self->{inverted_index}->{$token}->{$doc_id}->{$i} = 1; 
			$self->{document_index}->{$doc_id}->{$token}->{$i} = 1; 
			# $self->{word_index}->{$token}->{count}++; # now deprecated
		}

		$self->{current_doc_id}++;
	}
}


=head2 clean

 Cleans out the index directory specified under B<$self->{index_root}>.

=cut

sub clean
{
	my ($self, $rootdir) = @_;
	$rootdir = $self->{index_root} unless($rootdir);
	return unless(-d $rootdir);
	rmtree($rootdir, 0 ,1);
}

=head2 sync

 Simple wrapper around index_write, which in turn will call submodule 
 implementation of index writing. After the index has been written, it
 will save the current_doc_id in order to support incremental index writing.

=cut

sub sync
{
	my ($self) = @_;

	my $mod = $self->{index_file_format};
	
	unless(scalar keys %{ $self->{inverted_index} })
	{
		$self->errmsg("nothing to sync to disk - no inverted index found", 1);
	}

	$self->index_write($mod);
	
	# save the last doc_id
	my $last_file = $self->{last_doc_id_filename};
	open F, "> $self->{index_root}/$last_file" or $self->errmsg("cannot open: $!",1);
	print F $self->{current_doc_id};
	close F;

	$self->{is_incremental} = 0; # set it back to false since we finished writing index
}


=head2 init

 Initializes a number of indexes by means of sub-module index_read call.
 The specified index file is fetched from disk and mapped into an internal
 hash structure.

 This is how you can take the contents on disk and read them into memory
 to speed up your queries later on.

=cut

sub init
{
	my ($self, %indexlist) = @_;

	# initializing the index specified in the %indexlist hash.
	while ( my ($index_name, $flag) = each %indexlist )
	{
		# skip if we have it already
		next if(exists $self->{$index_name} && scalar keys %{$self->{$index_name}}); 
		$self->{$index_name} = $self->index_read($self->{index_file_format}, $index_name, "all");
	}
	my %returned = map { $_ => $self->{$_} } keys %indexlist;
	return %returned;
}


=head2 index_write

 A wrapper function that loads a submodule at runtime and passes the $self
 object to the underlying submodule routine that implements the actual 
 writing to disk.

=cut

sub index_write
{
	my ($self, $modname) = @_;	

	$modname = $self->{index_file_format} unless($modname);

	my $modobj = $self->_load_rw_module($modname);
	$modobj->index_write($self); # $self contains all the info we need
}


=head2 index_read

 A wrapper function that loads a submodule at runtime and reads 
 the necessary indexed files. The returned value is a hash.
 There is a third parameter that acts as a boolean flag that tells
 the submodules whether you are reading in a meta index or a regular
 inverted index.

=cut

sub index_read
{
	my ($self, $modname, $token, $is_meta) = @_;	

	$modname = $self->{index_file_format} unless($modname);

	my $modobj = $self->_load_rw_module($modname);
	return $modobj->index_read($token, $is_meta, $self);
}


=head2 _load_rw_module

 A privation function that loads the necessary index R/W modules
 at runtime.

=cut

sub _load_rw_module
{
	my ($self, $modname) = @_;

	unless($self->{loaded_modules}->{$modname})
	{
		my $modfile = "$self->{rw_modules_root}/$modname.pm";
		$self->debugmsg("loading $modfile for r/w operation", 1);
		eval { require $modfile; };
		$self->errmsg("failed to load $modfile: $@", 1) if $@;
		$self->{loaded_modules}->{$modname} = $modname;
	}

	return $modname;
}


=head1 TODO

 Write more submodules to output different index file layout.

=cut 


1;
