package Clair::Network::Writer::Pajek;
use Clair::Network::Writer;
@ISA = ("Clair::Network::Writer");

use strict;
use warnings;
use Graph;
use Clair::Util;

use vars qw($VERSION);

$VERSION = '0.01';


=head1 NAME

Clair::Network::Writer::Pajek - Class for writing Pajek network files

=cut

=head1 SYNOPSIS

my $export = Clair::Network::Writer::Pajek->new();
$export->set_name("pajek");
$export->write_network($net, "filename");

=cut

=head1 DESCRIPTION

This class will write a network object into a Pajek compatible file.

=cut


sub _write_network {
  my $self = shift;
  my $net = shift;

  my $graph = $net->{graph};
  my $filename = shift;

  my %parameters = @_;
  my $noduplicate = 0;
  $noduplicate = 1 if (exists $parameters{no_duplicate} && $parameters{no_duplicate} == 1);


  my $altname = 0;
  if (exists $parameters{altname}) {
    $altname = $parameters{altname};
  }

  my $round = 0;
  if (exists $parameters{round}) {
    $round = $parameters{round};
  }

  my $networkName = "";
  if (not defined $self->{name}) {
    $networkName = "network";
  } else {
    $networkName = $self->{name};
  }

  my $directed = $net->{directed};

  my @vertices = $graph->vertices;

  my %numToLinkNames=();
  my %new_names = ();
  my $numNodes = 0;

  foreach my $v (sort @vertices) {
    $numToLinkNames{++$numNodes} = $v;
    if ($altname) {
      $new_names{$numNodes} = $net->get_vertex_attribute($v,
                                                         $altname);
    }
  }

  my %linkNamesToNum = reverse %numToLinkNames;

  open (PAJEK, "> $filename") or die "Could not open file: $filename\n";

  print PAJEK "*Network $networkName\r\n";

  print PAJEK "*Vertices $numNodes\r\n";
  for (my $i = 1; $i <= $numNodes; ++$i) {
    if ($altname) {
      print PAJEK "$i \"$new_names{$i}\"\r\n";
    } else {
      print PAJEK "$i \"$numToLinkNames{$i}\"\r\n";
    }
  }

  if ($directed) {
    print PAJEK "*Arcs\r\n";
  } else {
    print PAJEK "*Edges\r\n";
  }
  my %processedNodes = ();

  foreach my $v (sort @vertices) {
	  foreach my $neighbor ($graph->successors($v)) {
	  	  next if ($noduplicate == 1 && exists $processedNodes{"$v,$neighbor"});
		  if ($graph->has_edge_weight($v, $neighbor)) {
			  if ($round) {
				  print PAJEK "$linkNamesToNum{$v} $linkNamesToNum{$neighbor} ",
					Clair::Util::round_number($graph->get_edge_weight($v, $neighbor),
							4), "\r\n";
			  } else {
				  print PAJEK "$linkNamesToNum{$v} $linkNamesToNum{$neighbor} ",
					$graph->get_edge_weight($v, $neighbor), "\r\n";
			  }
		  } else {
			  print PAJEK "$linkNamesToNum{$v} $linkNamesToNum{$neighbor} 1\r\n";
		  }
		  $processedNodes{"$v,$neighbor"} = 1;
		  $processedNodes{"$neighbor,$v"} = 1;
	  }
  }

  close(PAJEK);
}

1;

