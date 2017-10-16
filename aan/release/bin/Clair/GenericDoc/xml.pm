package xml;

=head1 NAME

B<package> xml - a submodule that parses xml and converts it into a hash

=head1 AUTHOR

JB Kim
L<jbremnant@gmail.com>
20070407

=head1 SYNOPSIS

This sub-module is a very rudimentary wrapper for XML::Simple module. 
The extract function just reads in XML file and then returns a hash
reference, pushed into the array.


=head1 DESCRIPTION

Simple wrapper to import XML files into GenericDoc.pm module.

=cut


use strict;
use XML::Simple;
use Data::Dumper;

=head2 extract
 
At the core, it runs $xs->XMLin($xml);
 
=cut


sub extract
{
	my ($self, $content, $content_source, $args, $caller) = @_;

	my @return = ();

	require XML::Simple;
	my $xs = new XML::Simple( );

	my $ref = eval { $xs->XMLin($content, ContentKey => "parsed_content", ForceContent => 1, NoAttr => 1); };
	
	return [ { error => $@, content_source => $content_source } ] if($@);
	
	$ref->{content_source} = $content_source;

	push @return, $ref;

	return \@return;
}


1;
