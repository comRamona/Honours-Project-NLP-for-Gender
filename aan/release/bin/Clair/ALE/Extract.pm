use strict;
package Clair::ALE::Extract;

=head1 NAME

Clair::ALE::Extract - Extract links and add them to the database

=head1 SYNOPSIS

    my $ex = Clair::ALE::Extractor->new();
    $ex->extract( drop_tables => 1, files => \@files );

=head1 DESCRIPTION

Adds the links of the given list of files to the ALE database. This is a 
Perl module version of the original alext script. This module depends on
modules that use the ALE environment variables, so they must be set before
using this.

=head2 CONSTRUCTOR

=over 4

=item Clair::ALE::Extract->new

	$ex = Clair::ALE::Extract->new( verbose => 1 );

Constructs a new Extract object. Set verbose to 1 to print information to
STDOUT.

=back

=head2 METHODS

=over 4

=item $ex->extract
    
    # Run ALE on a list of files
    $ex->extract( 
        files => \@files, 
        drop_tables => 1 
    );

    # Run ALE on a corpus from CorpusDownload
    $ex->extract(
        rootdir => "/my/path",
        corpusname => "myCorpus"
    );

Extracts the links from the given list of files. 'drop_tables' is an optional
parameter that when set to true will completely reset the current 
ALESPACE tables before adding the links.

Optionally you can specify a CorpusDownload rootdir and corpusname to have
ALE index the files downloaded by CorpusDownload. See L<CorpusDownload>.

=back

=head1 SEE ALSO

L<Clair::Utils::ALE>, L<Clair::ALE::Conn>, L<Clair::ALE::Link>, L<Clair::ALE::URL>.

=head1 AUTHOR

Tony Fader (afader@umich.edu)

=cut


use Clair::Utils::ALE;
use Clair::Utils::ALE qw(%ALE_ENV);
use Clair::ALE::Stemmer qw(ale_stemsome);
use Clair::ALE::Wget qw(alefile2url);
use Clair::ALE::_SQL;
use FileHandle;
use File::Find;
use HTML::LinkExtractor;

sub new {

    my $class = shift;
    my %args = @_;

    my $self = {};
    bless $self,$class;

    $self->{alesql} = Clair::ALE::_SQL->new();
    $self->{get_urlid_cache} = {};
    $self->{link_count} = 0;
    $self->{verbose} = $args{verbose};

    return $self;

}

sub extract {

    
    my $self = shift;

    my %args = @_;
    my $files;

    my $old_space = $ALE_ENV{ALESPACE};
    my $old_cache = $ALE_ENV{ALECACHE};

    if ($args{files}) {
        $files = $args{files};
    } elsif ($args{rootdir} && $args{corpusname}) {
        $ALE_ENV{ALESPACE} = $args{corpusname};
        $ALE_ENV{ALECACHE} = "$args{rootdir}/download/$args{corpusname}";
        my @found;
        find(sub { push @found, $File::Find::name if (-f $_); },
            $ALE_ENV{ALECACHE});
        $files = \@found;
    } else {
        die "Must specify either 'files' or 'rootdir' and 'corpusname'";
    }

    if ($args{drop_tables}) {
        print "Dropping tables\n" if $self->{verbose};
        $self->drop_tables();
    }

    print "Creating tables\n" if $self->{verbose};
    $self->_create_nonexistant_tables();

    my $total_added = 0;
    foreach my $file (@$files) {
        if (-f $file) {

            print "Converting $file to url\n" if $self->{verbose};
            my $url = alefile2url($file);

            unless($url) {
                warn "Couldn't get url for $file";
                next;
            }

            print "Running on $url\n" if $self->{verbose};

            print "Deleting links\n" if $self->{verbose};
            $self->_delete_links($url);

            print "Extracting links\n" if $self->{verbose};
            $self->_extract_links($url, $file);

            print "Updating timestamp\n" if $self->{verbose};
            $self->_set_last_updated($url);

            $total_added++;

        } else {
            warn "Skipping $file, not a file";
        }
    }

    $ALE_ENV{ALESPACE} = $old_space;
    $ALE_ENV{ALECACHE} = $old_cache;

    print "Added $total_added pages\n" if $self->{verbose};

}

