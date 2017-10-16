package Clair::Polisci::Record;
use strict;
use Clair::Cluster;
use Clair::Document;

sub new {
    my $self = shift;
    my %args = @_;

    die "Record source must be defined" unless defined $args{source};

    $args{grafs} = [] unless defined $args{grafs};
    $self = \%args;
    return bless($self);
}

sub add_graf {

    my $self = shift;
    my $graf = shift;

    my $grafs_ref = $self->{grafs};
    push @$grafs_ref, $graf;

    $self->{grafs} = $grafs_ref;

}

sub size {
    my $self = shift;
    return scalar @{$self->{grafs}};
}

sub get_grafs {

    my $self = shift;
    my %args = @_;

    # Need to check for speaker equality as a special case since it is an
    # object 
    my $speaker;
    if ($args{speaker}) {
        $speaker = $args{speaker};
        delete $args{speaker};
    }

    my @result;
    my $grafs_ref = $self->{grafs};

    # If each graf passes the requirements, push it onto the result
    foreach my $graf (@$grafs_ref) {
        if ( !$speaker || $speaker->equals($graf->{speaker}) ) {
            my $passed = 1;
            foreach my $key (keys %args) {
                $passed = 0;
                last unless (defined $graf->{$key});
                if ($graf->{$key} eq $args{$key}) {
                    $passed = 1;
                    next;
                }
            }
            if ($passed) {
                push @result, $graf;
            }
        }
    }

    # Sort the result by index and return
    return sort { $a->{index} <=> $b->{index} } @result;

}

sub to_string {

    my $self = shift;
    my %args = @_;

    my @grafs = $self->get_grafs(%args);

    my $string = "";
    foreach my $graf (@grafs) {
        $string .= $graf->{content};
    }
    return $string;
}

sub to_document {

    my $self = shift;
    my %args = @_;

    my $doc = Clair::Document->new( 
        string => $self->to_string(%args), 
        type => "text"
    );
    return $doc;

}

sub to_graf_cluster {

    my $self = shift;
    my %args = @_;

    my @grafs = $self->get_grafs(%args);
    my $cluster = Clair::Cluster->new();

    foreach my $graf (@grafs) {
        $cluster->insert($graf->{index}, $graf->to_document());
    }

    return $cluster;
}

=head1 NAME

Clair::Polisci::Record - An object representing a hansard record

=head1 SYNOPSIS

    use Clair::Cluster;
    use Clair::Document;

    my $record = Clair::Polisci::Record->new( source => "some_db" );
    my $graf = Clair::Polisci::Graf->new( ... );
    my $speaker = Clair::Polisci::Speaker->new( ... );
    $record->add_graf($graf);
    ...
    my %filter = ( is_speech => 1, speaker => $speaker );
    my @grafs = $record->get_grafs(%filter);
    my $cluster = $record->to_cluster(%filter);
    my $doc = $record->to_document(%filter);
    print $doc->to_string();

=head1 DESCRIPTION

This is a Record object used to represent a generic handard Record. A record
is an ordered collection of grafs. This module contains methods to convert
a record to cluster of grafs or a document and allows for filtering/projections
of grafs based on their properties. 

=head1 METHODS

=head2 new

     my $record = Clair::Polisci::Record->new(
        source => "polisci_us",
     );

Constructs a new record from the given source. Additional information can be 
associated with this graf by passing it to the constructor as a parameter.

=head2 add_graf

    my $graf = Clair::Polisci::Graf->new( ... );
    $record->add_graf($graf);

Adds a graf to the record. Its index in the record is determined by 
$graf->{index} and is not guaranteed to be unique within this record.

=head2 size
    
    $record->size()

Returns the total number of grafs in this record.

=head2 get_graf

    my %filter = (
        speaker => $speaker,
        is_speech => 1
    );
    my @grafs = $record->get_grafs(%filter);

Returns the list of grafs, ordered by their indices, from this record that
satisfy the given filter. In the above example, only grafs in $record
which satisfy $graf->{is_speech} == 1 and $graf->{speaker}->equals($speaker)
will be returned in the list.

=head2 to_string

    my $string = $record->to_string(%filter);

Returns the content of all grafs satisfying %filter concatenated together. See
the description of get_graf(%filter) for more information.

=head2 to_document

    my $doc = $record->to_document(%filter);

Returns the content of all grafs satisfying %filter concatenated together and
then converted into Clair::Document. See the description of get_graf(%filter)
for more information.

=head2 to_graf_cluster

    my $cluster = $record->to_graf_cluster(%filter);

Returns a cluster whose documents are the content of the grafs of this 
record that satify %filter. See the description of get_graf(%filter) for more
information.
    
=head1 AUTHOR

Tony Fader L<afader@umich.edu>

=cut

1;
