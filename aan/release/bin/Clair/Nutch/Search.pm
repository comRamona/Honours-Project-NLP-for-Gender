package Clair::Nutch::Search;

use strict;

use Clair::Cluster;
use Clair::Document;

my $SEARCH_CLASS = "edu.umich.si.clair.nutch.SimpleSearch";

sub new {

    my $class = shift;
    my %params = @_;

    die "'nutch_home' is a required field" 
        unless (defined $params{nutch_home});

    die "'index_path' is a required field"
        unless (defined $params{index_path});

    my $self = bless \%params, $class;

    return $self;

}

sub query {
    my $self = shift;

    my $query = shift;
    my $hits = shift;
    
    unless ($hits) {
        $hits = 10;
    }

    my $script = "$self->{nutch_home}/bin/nutch";
    my $command = "$script $SEARCH_CLASS $self->{index_path} '$query' $hits";

    unless (defined $self->{verbose}) {
        $command .= " 2>/dev/null";
    }

    my @lines = `$command`;
    my @result;
    foreach my $line (@lines) {
        my @pairs = split /\t/, $line;
        my %hit = @pairs;
        for (keys %hit) {
            if ($_ =~ /^\s*$/) {
                delete $hit{$_};
            }
        }
        push @result, \%hit;
    }
    return @result;

}

sub query_cluster {
    my $self = shift;
    my $query = shift;
    my $hits = shift;

    my @hits = $self->query($query, $hits);
    my $cluster = Clair::Cluster->new();
    my $i = 1;

    my $clean_query = $query;
    $clean_query =~ s/\s/_/;
    foreach my $hit (@hits) {
        if (defined $hit->{content}) {
            my $text = $hit->{content};
            my $id = "$clean_query$i";
            my $doc = new Clair::Document(
                string => $text,
                type => "text",
                id => $id
            );
            $cluster->insert($id, $doc);
        }
        $i++;
    }

    return $cluster;
}

=head1 NAME

Clair::Nutch::Search - A class for performing simple Nutch searches.

=cut

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

    #!/usr/bin/perl -w
    use strict;
    use Clair::Nutch::Search;
    my $search = Clair::Nutch::Search->new(
        nutch_home => "/path/to/nutch",
        index_path => "/path/to/index"
    );
    # Returns a list of hits, where each hit is a hashref
    my @results = $search->query("cat rabies", 20);
    foreach my $hit (@results) {
        foreach my $key (%$hit) {
            print "$key => $hit->{$key}\n";
        }
    }

=cut

=head1 METHODS

=cut

=head2 new

Takes two required parameters: "nutch_home" (the path to nutch) and 
"index_path" (the path to a Nutch index directory [it will contain db and 
segments]).

=cut

=head2 query

    $search->query($query, $numhits)
Queries Nutch with the given query (required) and returns at most $numhits
(optional, defaults to 10).

=cut

=head2 query_cluster

    $search->query($query, $numhits)
Queries Nutch with the given query (required) and returns at most $numhits
in a Clair::Cluster. The id of the each document is set to the query followed
by the index of the hit.

=cut

1;

