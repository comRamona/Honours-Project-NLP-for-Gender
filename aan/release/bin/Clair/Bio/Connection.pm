package Clair::Bio::Connection;

use strict;
use SOAP::Lite;
use FindBin;
use Clair::Cluster;
use Clair::Document;
use Clair::Network;

sub new {
    my $class = shift;
    my %given_parameters = @_;

    my %parameters = (
      "proxy" => "http://www.bioinformatics.med.umich.edu/app/mbi/dbquery.php",
      "server" => "db3",
      "database" => "pmcoa",
      "user" => "bionlp",
      "password" => "bionlp04" );
    
    for (keys %given_parameters) {
        $parameters{$_} = $given_parameters{$_};
    }

    my $self = bless \%parameters, $class;

    return $self;

}


sub get_ids {
    my $self = shift;
    my @list = @_;

    my $statement = "SELECT pmcid FROM openaccess_pmcids";
    if (@list) {
        my $lstr = join ",", map { "'$_'" } @list;
        $statement .= " WHERE pmcid in ($lstr)";
    } 

    my @rows = $self->dbquery($statement);

    my @result;
    for (@rows) {
        push @result, $_->[0];
    }

    return @result;
}

sub get_sentences {
    my $self = shift;

    my $id = shift;

    my $statement = "SELECT parno, rsnt, sno, sentence FROM "
                  . "sentence WHERE pmcid = $id ORDER BY sno";
    my @rows = $self->dbquery($statement);
    my @result = ();

    for (@rows) {
        my ($parno, $rsnt, $sno, $text) = @$_;
        my %map = ( parno => $parno, 
                    rsnt => $rsnt, 
                    sno => $sno, 
                    text => $text );
        push @result, \%map;
    }
    return @result;
}

sub get_title {
    my $self = shift;
    my $id = shift;

    my $statement = "SELECT atitle FROM atitle WHERE pmcid=$id";
    my @rows = $self->dbquery($statement);
    return $rows[0]->[0];
}

sub get_body {
    my $self = shift;
    my $id = shift;

    my @sents = $self->get_sentences($id);
    my $result = "";
    for (@sents) {
        $result .= $_->{text};
    }
    return $result;
}

sub get_citing_ids {
    my $self = shift;
    my $cited = shift;

    my $statement = "SELECT citer FROM citations WHERE cited=$cited";
    my @rows = $self->dbquery($statement);
    @rows = map { $_->[0] } @rows;

    return @rows;
}

sub get_cited_ids {
    my $self = shift;
    my $citing  = shift;

    my $statement = "SELECT cited FROM citations WHERE citer=$citing";
    my @rows = $self->dbquery($statement);
    @rows = map { $_->[0] } @rows;

    return @rows;
}

sub _get_citations {
    my $self = shift;

    if ($self->{_forward_graph} && $self->{_backward_graph}) {
        return ($self->{_forward_graph}, $self->{_backward_graph});
    }

    my $statement = "SELECT citer, cited FROM citations";
    my @rows = $self->dbquery($statement);
    my %forward_graph;
    my %backward_graph;

    foreach my $row (@rows) {
        my ($from, $to) = ($row->[0], $row->[1]);
        unless ($forward_graph{$from}) {
            $forward_graph{$from} = {};
        }
        $forward_graph{$from}->{$to} = 1;
        unless ($backward_graph{$to}) {
            $backward_graph{$to} = {};
        }
        $backward_graph{$to}->{$from} = 1;
    }
    
    $self->{_forward_graph} = \%forward_graph;
    $self->{_backward_graph} = \%backward_graph;

    return (\%forward_graph, \%backward_graph);
}


sub get_full_citation_network {
    my $self = shift;
    my ($forward_graph, $backward_graph) = $self->_get_citations();
    return $self->_hashref_to_network($forward_graph);
}

