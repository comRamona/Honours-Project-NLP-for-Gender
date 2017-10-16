package html;

=head1 NAME

B<package> html - a submodule that strips out html tags.

=head1 AUTHOR

 JB Kim
 jbremnant@gmail.com
 20070407

=head1 SYNOPSIS

 While html tags can be easily stripped out by proper use regexes, the
 parsing is made more extensible by the use of HTML::Parser module.

 Contents within unwanted tags can be ignored.

=head1 DESCRIPTION

 The module HTML::Parser is fairly robust. When utilized correctly, this
 html parser sub-module should be able to break the html content into
 multiple sub-sections.

=cut


use strict;
use HTML::Parser;
use Data::Dumper;
use File::Basename;

my %inside;
my %data = ();


=head2 extract

 This subroutine is invoked externally from the caller (parent) object that
 dynamically loads this sub-module. It takes care of stripping out html tags
 and returning the array of hash values containing parsed_content and other
 meta data.

=cut

sub extract
{
	my ($self, $content, $content_source, $args, $caller) = @_;

	my @return = ();

	# start fresh
	delete $data{parsed_content} if(exists $data{parsed_content});

	# my $p = new HTML::Parser(api_version => 3);
	# $p->parse($content);
	my $p = HTML::Parser->new(api_version => 3,
		  handlers    => {
					start => [\&tag, "tagname, '+1'"],
				  end   => [\&tag, "tagname, '-1'"],
				  text  => [\&text, "dtext"],
				 },
		  marked_sections => 1,
	);
	my $str = $p->parse($content) || die "[html.pm] cannot parse content: $!\n";

	# print "PRINTING: $content, $content_source\n" . Dumper($self);
	# $data{parsed_content}
  my $basename = basename($content_source);
  $basename =~ s/\.\w+$//;

  $data{parsed_content} =~ s/^\s+|\s+$//gs;
  $data{filename} = $args->{doc_id} || $basename;
  $data{content_source} = $content_source;
  $data{path} = $content_source;

	push @return, \%data;

	return \@return;
}


=head2 tag
 
 Private subroutine to indicate the entry and the exit point of html tags.

=cut

sub tag
{
   my($tag, $num) = @_;
   $inside{$tag} += $num;
   $data{parsed_content} .= " ";  # not for all tags
}

=head2 text

 Private subroutine to extract necessary info from html content.

=cut

sub text
{
		my($text) = @_;
    return if $inside{script} || $inside{style};
		if($inside{title})
		{
			$text =~ s/\s+$//s;
			$data{title} = $text 
		}
    $data{parsed_content} .= $text;
}


1;
