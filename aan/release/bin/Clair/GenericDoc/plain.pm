package plain;

=head1 NAME

 B<package> plain 
 A submodule that returns the document as is.

=head1 AUTHOR

 JB Kim
 jbremnant@gmail.com
 20070407

=head1 SYNOPSIS

 For plain text documents, we just return the contents and other metadata
 in the following data structure:

 @return = (
   {
     parsed_content => "actual content string",
     content_source => "path to the file",
     optional_params => "other optional metadata",
   },
   {
     parsed_content => "actual content string2",
     content_source => "path to the file2",
     optional_params => "other optional metadata",
   },
   ...
 );

 Note that you can have multiple documents returned. This is useful when
 you want to sub-divide a single file into multiple documents. Perhaps,
 each paragraph can be a document unit.

=head1 DESCRIPTION

 Simple wrapper to import XML files into GenericDoc.pm module.


=cut


use strict;
use Data::Dumper;


=head2 extract

 Return as is.

=cut

sub extract
{
	my ($self, $content, $content_source, $args, $caller) = @_;

	my @return = ();

	push @return, {
		parsed_content => $content,
		content_source => $content_source,
		path => $content_source,
	};

	return \@return;
}


1;
