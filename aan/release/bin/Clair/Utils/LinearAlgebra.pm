package Clair::Utils::LinearAlgebra;

my $error = "e";
my $lengthError = -1;
my $countError = -1;

=pod

=head1 NAME 

LinearAlgebra::InnerProduct

=head1 SYNOPSIS

@a = (1,4,2,3,6);
@b = (4,1,2,2,3);
$result = innerProduct(\@a,\@b);

=head1 DESCRIPTION 

Computes inner product of two arrays of numbers.

=head1 ERRORS 

Returns "e" if arrays are not the same length.
Returns "e" if only one array is given as input.
Returns "e" if more than one array is given as input.

=head1 AUTHOR

Mark Thomas Joseph

=cut

sub innerProduct  {
	my $count = verifyCount (@_);
   	my $length = verifyLength(@_);
	if ($count == $countError || $count > 2) {
#		print "Error - Unable to perform an Inner Product on more than two vectors.\n";
		return $error;
    	}
    	else {
		if ($length == $lengthError) {
			return $error;
		}
		else {
			my ($v1,$v2) = @_;
	    		my @v1vals = @{$v1};
	    		my @v2vals = @{$v2};
	
	    		my $sum = 0.0;
	    		my $l = scalar @v1vals;
	    		foreach $i (0..($l-1))  {
				$sum += $v1vals[$i]*$v2vals[$i];
	    		}
	    		return $sum;
		}
    	}
}

=pod

=head1 NAME 

LinearAlgebra::Subtract

=head1 SYNOPSIS

@a = (1,4,2,3,6);
@b = (4,1,2,2,3);
$result = subtract(\@a,\@b);

=head1 DESCRIPTION 

Subtracts arrays of numbers.

=head1 ERRORS 

Returns "e" if arrays are not the same length.
Returns "e" if only one array is given as input.

=head1 AUTHOR

Mark Thomas Joseph

=cut

sub subtract {

	my $count = verifyCount (@_);
    	my $length = verifyLength (@_);

    	if (($count == $countError) || ($length == $lengthError)) {
		return $error;
	}
	else {
		my @input = @_;
		my $result = shift(@input);
		my @result = @{$result};

		while (scalar @input > 0) { 
			my $v1 = shift(@input);
	    		my @v1vals = @{$v1};

	    		foreach $i (0..($length-1))  {
				$result[$i] = ($result[$i]-$v1vals[$i]);
	    		}
		}
		return @result;
    	}
}

=pod

=head1 NAME 

LinearAlgebra::Add

=head1 SYNOPSIS

@a = (1,4,2,3,6);
@b = (4,1,2,2,3);
$result = add(\@a,\@b);

=head1 DESCRIPTION 

Adds arrays of numbers.

=head1 ERRORS 

Returns "e" if arrays are not the same length.
Returns "e" if only one array is given as input.

=head1 AUTHOR

Mark Thomas Joseph

=cut

sub add {

	my $count = verifyCount (@_);
    	my $length = verifyLength (@_);

    	if (($count == $countError) || ($length == $lengthError)) {
		return $error;
	}
	else {
		my @input = @_;
		my $result = shift(@input);
		my @result = @{$result};

		while (scalar @input > 0) { 
			my $v1 = shift(@input);
	    		my @v1vals = @{$v1};

	    		foreach $i (0..($length-1))  {
				$result[$i] = ($result[$i]+$v1vals[$i]);
	    		}
		}
		return @result;
    	}
}

=pod

=head1 NAME 

LinearAlgebra::Average

=head1 SYNOPSIS

@a = (1,4,2,3,6);
@b = (4,1,2,2,3);
$result = average(\@a,\@b);

=head1 DESCRIPTION 

Computes average of arrays of numbers.

=head1 ERRORS 

Returns "e" if arrays are not the same length.
Returns "e" if only one array is given as input.

=head1 AUTHOR

Mark Thomas Joseph

=cut

sub average {

	my $count = verifyCount (@_);
    	my $length = verifyLength (@_);

    	if (($count == $countError) || ($length == $lengthError)) {
		return $error;
	}
	else {
		my @input = @_;
		my $interim = shift(@input);
		my @interim = @{$interim};

		while (scalar @input > 0) { 
			my $v1 = shift(@input);
	    		my @v1vals = @{$v1};

	    		foreach $i (0..($length-1))  {
				$interim[$i] = ($interim[$i]+$v1vals[$i]);
	    		}
		}
		
		my @result;
		foreach $ii (0..($length-1)) {
			$result[$ii] = ($interim[$ii]/$count);
		}
		return @result;
	}
}

=pod

=head1 NAME

verifyCount

=head1 SYNOPSIS

Counts the number of lists/arrays passed into LinearAlgebra in the @_ array

=cut

sub verifyCount {

	$count = scalar @_;
    	if ($count < 2)  {
		return -1;
    	}
    	else {
		return $count;
    	}
}

=pod

=head1 NAME

verifyLength

=head1 SYNOPSIS

Verifies matching lengths between all lists/arrays passed into LinearAlgebra in the @_ array

=cut

sub verifyLength {

    	my @array = @_;
    	$v = pop(@array);
    	my $length = (scalar @{$v});
    	my $index = (scalar @array);
    
    	for $i (0..$index) {
		$vt = $_[$i];
		if ( scalar @{$vt} != $length ) {
	    		return -1;
		}
		else {
	    		return $length;
		}
    	}
}

1;

