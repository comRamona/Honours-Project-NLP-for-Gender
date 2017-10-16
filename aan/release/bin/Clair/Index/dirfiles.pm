package dirfiles;

=head1 NAME

B<package> dirfiles
Builds the index into the filesystem namespace.

=head1 AUTHOR

JB Kim
L<jbremnant@gmail.com>
20070407

=head1 SYNOPSIS

Uses directories and files to store the positional inverted index.
The two conventional interfaces to the indexed data:

	index_write
	index_read


=head1 DESCRIPTION

Modularization of the index storage and retrieval are done through these 
sub-modules. Reading and writing the index content should be highly
specific for each of these sub-modules.

=cut


use strict;
use MLDBM qw(DB_File Storable);
use Fcntl;
use File::Basename;
use File::Find;
use File::Path;

# globals
my $extension = "tf";
my $extension_document = "df";
my $extension_document_meta = "meta";
my $index_class = "inverted_index";
my $index_class_document = "document_index";
my @files = ();

=head2 index_write

 The $filename input parameter can be a full path to a file or a name 
 of the file you want created under $index->{index_root} in the caller
 object (Index.pm).

 A tied hash is overwritten with the hash content provided, effectively
 causing MLDBM to write into the file that the tied hash is tied to.

=cut


sub index_write
{
	my ($self, $index) = @_;

	$index->errmsg("provide the hash to save as tf_format", 1) unless($index->{inverted_index});
	my $append = $index->{index_name_append};

	# write the meta indexes
	for my $index_name (qw/document_index document_meta_index/)
	{	
		if($self->can("_${index_name}_write"))
		{
			my $func = "_${index_name}_write";
			$self->$func($index_name, $index);
		}
	}

	my $hash = $index->{inverted_index};

	for my $word (keys %$hash)
	{
		my $one = substr $word, 0, 1;
		my $two = substr $word, 0, 2;
		my $dir = "$index->{index_root}/$index_class/$one/$two";
		mkpath($dir, 0, 0777) unless(-d $dir);
	
		my $lines = $self->build_tf_lines($hash->{$word});
		my $tf_file = "$dir/$word.$extension";
		
		open TF, "> $tf_file" or $self->errmsg("cannot open file $tf_file: $!", 1);
		print TF "$_\n" for (@$lines);	
		close TF;
		$index->debugmsg("wrote $tf_file", 2);
	}
}

=head2 build_tf_lines

 Index specific routine

=cut

sub build_tf_lines
{
	my ($self, $hash) = @_;
	
	my @lines;
	# for my $id (sort {$hash->{$a} <=> $hash->{$b}} keys %$hash)
	for my $id (keys %$hash)
	{
		my @pos = keys %{$hash->{$id}};
		next unless(scalar @pos);

		@pos = sort { $hash->{$id}->{$a} <=> $hash->{$id}->{$b} } @pos;
		my $positions = join ",", @pos;
		my $line = "$id:$positions";
		push @lines, $line;
	}
	return \@lines;
}


=head2 read_tf_file

 Read the file that's formatted in our format.

=cut

sub read_tf_file
{
	my ($self, $file, $caller) = @_;

	return {} unless(-f $file);

	open F, "< $file" or $caller->errmsg("cannot open $file: $!",1);
	my @a = <F>;
	chomp @a;
	close F;

	my %hash = ();
	for my $line (@a)
	{
		my ($id, $positions) = split /:/, $line;
		my @pos = split /,/, $positions;	
		
		#hash of hash
		$hash{$id} = { map { $_ => 1 } @pos };
	}

	return \%hash;
}



=head2 _document_index_write

 Index specific routine

=cut

sub _document_index_write
{
	my ($self, $name, $index) = @_;

	my $hash = $index->{$name};

 	for my $docid (keys %$hash)
	{
		# print "writing for doc: $docid\n";
		my $one = substr $docid, 0, 1;
		my $two = substr $docid, 0, 2;
		my $dir = "$index->{index_root}/$index_class_document/$one/$two";
		mkpath($dir, 0, 0777) unless(-d $dir);

		my $lines = $self->build_tf_lines($hash->{$docid});
    my $df_file = "$dir/$docid.$extension_document"; # df = doc file

    open DF, "> $df_file" or $self->errmsg("cannot open file $df_file: $!", 1);
    print DF "$_\n" for (@$lines);
    close DF;
    $index->debugmsg("wrote $df_file", 2);
  }
}


=head2 _document_meta_index_write

 Index specific routine

=cut

