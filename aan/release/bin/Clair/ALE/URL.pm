use strict;

package Clair::ALE::URL;

=head1 NAME

Clair::ALE::URL - A URL created by the Automatic Link Extrapolator

=head1 SYNOPSIS

This object simply contains a URL and an ID for a single URL.

=head1 DESCRIPTION

=head2 CONSTRUCTOR

=over 4

=item new(url => 'url', id => 'id')

Create a new URL with the given URL and ID.  Both of these options are
required, and no others are currently recognized.

=back

=head2 METHODS

=over 4

=item $url->print([indent_spaces])

Print a brief, human-readable description of a URL.  If the
indent_spaces parameter is provided, everything will be indented by
indent_spaces characters of I<$Clair::Utils::ALE::INDENTCHAR>; this is useful for
printing easy-to-read nested structures.  No other guarantees about
the format of the output are provided; if you need a specific format,
you should just print things out yourself, or else talk to me about
adding a specialized printing method.

=back

=head2 INSTANCE VARIABLES

=over 4

=item $url->{url}

The absolute URL of this URL.

=item $url->{id}

A short unique identifier for this URL.

=back

=head1 EXAMPLES

Mostly, these are created from L<Clair::ALE::Search|Clair::ALE::Search> and other
modules; there really isn't a good reason to create one yourself, but
if you want to, you can do:

  my $url = Clair::ALE::URL->new(url => 'http://www.test.com/',
                          id => 100);

or get one back from a search:

  my $search = Clair::ALE::Search->new(word => 'penguin');
  my $conn = $search->queryresult;
  my $link = $conn->{link}->[0];
  my $url = $link->{to};

After that, you can get the information from its instance variables:

  print "url=",$url->{url},"; id=",$url->{id},"\n";

or just print out the whole thing:

  $url->print;

=head1 SEE ALSO

L<Clair::Utils::ALE>, L<Clair::ALE::Search>, L<Clair::ALE::Link>, L<Clair::ALE::Conn>.

=cut

use Clair::Utils::ALE;

use Carp;

sub new
{
  my $class = shift;
  my $self = {@_};

  unless ($self->{url} and $self->{id})
  {
    croak "Need a url and an id to create an Clair::ALE::URL!\n";
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
    $indent = " " x $indent_spaces;
  }
  else
  {
    $indent = "";
    $indent_spaces=0;
  }

  print $indent,"(URL)\n";
  print $indent,"url: $self->{url}\n";
  print $indent," id: $self->{id}\n";
}


1;
