package Clair::Network::Writer::Edgelist;
use Clair::Network::Writer;
@ISA = ("Clair::Network::Writer");

use strict;
use warnings;
use Graph;

use vars qw($VERSION);

$VERSION = '0.01';

=head1 NAME

Clair::Network::Writer::Edgelist - Class for writing edge list network files

=cut

=head1 SYNOPSIS

my $export = Clair::Network::Writer::Edgelist->new();
$export->write_network($net, "filename");

=cut

=head1 DESCRIPTION

This class will write a network object into a edge list compatible file.

=cut

sub _write_network {
  my $self = shift;
  my $net = shift;
  my $filename = shift;
#  my $no_duplicate = shift;

  my %parameters = @_;
  my $no_duplicate = 0;
  $no_duplicate = 1 if (exists $parameters{no_duplicate} && $parameters{no_duplicate} == 1);

  my $graph = $net->{graph};

  my $skip_duplicates = 0;
  if (exists $parameters{skip_duplicates} &&
      $parameters{skip_duplicates} == 1) {
    $skip_duplicates = 1;
  }

  # if 1, ignore $u->$v if $v->$u exists
  my $skip_reverse = 0;
  if ($no_duplicate) {
  	$skip_reverse = 1;
  }

  my $delim = " ";
  if (exists $parameters{delim}) {
    $delim = $parameters{delim};
  }

  my $transpose = 0;
  if (exists $parameters{transpose} and $parameters{transpose} == 1) {
    $transpose = 1;
  }

  my $weights = 0;
  if (exists $parameters{weights} and $parameters{weights} == 1) {
    $weights = 1;
  }

  open(FILE, "> $filename") or die "Could not open file: $filename\n";

  my %seen_edges = ();
  my %processed_edges = ();
  my @vs = $graph->vertices();
  my %nodes;

  foreach my $node(@vs) {
  	$nodes{$node} = 0;
  }

  foreach my $e ($graph->edges) {
    my $u;
    my $v;
    my $w;

    ($u, $v) = @$e;
    $nodes{$u} = 1;
    $nodes{$v} = 1;
    if ($weights) {
      $w = $graph->get_edge_weight($u, $v);
    }
    if ($transpose == 1) {
      my $temp = $u;
      $u = $v;
      $v = $temp;
    }

    if (($skip_duplicates == 1)
		    || not exists $seen_edges{"$u,$v"}) {
	    next if (($skip_reverse == 1) && (exists $processed_edges{"$u,$v"})); 
	    if ($weights) {
		    print(FILE "$u$delim$v$delim$w\n");
	    } else {
		    print(FILE "$u$delim$v\n");
	    }
	    $seen_edges{"$u,$v"} = 1;
	    $processed_edges{"$u,$v"} = 1;
	    $processed_edges{"$v,$u"} = 1;
    }
  }

  my $w = 0;
  foreach my $node (sort keys %nodes) {
	  if ($nodes{$node} == 0) {
		  print (FILE "$node\n");

	  }
  }

  close(FILE);
}

1;
