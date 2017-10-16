package Clair::Polisci::Speaker;
use strict;

sub new {
    my $self = shift;
    my %args = @_;
    die "Speaker source must be defined" unless defined $args{source};
    die "Speaker id must be defined" unless defined $args{id};
    $self = \%args;
    return bless($self);
}

sub equals {
    my $self = shift;
    my $other_speaker = shift;

    return ($self->{source} eq $other_speaker->{source}) 
        && ($self->{id} eq $other_speaker->{id});
}

=head1 NAME

Clair::Polisci::Speaker - An object representing a hansard speaker

=head1 SYNOPSIS

    my $speaker = Clair::Polisci::Speaker->new(
        source => "polisci_us",
        id => 49238
    );

=head1 DESCRIPTION

This is a Speaker object used to represent a generic speaker from a hansard.
It is basically a container object with a source, an id and an equality 
relation. Two Speakers are equal if they come from the same source and have 
the same id.

=head1 METHODS

=head2 new
    
    my $speaker = Clair::Polisci::Speaker->new( 
        source => "some_db", 
        id => 49032 
    );

Constructs a new speaker from the given source and id. Additional properties
can be given to the speaker by adding them to the constructor's parameter
list.
    
=head1 AUTHOR

Tony Fader L<afader@umich.edu>

=cut

1;
