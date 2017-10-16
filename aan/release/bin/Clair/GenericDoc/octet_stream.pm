package octet_stream;

=head1 NAME

B<package> octet_stream - a submodule that parses xml and converts it into a hash

=head1 AUTHOR

 JB Kim
 jbremnant@gmail.com
 20070407

=head1 SYNOPSIS

 The MIME type for xml file sometimes comes back with octet_stream. This module
 is essentially the same as xml.pm sub-module.


=head1 DESCRIPTION

 Simple wrapper to import XML files into GenericDoc.pm module.


=cut


use strict;
use XML::Simple;
use Data::Dumper;


=head2 extract

 Return as is.

=cut

sub extract
{
	my ($self, $content, $content_source, $args, $caller) = @_;

	my @return = ();

	# require XML::Simple;
	# my $xs = new XML::Simple;

	# my $ref = $xs->XMLin($content);

	push @return, {
		parsed_content => $content,
		content_source => $content_source,
		path => $content_source
	};

	return \@return;
}


1;
