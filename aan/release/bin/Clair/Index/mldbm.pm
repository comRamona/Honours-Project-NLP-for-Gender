package mldbm;

=head1 NAME

B<package> mldbm
A submodule that gets dynamically loaded by Index.pm.

=head1 AUTHOR

jbkim
jbremnant@gmail.com
20070408

=head1 SYNOPSIS

Uses MLDBM to store multi-level and other complex data structures into 
a dbm file. The common methods are:

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
use File::Path;


=head2 index_write

 A submodule specific index writing. In this submodule, we break up the 
 inverted index alphabetically. The indexes that were built were stored
 in memory within the Clair::Index object. We pass the reference to that
 instantiated object so we can process the data stored therein.

=cut

sub index_write
{
	my ($self, $index) = @_;

  # we split up the dbmfiles per alphabet
  my %split;
  for my $token (keys %{$index->{inverted_index}})
  {
    my $firstchar = substr $token, 0, 1;
    $split{$firstchar}{$token} = $index->{inverted_index}->{$token};
  }

  # take what's in memory and sync to disk, but per alphabet
  for my $alphabet (keys %split)
  {
    $self->_mldbm_write($split{$alphabet}, "${alphabet}_index", $index);
    delete $split{$alphabet}; # we do some cleaning
  }

  # $self->_mldbm_write($index->{word_index}, "word" . $index->{index_name_append}, $index);
  $self->_mldbm_write($index->{document_index}, "document_index", $index);
  $self->_mldbm_write($index->{document_meta_index}, "document_meta_index", $index);
}


=head2 index_read

 Read the index for the token we are interested in.

=cut

sub index_read
{
	my ($self, $token, $is_meta, $caller) = @_;

	my $first_char = substr $token, 0, 1;
	# if we have a meta, we take the name as is, if not, we modify it
	my $filename = ($is_meta) ? $token : $first_char . "_index";
	
	return $self->_mldbm_read($filename, $caller);
}


=head2 _mldbm_write

 The $filename input parameter can be a full path to a file or a name 
 of the file you want created under $caller->{index_root} in the caller
 object (Index.pm).

 A tied hash is overwritten with the hash content provided, effectively
 causing MLDBM to write into the file that the tied hash is tied to.

=cut


sub _mldbm_write
{
	my ($self, $hash, $filename, $caller) = @_;

	mkpath($caller->{index_root}, 0, 0777) unless(-d $caller->{index_root});
	$filename = "$caller->{index_root}/$filename.dbm" unless(-f $filename);

	$caller->errmsg("provide the hash to save into dbm", 1) unless($hash);

	unlink $filename if(-f $filename);

	my %h;
	tie %h, "MLDBM", $filename, O_RDWR|O_CREAT, 0666
        or $caller->errmsg("cannot open file '$filename': $!", 1);

	(tied %h)->DumpMeth('portable'); 

	$caller->debugmsg("writing mldbm hash into: $filename", 1);

	# hot dang. this is called major flush.
	%h = %{ $hash };
	
	untie %h;
}


=head2 _mldbm_read

 Reads from the MLDBM index file created and returns the reference to 
 the tied hash.

=cut

sub _mldbm_read
{
	my ($self, $filename, $caller) = @_;

	$filename = "$caller->{index_root}/$filename.dbm" unless(-f $filename);

	return {} unless(-f $filename);

	$caller->debugmsg("reading mldbm hash from: $filename", 1);
	my %h;
	tie %h, "MLDBM", $filename, O_RDWR, 0666
        or $caller->errmsg("cannot open file '$filename' for read: $!", 1);
	
	return \%h;
}



1;
