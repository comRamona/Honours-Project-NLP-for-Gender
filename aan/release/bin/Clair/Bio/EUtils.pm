package Clair::Bio::EUtils;

=head1 NAME

Clair::Bio::EUtils - a base class for Bio::EUtils objects

=head1 SYNOPSIS

    use Clair::Bio::EUtils qw($ESEARCH_URL);
    print "$ESEARCH_URL\n";

=head1 DESCRIPTION

This module is a container for variables useful inside of Clair::Bio::EUtils::*.

=head1 EXPORTABLE METHODS

=head2 build_url

    my %args = ( this => "that thing" );
    my $base = "http://foo.bar/thing.cgi";
    my $url = build_url( base => $base, args => \%ags );
    print "$url\n"; $ prints http://foo.bar/thing.cgi?this=that%20thing

=head2 hash2args

    my %hash = ( this => "that thing", foo => "bar" );
    my $str = hash2args(%hash);
    print "$str\n"; # prints this=that%20thing&foo=bar

=head1 EXPORTABLE VARIABLES

$ROOT_URL - the base url that all eutils depend upon
$ESEARCH_URL - the esearch url, including the ? at the end
$TOOL - the name of the tool to send to EUtils
$EMAIL - the email address to send to EUtils

=head1 AUTHOR

Tony Fader, afader@umich.edu

=cut

use strict;
use Exporter;
use URI::Escape;
our (@EXPORT_OK, @ISA);
@ISA = qw(Exporter);
@EXPORT_OK = qw( $ROOT_URL $ESEARCH_URL $TOOL $EMAIL hash2args build_url );

our $TOOL = "clairlib";
our $EMAIL = 'afader@umich.edu';
our $ROOT_URL = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils";
our $ESEARCH_URL = "$ROOT_URL/esearch.fcgi?";

sub hash2args {
    my %args = @_;
    map { delete $args{$_} unless $args{$_} } keys %args;
    return join("&", 
        ( map { uri_escape($_)."=".uri_escape($args{$_}) } sort keys %args ));
}

sub build_url {
    my %params = @_;
    my $base = $params{base} || "";
    my $argsref = $params{args} || {};
    unless ($base =~ /\?$/) {
        $base .= "?";
    }
    return $base . hash2args(%$argsref);
}

1;
