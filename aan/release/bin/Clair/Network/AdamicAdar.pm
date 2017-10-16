package Clair::Network::AdamicAdar;
use Carp;

$VERSION = 0.01;
=head1 NAME

Clair::Network::AdamicAdar - Calculate the adamic/adar value for the CLAIR Library

=cut

=head1 SYNOPSIS

This module calculate adamic/adar value for each pair of nodes in a network.

=cut

=head1 DESCRIPTION

This is a class for computing adamic/adar value.

=cut

@ISA=qw();

   
=head2 new

$aa = new Clair::Network::AdamicAdar();

Creates a AdamicAdar class.

=cut

sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	return $self;
}

=head2 readCorpus

read corpus into AdamicAdar class and calculate the adamic/adar value.

Returns a two dimensional hash, stored the value between any two nodes. Note: in order to save space, each value is stored at one node pair, which is in ascend order. So $result->{$a}->{$b} will return the value, $result->{$b}->{$a} won't

=cut

sub readCorpus {
	my $self = shift;
	my $folderName = shift;
	my %nodeTerms = ();
	my %termNodes = ();
	my %nodeNodes = ();

	my @files;

	opendir DH, $folderName or die "can't open the folder: $!";	
	
	while (defined($file = readdir(DH))) {
		unless ($file =~ /^\.\.?$/) {
			push(@files, $file);	
		}	
	}


	closedir DH;

	foreach $fileName (@files) {
		open(FH, "< $folderName/$fileName");

		while(my $attr=<FH>) {
			chomp($attr);
			next unless($attr =~ /(\W|\D)+/);

			$termFrequency{$attr}++;
			unless (defined $nodeTerms{$fileName}{$attr}) { 
				$nodeTerms{$fileName}{$attr} = 1;
			}
			unless (defined $termNodes{$attr}{$fileName}) {
				$termNodes{$attr}{$fileName} = 1;
			}
		}
	}

	foreach $node(@files) {
		foreach $term (keys %{$nodeTerms{$node}}) {
			foreach $node1 (keys %{$termNodes{$term}}) {
				if ($node lt $node1) {
					$nodeNodes{$node}{$node1}+=1/log($termFrequency{$term});
				}
			}
		}

	}

	$self->{nodeTerms} = \%nodeTerms;
	$self->{termNodes} = \%termNodes;
	$self->{nodeNodes} = \%nodeNodes;

	return $self->{nodeNodes};
}

=head2 printResult

print each aa value to the standard output

=cut

sub printResult {
    my $self = shift;
    my $result = $self->{nodeNodes};
 
    foreach $key(keys %{$result}) {
        foreach $key1(keys %{$result->{$key}}) {
            print "$key\t$key1\t$result->{$key}->{$key1}\n";
        }
    }
}

=head2 printNodeTerms 

print each node and the terms contained in each node.

=cut

sub printNodeTerms {
    my $self = shift;
    my $nodeTerms = $self->{nodeTerms};

    foreach $node(sort keys %nodeTerms) {
        print "$node:\n";
        foreach $term(sort keys %{$nodeTerms{$node}}) {
            print "\t$term\n";
        } 
    }
}

sub printNodeTable {
    my $self = shift;
    my $nodeNodes = $self->{nodeNodes};

    foreach $node(sort keys %nodeNodes) {
        foreach $node1 (sort keys %{$nodeNodes{$node}}) {
            print "$node\t$node1\n";
        }
    }
}

sub printTermNodes {
    my $self = shift;
    my $termNodes = $self->{termNodes};

    foreach $term(sort keys %termNodes) {
        foreach $node(sort keys %{$termNodes{$term}}) {
            print "$term\t$node\n";
        }
    }
}

=head1 AUTHOR

Chen, Huang << <clair at umich.edu> >>

=cut


=head1 BUGS

Please report any bugs or feature requests to
C<bug-clair-document at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=clairlib-dev>.
I will be notified, and then you will automatically be notified of progress on
your bug as I make changes.

=cut

1;	
