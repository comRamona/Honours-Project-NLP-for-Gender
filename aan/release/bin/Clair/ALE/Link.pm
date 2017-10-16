use strict;

package Clair::ALE::Link;

=head1 NAME

Clair::ALE::Link - A link between two URLs created by the Automatic Link Extrapolator.

=head1 SYNOPSIS

This object contains two URLs comprising a link between two pages, the
source page ("from") and the destination page ("to").

=head1 DESCRIPTION

=head2 CONSTRUCTOR

=over 4

=item new

(to =E<gt> Clair::ALE::URL, from =E<gt> Clair::ALE::URL, text =E<gt> 'words which create link', id =E<gt> 'link_id')

Creates a new Clair::ALE::Link object with an L<Clair::ALE::URL|Clair::ALE::URL> for the
'to' and 'from' of the link, the words that create the link (in an
HTML Web page, the part between the E<lt>aE<gt> and E<lt>/aE<gt> tags
as 'text', and a short unique identifier in 'id'.  All of these
parameters are required, and no others are recognized.

=back

=head2 METHODS

=over 4

=item $url-E<gt>print ([indent_spaces])

Print a brief, human-readable description of a Link.  If the
indent_spaces parameter is provided, everything will be indented by
indent_spaces characters of I<$Clair::Utils::ALE::INDENTCHAR>; this is useful for
printing easy-to-read nested structures.  No other guarantees about
the format of the output are provided; if you need a specific format,
you should just print things out yourself, or else talk to me about
adding a specialized printing method.

=back


=head2 INSTANCE VARIABLES

=over 4

=item $link->{from}

An L<Clair::ALE::URL|Clair::ALE::URL> object containing the address the link is
"from" (the "source" page).

=item $link->{to}

An L<Clair::ALE::URL|Clair::ALE::URL> object containing the address the link is "to"
(the "destination" page).

=item $link->{text}

A string containing the words which link the two pages.  For an HTML
Web page, this would be the part between the E<lt>aE<gt> and
E<lt>/aE<gt> tags.

=item $link->{id}

A short, unique identifier for this link.

=back


=head1 EXAMPLES

Mostly, links will come back from L<Clair::ALE::Search|Clair::ALE::Search> and other
modules; there really isn't a good reason to create one yourself, but
if you want to, you can do:

  my $link = Clair::ALE::Link->new(to => Clair::ALE::URL->new(url=>'http://www.test.com/',id=>1),
                            from => Clair::ALE::URL->new(url=>'http://www2.test.com/',id=>2),
                            text => "Link from page1 to page2",
                            id => 101);

or get one back from a search:

  my $search = Clair::ALE::Search->new(word => 'penguin');
  my $conn = $search->queryresult;
  my $link = $conn->{link}[0];

.  After that, you can get the information from its instance
variables:

  print $link->{from}->{url}," connects to ",$link->{to}->{url}," via words ",
        $link->{text},"\n";

or just print out the whole thing:

  $link->print;

=head1 SEE ALSO

L<Clair::Utils::ALE>, L<Clair::ALE::Search>, L<Clair::ALE::URL>, L<Clair::ALE::Conn>.

=cut


use Clair::Utils::ALE;
use Clair::ALE::_SQL;
use Clair::ALE::URL;

use Carp;

sub new
{
  my $class = shift;
  my $self = {@_};

  unless ($self->{to} && $self->{from} && $self->{text} && $self->{id})
  {
    croak "Need to, from, text, id to create Clair::ALE::Link!";
  }
  bless $self,$class;
}

sub print
{
  my $self = shift;
  
  my($indent_spaces) = @_;
  my $indent;
  if ($indent_spaces)
  {
    $indent = $Clair::Utils::ALE::INDENTCHAR x $indent_spaces;
  }
  else
  {
    $indent = "";
    $indent_spaces = 0;
  }
  print $indent,"(Link)\n";
  print $indent,"From:\n";
  $self->{from}->print($indent_spaces+$Clair::Utils::ALE::INDENTS_PER_LEVEL);
  print $indent,"To:\n";
  $self->{to}->print($indent_spaces+$Clair::Utils::ALE::INDENTS_PER_LEVEL);
  print $indent,"Link ID: ",$self->{id},"\n";
  print $indent,"Link Text: ",$self->{text},"\n";
}
  
  1;