sub get_citation_network {
    my $self = shift;

    my @ids = @_;

    my ($forward_graph, $backward_graph) = $self->_get_citations();

    my $subgraph = {};
    my $visited = {};
    my %to_visit = ();
    map { $to_visit{$_} = 1 } @ids;

    while (keys %to_visit) {
        my ($id, $junk) = each %to_visit;
        delete $to_visit{$id};
        $visited->{$id} = 1;

        unless ($subgraph->{$id}) {
            $subgraph->{$id} = {};
        }

        for (keys %{ $forward_graph->{$id} }) {
            $subgraph->{$id}->{$_} = 1;
            $to_visit{$_} = 1 unless $visited->{$_};
        }

        for (keys %{ $backward_graph->{$id} }) {
            unless ($subgraph->{$_}) {
                $subgraph->{$_} = {};
            }
            $subgraph->{$_}->{$id} = 1;
            $to_visit{$_} = 1 unless $visited->{$_};
        }

    }

    my $n = $self->_hashref_to_network($subgraph);
    return $n;
}

sub _hashref_to_network {
    my $self = shift;
    my $hashref = shift;

    my $n = new Clair::Network();
    foreach my $from (keys %$hashref) {
        $n->add_node($from) unless $n->has_node($from);
        foreach my $to (keys %{ $hashref->{$from} } ) {
            $n->add_node($to) unless $n->has_node($to);
            my $edge = $n->add_edge($from, $to);
            $n->set_edge_attribute($from, $to, 'pagerank_transition', 1);
        }
    }
    return $n;
}



sub get_citing_sentences {
    my $self = shift;

    my $citer = shift;
    my $cited = shift;

    my $statement_xml = "SELECT sentence.parno, sentence.rsnt, sentence.sno, "
                      ."sentence.sentence, citation FROM references_xml, "
                      . "sentence, pmid WHERE citation=sentence AND "
                      . "cited_pmid=pmid AND pmid.pmcid=$cited AND "
                      . "citer_pmcid=$citer AND sentence.pmcid=$citer";

    my $statement_html = "SELECT sentence.parno, sentence.rsnt, sentence.sno, "
                       . "sentence.sentence, citation FROM references_html, "
                       . "sentence WHERE citation=sentence AND "
                       . "cited_pmcid=$cited AND citer_pmcid=$citer AND "
                       . "sentence.pmcid=$citer";

    my @xml_rows = $self->dbquery($statement_xml);
    my @html_rows = $self->dbquery($statement_html);

    my @rows = (@xml_rows, @html_rows);
    my @result;

    for (@rows) {
        push @result, { 
            parno => $_->[0], 
            rsnt => $_->[1], 
            sno => $_->[2], 
            text => $_->[3] 
        };
    }

    return @result;
}

sub count_citations {
    my $self = shift;
    my $statement = "SELECT count(*) FROM citations";
    my @rows = $self->dbquery($statement);
    return $rows[0]->[0];
}

sub get_pagerank {
    my $self = shift;
    my @ids = shift;
    return undef unless @ids;
    my $str = list_to_sql_list(@ids);

    my $statement = "SELECT pmcid, pagerank_score FROM pagerank WHERE pmcid "
                  . "IN $str";
    my @rows = $self->dbquery($statement);
    my %scores;
    foreach my $row (@rows) {
        my ($pmcid, $score) = @$row;
        $scores{$pmcid} = $score;
    }
    return %scores;
}

sub get_abstract_sentences {
    my $self = shift;
    my $id = shift;

    my $statement = "SELECT parid, sentid, sentence FROM abstracts WHERE "
                  . "pmcid=$id ORDER BY parid, sentid";
    my @rows = $self->dbquery($statement);

    my @result;
    for (@rows) {
        push @result, {
            parno => $_->[0],
            sno => $_->[1],
            text => $_->[2]
        };
    }
    return @result;
}

sub get_abstract {
    my $self = shift;
    my $id = shift;
    my @sents = $self->get_abstract_sentences($id);

    my $result = "";
    for (@sents) {
        $result .= $_->{text};
    }

    return $result;
}

