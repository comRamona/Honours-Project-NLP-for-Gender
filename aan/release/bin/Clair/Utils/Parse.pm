package Clair::Utils::Parse;

use warnings;
use strict;

use Clair::Config;
use Clair::Document;

# Run the Charniak parser on the specified file
sub parse {
	my $filename = shift;

	my %args = @_;

	my $output_file = (defined $args{output_file} ? $args{output_file} : "");
	my $char_path = (defined $args{path} ? $args{path} : $CHARNIAK_PATH);
	my $char_data_path = (defined $args{data_path} ? $args{data_path} : $CHARNIAK_DATA_PATH);
	my $options = (defined $args{options} ? $args{options} : "");

	my $result = `$char_path $options $char_data_path $filename`;

	if ($output_file ne "") {
		open OUT, "> $output_file";
		print OUT $result;
		close OUT;
	}

	return $result;
}

# Convert charniak output to chunklink input
sub forcl {
	my $filename = shift;

	my %args = @_;

	my $chunk_path = (defined $args{path} ? $args{path} : $CHUNKLINK_PATH);
	my $output_file = (defined $args{output_file} ? $args{output_file} : "");

	my $result = "";

	open FILENAME, $filename;
	while (<FILENAME>) {
	    s/\(S1 \(/\( \(/;
	    $result .= $_;
	}
	
	if ($output_file ne "") {
		open OUT, "> $output_file";
		print OUT $result;
		close OUT;
	}

	return $result;
}

# Run chunklink on the specified file
sub chunklink {
	my $filename = shift;

	my %args = @_;

	my $chunk_path = (defined $args{path} ? $args{path} : $CHUNKLINK_PATH);
	my $output_file = (defined $args{output_file} ? $args{output_file} : "");
	my $options = (defined $args{options} ? $args{options} : "");

	my $result = `$chunk_path $options $filename 2> /dev/null`;
	
	if ($output_file ne "") {
		open OUT, "> $output_file";
		print OUT $result;
		close OUT;
	}

	return $result;
}

# Prepare a document for parsing by tagging each sentence and putting it
# on its own line
sub prepare_for_parse {
	my $filename = shift;
	my $outfile = shift;

	my $doc = new Clair::Document(file => $filename, id => 'parse_doc', type => 'text');

	my @sentences = $doc->split_into_sentences();

	open OUT, "> $outfile";

	foreach my $sent (@sentences) {
		print OUT "<s> $sent </s>\n";
	}

	close OUT;
}

=head1 NAME

Parse - A wrapper around two common parsing tools: the Charniak parser and
chunklink tool.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This module wraps two common parsing tools: the Charniak parser and chunklink tool.
It provides a simple interface for using the tools.

=head1 METHODS

=cut

    
=head2 parse

my $parse_output = Clair::Utils::Parse::parse("to_be_parsed.txt", output_file => "output.txt");

The parse method runs a file through the Charniak parser, returning the result
as a string, and optionally saving it to an output file.

=cut



=head2 chunklink

my $chunk_output = Clair::Utils::Parse::chunklink("WSJ_0021.MRG", output_file => "output.txt");

The chunklink method runs a file through the chunklink tool, returning the result
as a string, and optionally saving it to an output file.

=cut



=head2 prepare_for_parse

Clair::Utils::Parse::prepare_for_parse("input.txt", "output.txt");

Prepare for parse creates a file prepared for being run through the Charniak parser.
It splits a file into sentences and places each sentence on its own line, inside
<s></s> tags.

=cut



=head1 AUTHOR

Hodges, Mark << <clair at umich.edu> >>
Radev, Dragomir << <radev at umich.edu> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-clair-document at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=clairlib-dev>.
I will be notified, and then you will automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Stem

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/clairlib-dev>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/clairlib-dev>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=clairlib-dev>

=item * Search CPAN

L<http://search.cpan.org/dist/clairlib-dev>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 The University of Michigan, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
