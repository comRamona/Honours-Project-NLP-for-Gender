package Clair::Network::Reader::Pajek;
use Clair::Network::Reader;
@ISA = ("Clair::Network::Reader");

use strict;
use warnings;
use Clair::Network;

use vars qw($VERSION);

$VERSION = '0.01';


=head1 NAME

Clair::Network::Reader::Pajek - Class for reading in Pajek network files

=cut

=head1 SYNOPSIS

my $reader = Clair::Network::Reader::Pajek->new();
my $net = $reader->read_network($filename);

=cut

=head1 DESCRIPTION

This class will read in a Pajek format graph file into a Network object.

=cut

sub _read_network {
        my $self = shift;
        my $filename = shift;

        my $net = Clair::Network->new(directed => 1);

        open(FIN, $filename) or die "Couldn't open $filename: $!\n";

        my $in_vertices = 0;
        my $in_edges = 0;
        my $in_arcs = 0;
        while (<FIN>) {
                if (/\*Vertices/i) {
                        $in_vertices = 1;
                } elsif (/\*Edges/i) {
                        $in_edges = 1;
                        $in_arcs = 0;
                        $in_vertices = 0;
                } elsif (/\*Arcs/i) {
                        $in_arcs = 1;
                        $in_edges = 0;
                        $in_vertices = 0;
                } else {
                        chomp;
                        $_ =~ s/^\s+//;
                        if ($in_vertices) {
                                my @v = split (/\s+/, $_);
                                if (defined $v[1]) {
                                        $v[1] =~ s/\"//g;
                                        $net->add_node($v[0], $v[1]);
                                } else {
                                        $net->add_node($v[0]);
                                }
                        } elsif ($in_arcs) {
# directed edge
                                my @e = split (/\s+/, $_);
                                $net->add_edge($e[0], $e[1]);
                        } elsif ($in_edges) {
# undirected edge
                                my @e = split (/\s+/, $_);
                                if ($#e == 2) { 
                                        $net->add_weighted_edge($e[0], $e[1], $e[2]);
                                        $net->add_weighted_edge($e[1], $e[0], $e[2]);
                                } elsif ($#e == 1) {
                                        $net->add_edge($e[0], $e[1]);
                                        $net->add_edge($e[1], $e[0]);
                                } else {
                                        print STDERR "Format ERROR!\n";
                                        exit;
                                }
                        }
                }
        }
        close FIN;

        return $net;
}

1;

