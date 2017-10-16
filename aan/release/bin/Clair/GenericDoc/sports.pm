package sports;

=head1 NAME

B<package> sports - a specialized module for parsing docs for hw2

=head1 AUTHOR

JB Kim
L<jbremnant@gmail.com>
20070407

=head1 SYNOPSIS

This module uses some regexes to parse, assuming that the documents are 
enclosed with <DOC GROUP="blah">...</DOC> format.


=head1 DESCRIPTION

Hardcoded ugliness to parse the pseudo xml files for hw2.

=cut


use strict;
use XML::Simple;
use Data::Dumper;

=head2 extract
 
At the core, it does:

	$content =~ /<DOC GROUP="([\w\.]+)">(.+)<\/DOC>/gs

Yup, ugly.
 
=cut


sub extract
{
	my ($self, $content, $content_source, $args, $caller) = @_;

	my @return = ();

	if($content =~ /<DOC GROUP="([\w\.]+)">(.+)<\/DOC>/gs)
	{
		push @return, { GROUP => $1, parsed_content => $2, content_source => $content_source };
	}
	else
	{
		return [ { error => "can not parse", content_source => $content_source } ] if($@);

	}

	# $content =~ s/<[@\w\.\s]+>//gis;

	# require XML::Simple;
	# my $xs = new XML::Simple( );

	# my $ref = eval { $xs->XMLin($content, ContentKey => "parsed_content", ForceContent => 1); };
	
	
	# $ref->{content_source} = $content_source;

	# push @return, $ref;

	return \@return;
}


1;