sub _document_meta_index_write
{
	my ($self, $name, $index) = @_;

	my $hash = $index->{$name};

 	for my $docid (keys %$hash)
	{
		my $one = substr $docid, 0, 1;
		my $two = substr $docid, 0, 2;
		my $dir = "$index->{index_root}/$index_class_document/$one/$two";
		mkpath($dir, 0, 0777) unless(-d $dir);

		my $lines = [ map { "$_ = $hash->{$docid}->{$_}" } keys %{$hash->{$docid}} ];
    my $df_file = "$dir/$docid.$extension_document_meta"; # df = doc file

    open DF, "> $df_file" or $self->errmsg("cannot open file $df_file: $!", 1);
    print DF "$_\n" for (@$lines);
    close DF;
    $index->debugmsg("wrote $df_file", 2);
  }
}

=head2 index_read

 Reads from the MLDBM index file created and returns the reference to 
 the tied hash.

=cut

sub index_read
{
	my ($self, $token, $is_meta, $caller) = @_;


	# the is_meta flag can also serve as a document id.
	if($is_meta) 
	{
		# if the Index.pm is doing incremental update, we don't need to 
		# return the existing document index for dirfiles format...
		return {} if($caller->{is_incremental});

		if($self->can("_${token}_read"))
		{
			my $func = "_${token}_read";
			my $meta_hash = $self->$func($is_meta, $caller);
			return $meta_hash;
		}
		else
		{
			$caller->debugmsg("unknown meta index: $token. Skipping",0);
			return {};
		}
	}
	else
	{
		my $one = substr $token, 0, 1;
		my $two = substr $token, 0, 2;
		my $dir = "$caller->{index_root}/$index_class/$one/$two";
		my $tf_file = "$dir/$token.$extension";
		$caller->debugmsg("indexed file to read: $tf_file",1);

		my $hash = $self->read_tf_file($tf_file, $caller);

		return { $token => $hash };
	}
	
}


=head2 _document_index_read

 Read from the document_index dir files. The first argument, $is_meta, is actually
 treated as a boolean flag in mldbm.pm module. However, in dirfiles.pm (this module),
 it can be treated as the document id with which a particular document entry can 
 be retrieved from the index.

=cut

sub _document_index_read
{
	my ($self, $is_meta, $caller) = @_;

	if(defined $is_meta && $is_meta =~ /^\d+$/)
	{
		my $one = substr $is_meta, 0, 1;
		my $two = substr $is_meta, 0, 2;
		my $dir = "$caller->{index_root}/$index_class_document/$one/$two";
    my $df_file = "$dir/$is_meta.$extension_document"; # df = doc file

		my $hash = $self->read_tf_file($df_file, $caller);
		return { $is_meta => $hash };
	}
	else # loop through everything.
	{
		@files = ();
		find(\&_wanted, ( "$caller->{index_root}/$index_class_document" ));
		@files = grep { /\.$extension_document/ } @files;
		
		my %returnhash = ();
		for my $file (@files)
		{
			my $docid = $file;
			$docid = basename($docid);	
			$docid =~ s/\.$extension_document//;
			$returnhash{$docid} = $self->read_tf_file($file, $caller);
		}

		return \%returnhash;
	}
}

=head2 _document_meta_index_read

 Read the doc meta data from the document_index directory. Pretty much the
 same as above.

=cut

sub _document_meta_index_read
{
	my ($self, $is_meta, $caller) = @_;

	if(defined $is_meta && $is_meta =~ /^\d+$/)
	{
		my $one = substr $is_meta, 0, 1;
		my $two = substr $is_meta, 0, 2;
		my $dir = "$caller->{index_root}/$index_class_document/$one/$two";
    my $df_file = "$dir/$is_meta.$extension_document_meta"; # df = doc file

		my $hash = $self->read_equal_delimited($df_file, $caller);
		return { $is_meta => $hash };
	}
	else # loop through everything.
	{
		@files = ();
		find(\&_wanted, ( "$caller->{index_root}/$index_class_document" ));
		@files = grep { /\.$extension_document_meta/ } @files;
		
		my %returnhash = ();
		for my $file (@files)
		{
			my $docid = $file;
			$docid = basename($docid);	
			$docid =~ s/\.$extension_document_meta//;
			$returnhash{$docid} = $self->read_equal_delimited($file, $caller);
		}

		return \%returnhash;
	}
}

=head2 read_equal_delimited

 A simple helper method to read in a file that contains key = value paired
 lines.

=cut

sub read_equal_delimited
{
	my ($self, $file, $caller) = @_;

	return {} unless(-f $file);

	open F, "< $file" or $caller->errmsg("cannot open file $file: $!", 1);
	my @lines = <F>;
	chomp @lines;
	close F;

	my %hash = ();
	for my $l (@lines)
	{
		my ($key, $value) = split /\s*=\s*/, $l;
		$hash{$key} = $value;
	}	
	return \%hash;
}



sub _wanted
{
  return if( ! -f $File::Find::name );
  push @files, $File::Find::name;
}

1;
