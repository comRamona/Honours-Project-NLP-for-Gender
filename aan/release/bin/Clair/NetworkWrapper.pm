package Clair::NetworkWrapper;
use Clair::Network;

@ISA = (Clair::Network);

sub new {
    my $class = shift;
    my %params = @_;
    my $self;

    if (defined $params{network}) {
        $self = $params{network};
    } else {
        $self = Clair::Network->new();
    }

    die "'prmain' is a required parameter" unless (defined $params{prmain});
    $self->{prmain} = $params{prmain};
    $self->{clean} = $params{clean};

    bless $self, $class;
}

sub compute_lexrank {

    my $self = shift;
    my $graph = $self->{graph};
    my @vertices = $graph->vertices();

    my %user_params = @_;
    my %params = (
        random_jump => 0.15,
    );
    foreach my $key (keys %user_params) {
        $params{$key} = $user_params{$key};
    }

    # These are temp files that are needed by the prmain program
    my $cos_file = "cos.temp";
    my $bias_file = "bias.temp";
    my $out_file = "out.temp";

    # The transition matrix
    my $rank_matrix = $self->get_property_matrix(\@vertices, 
        "lexrank_transition");

    #die "Lexrank matrix should be symmetric" 
    #    unless $rank_matrix->is_symmetric;

    #for (my $i = 0; $i < ($rank_matrix->dim())[0]; $i++) {
    #    die "Lexrank matrix should have 1's along the diagonal"
    #        unless ($rank_matrix->element($i + 1, $i + 1) == 1);
    #}

    # The bias vector
    my $v_matrix = $self->get_property_vector(\@vertices, "personalization");

    $self->make_matrix_stochastic($rank_matrix);
    $self->make_matrix_stochastic($v_matrix);

    # $m should equal $n
    my ($m, $n) = $rank_matrix->dim();

    # Writes the cosine file
    open COS, "> $cos_file" or die "Could not open cos.temp for writing: $!";
    for (my $i = 0; $i < $n; $i++) {
        for (my $j = 0; $j < $i; $j++) {
            my $value = $rank_matrix->element($i + 1, $j + 1);
            print COS "$i\t$j\t$value\n";
            print COS "$j\t$i\t$value\n";
        }
    }
    close COS;

    # Writes the bias file
    open BIAS, "> $bias_file" or die "Could not open bias.temp for writing: $!";
    for (my $i = 0; $i < $n; $i++) {
        my $value = $v_matrix->element($i + 1, 1);
        print BIAS "$i\t$value\n";
    }
    close BIAS;

    # Build the command for running lexrank
    my $prmain = $self->{prmain};
    my $max_id = $n - 1;
    my $jump = $params{random_jump};
    my $command = "$prmain -link $cos_file -maxid $max_id -jump $jump "
                . "-out $out_file -bias $bias_file 2>/dev/null";

    # Runs lexrank
    my @scores;
    if ( system($command) == 0 ) {
        open OUT, "< $out_file" or die "Could not read $out_file: $!";
        while (<OUT>) {
            chomp;
            my ($node, $value) = split /\s+/, $_;
            push @scores, $value;
        }
        close OUT;
    } else {
        die "There was an error running $prmain";
    }

    # Setting the vertex attributes
    for (my $i = 0; $i < $n; $i++) {
        $graph->set_vertex_attribute(
            $vertices[$i], "lexrank_value", $scores[$i]);
    }

    # Cleaning up
    if ($self->{clean}) {
        unlink($cos_file) or warn "Couldn't unlink $cos_file: $!";
        unlink($bias_file) or warn "Couldn't unlink $bias_file: $!";
        unlink($out_file) or warn "Couldn't unlink $out_file: $!";
    }

    return $self->get_property_hash("lexrank_value");
}

=head1 NAME

Clair::NetworkWrapper - A subclass of Clair::Network that wraps the C++ version
of Lexrank.

head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    #!/usr/bin/perl -w
    use Clair::NetworkWrapper;
    my $network = Clair::NetworkWrapper( prmain => "/path/to/prmain");
    # ...
    $network->compute_lexrank( jump => 0.15 );

This module is a subclass of Clair::Network. The only methods that it 
overrides are the constructor and compute_lexrank(). The constructor 
requires the programmer to specify a path to the C++ version of lexrank.
See the documentation for Clair::Network for more information on how to
use this module.

=head1 METHODS

=cut

=head2 new

# Create a new NetworkWrapper
$newtwork = new Clair::NetworkWrapper( prmain => "/path/to/lexrank" );

# Create a new NetworkWrapper from an existing Network
$new_network = new Clair::NetworkWrapper( 
    prmain => "/path/to/lexrank", 
    network => $old_network,
    clean => 1
);

Creates a new, empty network. 'prmain' is a required parameter and should
be a path to an instance of the C++ implementation of lexrank. Optionally,
you can create a NetworkWrapper from an existing network. If the clean
parameter is set to 1, then temporary files will be deleted.

=cut

1;
