package Clair::Util;

use lib("..");
use Clair::Config;

use Graph::Directed;
use Clair::Network;

use strict;
use warnings;

use Clair::Utils::SimRoutines;
our $lang="ENG";
our $idffile = "enidf";

=over

=item round_number

        round_number($num, $places)

Rounds a number to a certain number of places.  Pass in the number and number
of digits beyond the decimal place to display.

=back

=cut

sub round_number {
  my $num = shift;
  my $places = shift;

  return sprintf("%." . $places . "f", $num);
}


sub build_IDF_database
{
  my %parameters = @_;
  my $text_file = $parameters{text_file};

  my %idf;

  open INFILE, $text_file or
      die "Unable to open '$text_file' for input\n";

  my $total = 0;
  while (<INFILE>) {
    my ($key, $value) = /^\s*(\S+)\s+([\d\.]+)\s*/;
    $idf{$key} = $value;

    unless (++$total % 100) {
      print STDERR "Wd: $total\r";
    }
  }

  print STDERR "\n";

  close INFILE;

  return %idf;
}

sub build_idf_by_line
{
  my $text = shift;
  my $dbm_file = shift;
  # my $given_count = shift;

  my %token_hash;
  dbmopen(%token_hash, $dbm_file, 0666);
        %token_hash = ();

  my $count = 0;

  my @lines = split("\n", $text);
  foreach my $l (@lines) {
    # print "Sentence $count: $l\n";
    $l =~ s/\s+/ /g;
    my @tokens = split(" ", $l);
    my %looked;

    foreach my $t (@tokens) {
      $t =~  s/^\\[0-9]+//;
      $t =~ s/^[\.\"\-\_\+\\\`\~\!\&\(\)\[\]\{\}\'\;\:\&\*\?\,]+//;
      $t =~ s/[\.\"\-\_\+\\\`\~\!\&\(\)\[\]\{\}\'\;\:\&\*\?\,]+$//;

      if ($t =~ /^\s*$/ || exists $looked{$t}) { next; }
      if ($token_hash{$t} and $token_hash{$t} > 0) {
        $token_hash{$t} ++;
      }
      else {
        $token_hash{$t} = 1;
      }

      $looked{$t}++;
    }
    $count++;
  }

  # print "Calculated count: $count\n";
  # if ($given_count) {
  #  $count = $given_count;
  #}

  # print "Using count: $count\n";

  foreach my $t (keys %token_hash) {
    # print "word: $t, count: $token_hash{$t}\n";
                if (0.5+$token_hash{$t} != 0) {
            $token_hash{$t} = log(($count+1)/(0.5+$token_hash{$t}));
                }
  }

        return %token_hash;
}

sub read_idf
{
  my $db_name = shift;
  my %db;

  dbmopen %db, $db_name, 0666;

  return %db;

  # my $retVal = "";
  # my $l;
  # my $r;
  # my $ct = 0;

  # while (($l, $r) = each %db) {
  #   $ct++;
  #   $retVal .= "$ct\t$l\t*$r*\n";
  # }

  # return $retVal;
}

# Compares any two files, returns 1 if they are the same, 0 if they are different
sub compare_files {
  my $expected_file = shift;
  my $generated_file = shift;

  if (!(-e $expected_file) or !(-e $generated_file)) {
    return 0;
  }

  my $expected_text = join "", `cat $expected_file`;
  my $generated_text = join "", `cat $generated_file`;

  if ($expected_text eq $generated_text) {
    return 1;
  } else {
    return 0;
  }
}

# Compares any two files, returns 1 if they are the same, 0 if they are different
sub compare_sorted_files {
  my $expected_file = shift;
  my $generated_file = shift;

  if (!(-e $expected_file) or !(-e $generated_file)) {
    return 0;
  }

  my $expected_text = join "", `sort $expected_file | uniq`;
  my $generated_text = join "", `sort $generated_file | uniq`;

  if ($expected_text eq $generated_text) {
    return 1;
  } else {
    return 0;
  }
}

sub within_delta {
    my $number1 = shift;
    my $number2 = shift;
    my $delta = shift;
    return abs($number1 - $number2) < $delta;
}


=head1 NAME

Clair::Util - Utility Class for the CLAIR Library

head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This module provides utility functions for use when using the Clair library

=head1 METHODS

=cut


=head2 build_IDF_database

Clair::Util::build_IDF_database

builds an IDF database from the provided text file.

=cut



=head2 build_idf_by_line

Clair::Util::build_idf_by_line

Uses dbm files to compute the idf for a provided text

=cut



=head2 read_idf

Clair::Util::read_idf

Reads the dbm IDF file produced by build_idf

=cut



=head1 AUTHOR

Dagitses, Michael << <clair at umich.edu> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-clair-document at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=clairlib-dev>.
I will be notified, and then you will automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Clair::Util

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/clairlib-dev>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/clairlib-dev>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=clairlib-dev>

=item * Search CPAN

L<http://search.cpan.org/dist/clairlib-dev>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 The University of Michigan, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