sub drop_tables {

    my $self = shift;
    my $alesql = $self->{alesql};
    my ($links_table, $urls_table, $words_table) =
        ($alesql->links_table, $alesql->urls_table, $alesql->words_table);

    my $sql = "DROP TABLE IF EXISTS $links_table, $urls_table, $words_table";
    $alesql->do($sql)
        or $alesql->errdie("Couldn't drop tables $links_table, $urls_table, "
        . "$words_table");

}

sub _create_nonexistant_tables {

    my $self = shift;
    my $alesql = $self->{alesql};
    my ($links_table, $urls_table, $words_table) =
        ($alesql->links_table, $alesql->urls_table, $alesql->words_table);

    my $sql = "CREATE TABLE IF NOT EXISTS $links_table ("
            . "linkid bigint NOT NULL auto_increment, "
            . "link_from int NOT NULL, "
            . "link_to int NOT NULL, "
            . "link_num int NOT NULL, "
            . "link_text char(255) NOT NULL, "
            . "PRIMARY KEY(linkid), "
            . "UNIQUE KEY(link_from,link_num), "
            . "KEY (link_from), "
            . "KEY (link_to) );";
    $alesql->do($sql) or $alesql->errdie("Error creating table $links_table");


    $sql = "CREATE TABLE IF NOT EXISTS $urls_table ( "
         . "urlid int NOT NULL auto_increment, "
         . "url char(255) NOT NULL, "
         . "last_updated DATETIME, "
         . "PRIMARY KEY (urlid), "
         . "UNIQUE KEY (url) "
         . ")";
    $alesql->do($sql) or $alesql->errdie("Error creating table $urls_table");

    $sql = "CREATE TABLE IF NOT EXISTS $words_table ( "
         . "linkid bigint NOT NULL, "
         . "word char(25) NOT NULL, "
         . "KEY (linkid), "
         . "KEY (word) "
         . ")";
    $alesql->do($sql) or $alesql->errdie("Error creating table $words_table");

}

sub _delete_links {

    my $self = shift;
    my $url = shift;
    my $alesql = $self->{alesql};
    my ($links_table, $urls_table, $words_table) =
        ($alesql->links_table, $alesql->urls_table, $alesql->words_table);

    $self->{link_count} = 0;
    my $urlid = $self->_get_urlid($url);
    unless ($urlid) {
        warn "Couldn't get urlid for $url";
        return undef;
    }

    #my $sql = "DELETE $links_table, $words_table FROM $links_table AS links "
    #        . "NATURAL LEFT JOIN $words_table AS words WHERE "
    #        . "links.link_from=" . $alesql->quote($urlid);
    #my $sql = "DELETE $links_table, $words_table FROM $links_table "
    #        . "NATURAL LEFT JOIN $words_table WHERE "
    #        . "test_extract_links.link_from=" . $alesql->quote($urlid);
    my $sql = "DELETE links, words FROM $links_table AS links "
            . "NATURAL LEFT JOIN $words_table AS words WHERE "
            . "links.link_from=" . $alesql->quote($urlid);
    $alesql->do($sql) or $alesql->errdie("Deleting links for URLID $urlid on sql($sql)");

    return 1;

}

