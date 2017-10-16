package Clair::Utils::ALE;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw( %ALE_ENV );
use strict;

our ($INDENTCHAR, $INDENTS_PER_LEVEL, %ALE_ENV);
%ALE_ENV = %ENV;

$INDENTCHAR = " ";
$INDENTS_PER_LEVEL = 4;
#$ALE_ENV{ALECACHE} = $ENV{ALECACHE} || "/clair4/projects/crawl/var/alecache";
$ALE_ENV{ALECACHE} = $ENV{ALECACHE} || "/data1/clair4/projects/crawl/var/alecache";
$ALE_ENV{ALESPACE} = $ENV{ALESPACE} || "default";
$ALE_ENV{MYSQL_UNIX_PORT} = $ENV{MYSQL_UNIX_PORT};




=head1 NAME

ALE - The Automatic Link Extrapolator

=head1 SYNOPSIS

ALE is a collection of tools and Perl libraries providing easy database access for indexing information about the links in HTML documents and retreiving information from those indices.

The basic process used is to give a series of documents to the ALE indexer, then ask questions with the command-line search tool or the Perl modules.

=head1 DESCRIPTION

To use the ALE classes in your program, you'll need to first tell Perl
where they are, with a line like this:

    use lib '/clair4/projects/crawl/wget/prog/ale';

After that, you can just use them like any other modules.

The only module you should use directly is L<Clair::ALE::Search|Clair::ALE::Search>.
That module will return L<Clair::ALE::Conn|Clair::ALE::Conn> objects, which contain
one or more L<Clair::ALE::Link|Clair::ALE::Link> objects, which contain two
L<Clair::ALE::URL|Clair::ALE::URL> objects.

Internal modules you might be interested in if you are extending ALE
are L<Clair::ALE::Stemmer|Clair::ALE::Stemmer> and L<Clair::ALE::_SQL|Clair::ALE::_SQL>.

The easiest way to begin using ALE is to pull in the environment variables from /clair4/projects/crawl/profile using a Bourne-like shell (sh, ksh, bash, zsh, etc.). You can do that with a command like:

    . /clair4/projects/crawl/profile

That will add the ALE tools to your path, and set other environment variables necessary to use ALE.

=head2 Environment variables

All ALE programs and libraries recognize a few environment variables which tell them where to store and look for their data. These can be set directly in the environment or by importing %ALE::ALE_ENV and setting them there, with the exception of MYSQL_UNIX_PORT.

=over 4

=item C<ALESPACE>

is the subdirectory where all data should be stored, and a prefix for
all directory names. If you are working with data independent of other
projects, you should try to set ALESPACE to something unique, perhaps
starting with your username. It defaults to ``default''.

=item C<ALECACHEBASE>

determines the root of the location where ALE can find the documents
its working with, in wget format. It defaults to F<$ALEBASE/cache>.

In addition, ALE is built on a MySQL backend. Several MySQL
environment variables can further influence ALE's behavior.

=item C<MYSQL_UNIX_PORT> 

gives the path to the UNIX socket where the MySQL database ALE should
use is running on.

=back

=head2 Getting files

C<aleget> is a tool for fetching files to index from the Web. It is a
thin front-end to C<wget>, which instructs wget to stores files in the
place you specified in your L<environment variables|/"Environment
variables">.  It gives some default command-line options to C<wget>,
and you can also use any other switches documented in L<wget>.

=head2 Indexing

C<alext> is the ALE indexer. It takes one or more HTML files to index
on its command line, extracts the links from them, and puts them into
its index.

It expects all files to be in the C<$ALESPACE> subdirectory of the
C<$ALECACHEBASE> directory. If a filename starts with ``./'' it is
assumed to be a relative path and located in the proper directory, and
otherwise it is assumed to be an absolute path which should be located
in the proper directory. If you fetched your files with C<aleget>, you
won't have to worry much about this.

You can use C<alext -z> to ``zap'' the tables in C<$ALESPACE>,
removing all data stored there.

You usually will use alext in conjunction with C<find> and C<xargs>,
to easily pass it a large number of files to index. If you are using
GNU xargs, you can use the C<-P> option to run multiple copies of
C<alext> in parallel. For more information on using these commands, see
L<find> and L<xargs>.

alext recognizes the standard environment variables; for more information, see Environment Variables.

Searching from the command-line

ale is the command-line searching tool. It takes many command-line
parameters; you can get a list of all of them by running C<ale
--help>. Some of the more useful ones are:

=over 4

=item --source_url

Only show links with this source URL. Also --no_source_url.

=item --dest_url

Only show links with this destination URL. Also --no_dest_url.

=item --link_word

Only show links with this word as part of the text that creates the link.

=item --source1_url, --dest2_url, --link3_word, etc.

Requests multi-link paths, with the first link having the specified
source URL, the second link having the specified destination URL, the
third link being created by the specified word, and so forth. These
queries have to look at a lot of links, and so can be much slower than
other queries.

=item --limit

Return at most the given number of results. Defaults to 10; use the
string ``none'' to retreive all links.

=back

ale recognizes the standard L<environment variables|/"Environment variables">.

=head2 Searching from the Perl modules

The Perl modules do the same searches as the command-line tool C<ale>,
but return the data in a native Perl format instead of as text. In
fact, the command-line tool is built on top of the Perl modules.

The Perl modules are well-documented. A good starting place to learn
more about them is L<ALE>.

=head1 EXAMPLES

Here's an example of indexing the links on the CLAIR Web site, and
asking a few questions about the links.

First, we log on to tangra and start up a Bourne-like shell (if you're
using bash, you don't have to do anything special).

Once we're logged on, we set up the ALE environment:

    . /clair4/projects/crawl/profile

and set up an C<ALESPACE> environment variable so we are working in
our own private space

    ALESPACE=gifford_clair
    export ALESPACE

Now let's get the CLAIR Web site:

    aleget -r http://tangra.si.umich.edu/clair/index.html \
      -X /clair/nsir -D tangra.si.umich.edu

(as is generally true when using wget to crawl the Web, some
experimentation will be required to figure out what needs to be
excluded). This downloads about 20MB and takes 2.5 minutes.

With the Web pages in our local cache, we can now build an ALE index on it:

    cd /clair4/projects/crawl/var/alecache/gifford_clair
    find . -type f -print0 | 
      xargs -P 5 -n 20 -0 nofail alext >/tmp/alext.out 2>&1

This takes about 5 minutes.

Now, we can ask questions using the command-line tool:

Search for all links containing the word ``mead'':

    ale --link1_word='mead' --limit=none

Search for all links that contain the word ``Jahna'', display up to 10:

    ale --link1_word='jahna'

Search for all links to www.aclweb.org, display up to 10:

    ale --dest_url 'http://www.aclweb.org'

Display all links from the Projects page:

    ale --source_url http://tangra.si.umich.edu/clair/home/projects.htm \
        --limit=none

=head1 SEE ALSO

You may also want to look at L<ALE>, L<wget>, L<find>, L<xargs>, and
L<mysql>.

=head1 AUTHORS

ALE was written primarily by Scott Gifford, with input and assistance
from Dragomir Radev, Adam Winkel, and other members of the CLAIR group
at the University of Michigan School of Information.

=cut

1;  # End of ALE.pm