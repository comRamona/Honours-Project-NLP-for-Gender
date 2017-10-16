package Clair::Network::Writer::GraphML;
use Clair::Network::Writer;
@ISA = ("Clair::Network::Writer");

use strict;
use warnings;

use vars qw($VERSION);

$VERSION = '0.01';

=head1 NAME

Clair::Network::Writer::GraphML - Class for writing GraphML network files

=cut

=head1 SYNOPSIS

my $export = Clair::Network::Writer::GraphML->new();
$export->set_name("graphml");
$export->write_network($net, "filename");

=cut

=head1 DESCRIPTION

This class will write a network object into a GraphML compatible file.

=cut


sub _write_network {
  my $self = shift;
  my $net = shift;
  my $fn = shift;
  my $noduplicate = 0;
  my %parameters = @_;
  $noduplicate = 1 if (exists $parameters{no_duplicate} && $parameters{no_duplicate} == 1);

  my $graph = $self->{graph};

  open(GRAPH, "> $fn") or die "Couldn't open file: $fn\n";

  print GRAPH <<EOH
<?xml version="1.0" encoding="UTF-8"?>
<graphml xmlns="http://graphml.graphdrawing.org/xmlns"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://graphml.graphdrawing.org/xmlns
                      http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd">
EOH
;

  print GRAPH "<key id=\"d1\" for=\"edge\" attr.name=\"weight\" attr.type=\"double\"/>\n";
  if ($net->{directed}) {
    print GRAPH "  <graph id=\"graph\" edgedefault=\"directed\">\n";
  } else {
    print GRAPH "  <graph id=\"graph\" edgedefault=\"undirected\">\n";
  }

  foreach my $v ($net->get_vertices) {
    print GRAPH "    <node id=\"" . $v . "\"/>\n";
  }
  my %processedNodes = ();

  foreach my $e ($net->get_edges) {
    my ($u, $v) = @{$e};
    next if ($noduplicate == 1 && $processedNodes{"$u,$v"} == 1);
    if ($net->{graph}->has_edge_weight($u, $v)) {
      my $weight = $net->get_edge_weight($u, $v);
      print GRAPH "    <edge source=\"" . $u . "\" target=\"" . $v . "\">\n";
      print GRAPH "      <data key=\"d1\">" . $weight . "</data>\n";
      print GRAPH "    </edge>\n";
    } else {
      print GRAPH "    <edge source=\"" . $u . "\" target=\"" . $v . "\"/>\n";
    }
    $processedNodes{"$u,$v"} = 1;
    $processedNodes{"$v,$u"} = 1;
  }

  print GRAPH "  </graph>\n";
  print GRAPH "</graphml>\n";

  close(GRAPH);
}

1;