sub _get_urlid {

    my $self = shift;
    my $url = shift;

    my $alesql;
    if ($self->{get_urlid_sql}) {
        $alesql = $self->{get_urlid_sql};
    } else {
        $alesql = Clair::ALE::_SQL->new();
    }
    $self->{get_urlid_sql} = $alesql;
    my ($links_table, $urls_table, $words_table) =
        ($alesql->links_table, $alesql->urls_table, $alesql->words_table);

    my %get_urlid_cache = %{$self->{get_urlid_cache}};

    if (length($url) > 255) {
        $url = substr($url, 0, 255);
    }

    # First try to get it from the cache
    if ($get_urlid_cache{$url}) {
        return $get_urlid_cache{$url};
    }

    # Next try to get it from the DB
    my $sql = "SELECT urlid FROM $urls_table WHERE url=" 
            . $alesql->quote($url);
    my $r = $alesql->queryone($sql);
    if ($r && $r->{urlid}) {
        $get_urlid_cache{$url} = $r->{urlid};
        return $r->{urlid};
    }

    # Doesn't yet exist, creating new id
    $sql = "INSERT INTO $urls_table (url) VALUES ("
         . $alesql->quote($url) .")";
    if ($alesql->do($sql) && $alesql->insertid()) {
        return $get_urlid_cache{$url} = $alesql->insertid();
    } 

    return undef;

}

sub _extract_links {

    my $self = shift;
    my ($url, $fn) = @_;

    my $f = FileHandle->new("< $fn");
    unless ($f) {
        warn "Couldn't open $fn: $!";
        return undef;
    }

    my $lx = HTML::LinkExtractor->new(undef, $url);
    $lx->strip(1);
    $lx->parse($f);

    foreach my $link (@{ $lx->links() }) {

        if ($$link{tag} eq 'a') {

            my $type = $self->_encode($$link{tag});
            my $text = $self->_encode($$link{_TEXT});
            my $href = $self->_encode($$link{href});

            $href =~ s/\/index\.html$//;
            $href =~ s/\/$//;
            if ($href =~ /[\x00-\x1f\x7f-\xff]/) {
                warn "Bad link \#$self->{link_count} from page $url";
                next;
            }

            $self->_insert_link($url, $type, $text, $href);
            
        } 
    }

    close($f) or die "Error closing '$fn': $!";
    return 1;

}

sub _set_last_updated {

    my $self = shift;
    my $url = shift;
    my $urlid = $self->_get_urlid($url);
    my $alesql = $self->{alesql};
    my ($links_table, $urls_table, $words_table) =
        ($alesql->links_table, $alesql->urls_table, $alesql->words_table);

    my $sql = "UPDATE $urls_table SET last_updated = NOW() WHERE "
            . "urlid=" . $alesql->quote($urlid);
    $alesql->do($sql) or $alesql->errdie("Error setting last_updated");
    return 1;

}

sub _encode {

    my $self = shift;
    my $str = shift;

    if ($str) {
        $str =~ s/\t/%09/g;
        $str =~ s/\r/%0D/g;
        $str =~ s/\n/%0A/g;
        return $str;
    } else {
        return "";
    }

}

sub _insert_link {
    
    my $self = shift;
    my ($url, $type, $text, $href) = @_;
    my $alesql = $self->{alesql};
    my ($links_table, $urls_table, $words_table) =
        ($alesql->links_table, $alesql->urls_table, $alesql->words_table);

    unless ($url && $href) {
        warn "Link to/from nothing ($url,$type,$text,$href)\n";
        return undef;
    }

    my $urlid = $self->_get_urlid($url) or return undef;
    my $hrefid = $self->_get_urlid($href) or return undef;

    my $list = join(", ", map { $alesql->quote($_) } 
               ($urlid, $hrefid, $self->{link_count}, $text) );
    my $sql = "INSERT INTO $links_table (link_from, link_to, link_num, "
            . "link_text) VALUES ($list)";
    $alesql->do($sql) or $alesql->errdie("Error inserting new link");
    my $linkid = $alesql->insertid() or die "Didn't get a link ID!";

    my @words = grep(/./, ale_stemsome(
        map { lc $_ } split(/[^a-zA-Z]+/, $text)));

    if (@words) {
        $list = join(", ", 
            map { "(".$alesql->quote($linkid).", ".$alesql->quote($_).")" }
            @words);
        $sql = "INSERT INTO $words_table (linkid, word) VALUES $list";
        $alesql->do($sql) or $alesql->errdie("Error inserting new words");
    }

    $self->{link_count}++;

    return 1;

}

1;