sub get_degree_in {
    my $self = shift;
    my $id = shift;
    return $self->get_degree($id, "cited");
}

sub get_degree_out {
    my $self = shift;
    my $id = shift;
    return $self->get_degree($id, "citer");
}


sub dbquery {

    my $self = shift;

    my $statement = shift;
    my $client = SOAP::Lite->new();
    $client->proxy($self->{"proxy"});
    my $som = $client->dbquery(
        $self->{"server"}, 
        $self->{"database"}, 
        $self->{"user"},
        $self->{"password"}, $statement) || die "Query failed $!";

    my $result_chunk = $som->result();

    # A tab and newline separated chunk of text is what we get back. 
    # We want to put it into a nicer format before returning.
    my @lines = split /\n/, $result_chunk;
    my @result;
    foreach my $line (@lines) {
        my @fields = split /\t/, $line;
        push @result, \@fields;
    }

    return @result;

}

sub list_to_sql_list {
    my @list = @_;
    my $joined = join ", ", @list;
    return "($joined)";
}

sub get_degree {
    my $self = shift;
    my $id = shift;
    my $type = shift;
    die "Type must be citer or cited" 
        unless ($type eq "citer" or $type eq "cited");

    my $statement = "SELECT count(*) FROM citations WHERE $type=$id";
    my @rows = $self->dbquery($statement);
    return $rows[0]->[0];
}

=head1 NAME

Clair::Bio::Connection - Connect to the Bio database using SOAP

head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This module connects to the biodb using SOAP. 

    #!/usr/bin/perl -w
    use Bio::Connection;
    my @ids = $c->get_ids();
    my @sents = $c->get_sentences("29019"); # using PMID
    my $title = $c->get_title("29019"); 
    my @citing_sents = $c->get_citing_sentences(1242180, 64497); 

    # Each sentence is a hashref with values parno, rsnt, sno, and text
    foreach my $sent (@citing_sents) {
        print "$sent->{parno}, $sent->{rnsnt}, $sent->{sno}, $sent->{text}\n";
    }

    # Run a manual query
    my @rows = $c->dbquery("...");
    foreach my $row (@rows) {
        foreach my $col (@$row) {
            # each "row" is a reference to a list of column values
        }
    }


=head1 METHODS

=cut

    
=head2 new

Creates a new Connection object. The following parameters can be set: proxy, 
server, database, user, password.

=cut


=head2 get_ids()

Returns a list of the ids of every paper in the database.

=cut

=head2 get_sentences($id)

Returns a list of hash references containing information about each sentence
in the document with PMID $id. Each element in the list is in the
form { parno => ..., rsnt => ..., sno => ..., text => .. }.

=cut

=head2 get_title($id)

Returns the title of the document with PMID $id.

=cut

=head2 get_body($id)

Returns all of the sentences of the document with PMID $id concatenated 
together.

=cut

=head2 get_citing_sentences($citer, $cited)

Returns a list of sentences from the document with PMID $citer that cite
the document with PMID $cited. This list will have the same structure 
as in get_sentences.

=cut

=head2 count_citations()

Returns the total number of citations in the database.

=cut

=head2 get_abstract_sentences($id)

Returns a list of sentences from the abstract of the document with
PMID $id. 

=cut

=head2 get_abstract($id)

Returns all of the sentences from the abstract of the document with PMID $id
concatenated together.

=cut

=head2 get_degree_in($id)

Returns the total number of papers that cite the document with PMID $id.

=cut

=head2 get_degree_out($id)

Returns the total number of papers the document with PMID $id cites.

=head2 get_citation_network(@ids)

Returns a Clair::Network object of ids with an edge between id1 and id2
if id1 cites id2. Generates the network starting from the ids in @ids.

=head2 get_full_citation_network()

Returns a Clair::Network object containing the full citation network.

=cut

=head2 dbquery($statement)

Executes the given statement on the database and returns the results. The 
result is an array of array references. See the synopsis for an example.

=cut

1;
