use strict;

package Clair::ALE::Conn;

=head1 NAME

Clair::ALE::Conn - A connection between two pages, consisting of one or more
links, created the the Automatic Link Extrapolator.

=head1 SYNOPSIS

This object contains one or more L<Clair::ALE::Link|Clair::ALE::Link> objects which
lead from one URL to another.

=head1 DESCRIPTION

=head2 CONSTRUCTOR

=over 4

=item new (link1, link2, link3, ..., linkn)

Create a new connection between link1 and linkn, which takes a path
through link2, link3, etc.

=back

=head2 METHODS

=over 4

=item $conn-E<gt>print ([indent_spaces])

Print a brief, human-readable description of a Connection.  If the
indent_spaces parameter is provided, everything will be indented by
indent_spaces characters of I<$Clair::Utils::ALE::INDENTCHAR>; this is useful for
printing easy-to-read nested structures.  No other guarantees about
the format of the output are provided; if you need a specific format,
you should just print things out yourself, or else talk to me about
adding a specialized printing method.

=back

=head2 INSTANCE VARIABLES

=over 4

=item $conn-E<gt>{links}

An array reference to all of the links that make up this connection.

=item $conn->{numlinks}

The number of links in this connection.

=item $conn->lastlink

The number of the last link in this connection.

=back

=head1 EXAMPLES

Mostly, connections will come back from L<Clair::ALE::Search|Clair::ALE::Search> and
other modules; there really isn't a good reason to create one
yourself, but if you want to, you can do:

  my $link1 = Clair::ALE::Link->new(to => Clair::ALE::URL->new(url=>'http://www.test.com/',id=>1),
                             from => Clair::ALE::URL->new(url=>'http://www.test2.com/',id=>2),
                             text = "Link from page1 to page2",
                             id => 101);
  my $link2 = Clair::ALE::Link->new(to => Clair::ALE::URL->new(url=>'http://www.test2.com/',id=>1),
                             from => Clair::ALE::URL->new(url=>'http://www.test3.com/',id=>2),
                             text = "Link from page2 to page3",
                             id => 102);
  my $conn = Clair::ALE::Conn->new($link1,$link2);

or get one back from a search:

  my $search = Clair::ALE::Search->new(word => 'penguin');
  my $conn = $search->queryresult;

.  After that, you can get the information from its instance
variables:

  print $conn->[0]->{from}->{url}," connects to ",
        $conn->[$conn->{lastlink}]->to->{url}," in ",
        $conn->{numlinks}," links.\n";

or just print it:

  $conn->print;

.

=head1 SEE ALSO

L<Clair::ALE>, L<Clair::ALE::Search>, L<Clair::ALE::URL>, L<Clair::ALE::Link>.

=cut


use Clair::Utils::ALE;
use Clair::ALE::Link;
use Clair::ALE::URL;

use Carp;

sub new
{
  my $class = shift;
  my $self = {
	      links => [@_],
	      numlinks => scalar(@_),
	      lastlink => scalar(@_)-1,
	     };
  bless $self,$class;
}

sub print
{
  my $self = shift;
  my($indent_spaces) = @_;
  my $indent;
  if ($indent_spaces)
  {
    $indent = $Clair::Utils::ALE::INDENTCHAR x $Clair::Utils::ALE::INDENTS_PER_LEVEL;
  }
  else
  {
    $indent = "";
    $indent_spaces=0;
  }
  my $hop=1;
  
  print $indent,"(Connection)\n";
  foreach my $l (@{$self->{links}})
  {
    print $indent,"Hop $hop\n";
    $hop++;
    $l->print($indent_spaces + $Clair::Utils::ALE::INDENTS_PER_LEVEL);
  }
}

1;
