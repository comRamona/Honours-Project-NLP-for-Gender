package Clair::Gen;

use warnings;
use strict;

use Statistics::ChisqIndep;
use POSIX;
use Math::Random qw (random_poisson);
use Clair::ChisqIndependent;

sub new {
	my $class = shift;
	my %parameters = @_;

	my @distribution = ();

	if (exists $parameters{distribution}) {
		my $d = $parameters{distribution};
		@distribution = @$d;
	}

	my $self = bless {
		distribution => \@distribution,
	}, $class;

	return $self;
}

sub distribution {
	my $self = shift;

	my $dist = $self->{distribution};

	return @$dist;
}

sub count {
	my $self = shift;

	my $dist = $self->{distribution};
	my @distribution = @$dist;

	my $count = @distribution;

	return $count;
}

sub read_from_file {
	my $self = shift;
	my $filename = shift;

	open(FILE, "< $filename");
	my $largest_key = 0;
	my %dist_hash = ();

	while (<FILE>) {
		next unless m/(.+) (.+)/;

		my $value = $1;
		my $key = $2;

		$dist_hash{$key} = $value;
		if ($key > $largest_key) {
			$largest_key = $key;
		}
	}

#	$self->{distribution} = \%dist_hash;
#	return %dist_hash;

	my @ret_array;
	foreach my $k (1..$largest_key) {
		# print "$k: ";
		if (exists $dist_hash{$k}) {
			push(@ret_array, $dist_hash{$k});
			# print $ret_array[$k-1];
			# print "\n";
		} else {
			push(@ret_array, 0);
			# print "0\n";
		}
	}

	$self->{distribution} = \@ret_array;

	return @ret_array;
}

sub plEstimate {
	my $self = shift;
	my $obs = shift;
	my @observed = @$obs;

	my %points;

	# x_total is the sum of all x's
	my $x_total=0;
	# y_total is likewise: \sum_i y_i
	my $y_total=0;
	# number of data points.
	my $num_points=0;

	my $num_elements = @observed;

	foreach my $key (1..$num_elements)
	{
		my $value = $observed[$key-1];

		# Added Thu Apr 14 23:31:35 EDT 2005
		# By Alex C De Baca
		#
		# Can't take the log of zero, so zero entries would
		#   kill this script before.
		#
		next if ($key == 0 || $value == 0);
		
		# End of added section
		
		#  print "$1 $2\n";
		my $one=log($value);
		my $two=log($key);
		$points{$two}=$one;
		$x_total+=$two;
		$y_total+=$one;
		$num_points++;
	}
	
	my $x_average=$x_total/$num_points;
	my $y_average=$y_total/$num_points;
	
	# \sum_i x_i y_i
	my $sum_x_and_y=0;
	# \sum_i {x_i}^2
	my $sum_x_squared=0;
	my $sum_x=0;
	my $sum_y=0;
	
	foreach (keys %points)
	{
		$sum_x_and_y+=($_)*($points{$_});
		$sum_x_squared+=($_)**2;
		$sum_x+=$_;
		$sum_y+=$points{$_};
	}
	
	# here's where the formula for linear regression comes in (check your
	# stats book if you forgot)
	
	my $m=( $num_points*$sum_x_and_y - $sum_x*$sum_y ) /
	      ( $num_points*$sum_x_squared - $sum_x**2 );
	
	my $b=$y_average-$m*$x_average;
	
	#  Since $b is actually (log C) in log y = log C + a log x,
	#  with y = Ce^(ax), we get
	
	my $C=exp($b);
	
	my $a = $m;
	
	# print "y = $C x^$a\n";
	return ($C, $a);
}

# poissonEstimate is not yet written
sub poissonEstimate {
	my $self = shift;

	return 0;
}

sub genPL {
	my $self = shift;
	my $c_hat = shift;
	my $alpha_hat = shift;
	my $n = shift;

	my @ret_array;

	foreach my $i (1..$n) {
		my $j = $c_hat * $i ** $alpha_hat;
		# print "$j $i\n";
		push(@ret_array, $j);
	}

	return @ret_array;
}

sub genPois {
	my $self = shift;
	my $l = shift;
	my $n = shift;

	my @obs = &random_poisson($n, $l);

	return @obs;
}

sub compareChiSquare {
	my $self = shift;

	my $obs = shift;
	my @observed = @$obs;

	my $exp = shift;
	my @expected = @$exp;

	my $extra_df = shift;

	my @chi_array = (\@observed, \@expected);

	my $chi = new Clair::ChisqIndependent;
	$chi->load_data(\@chi_array);
	$chi->{df} -= $extra_df;
	$chi->recompute_chisq();

	return ($chi->{df}, $chi->{p_value});
}


=head1 NAME

Clair::Gen - Generator Class for the CLAIR Library

head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This module works with distributions: to produce random and expected distributions
and to compare them.  It works with Poisson and Power Law distributions.

=head1 METHODS

=cut

    
=head2 new

$gen = new Clair::Gen(distribution => \@dist);

Creates a Gen class with the specified distribution.  If no distribution is given,
the class is created with an empty distribution.

=cut



=head2 distribution

distribution

Returns the distribution.

=cut



=head2 count

count

Returns the number of elements in the distribution

=cut


=head2 read_from_file

read_from_file($filename);

Reads a distribution from a file.  Distribution should have lines with the format:
value key

=cut


=head2 plEstimate

($c_hat, $alpha_hat) = plEstimate(\@observed)

Estimates the values for c_hat and alpha_hat for the observed distribution as a power law
distribution.

=cut


=head2 poissonEstimate

poissonEstimate

Does nothing currently.  A stub is in place for a function that will behave like the
power law estimate above, but for a poisson distribution

=cut


=head2 genPL

genPL($c_hat, $alpha_hat, $n)

Generates the expected power law distribution for the given values of c_hat, alpha_hat, and the
number of keys

=cut


=head2 genPois

genPois($l, $n)

Generates a random poisson distribution for the provided values of n and l.

=cut



=head2 compareChiSquare

($df, $p_value) = compareChiSquare(\@observed, \@expected, $df);

Performs a chi square comparison of observed and expected values.  Reduces the number of degrees
of freedom by the value in $df.  Returns the number of degrees of freedom and the p-value.

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

    perldoc Clair::Gen

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
