package Clair::Polisci::Graf;
use strict;
use Clair::Document;

sub new {

    my $self = shift;
    my %args = @_;

    die "Graf source must be defined" unless defined $args{source};
    die "Graf index must be defined" unless defined $args{index};
    die "Graf content must be defined" unless defined $args{content};
    die "Graf speaker must be defined" unless defined $args{speaker};

    $self = \%args;
    return bless($self);

}

sub to_document {
    
    my $self = shift;

    my $doc = Clair::Document->new(
        string => $self->{content},
        type => "text"
    );

    return $doc;
}

=head1 NAME

Clair::Polisci::Graf - An object representing a hansard graf

=head1 SYNOPSIS

    my $speaker = Clair::Polisci::Speaker->new( ... );
    my $graf = Clair::Polisci::Graf->new(
        source => "polisci_us",
        index => 2,
        content => "Four score and seven million years ago...",
        speaker => $speaker
    );

=head1 DESCRIPTION

This is a Graf object used to represent a generic graf from a hansard. A
graf is the smallest unit of speech in a hansard. An ordered list of 
grafs makes up a record. Each graf must have a source, an index, some 
content, and a speaker. 

=head1 METHODS

=head2 new

     my $graf = Clair::Polisci::Graf->new(
        source => "polisci_us",
        index => 2,
        content => "Four score and seven million years ago...",
        speaker => $speaker
    );

Constructs a new graf from the given parameters. source, index, content,
and speaker are all required. Additional information can be associated with
this graf by passing it to the constructor as a parameter.

=head2 to_document

    use Clair::Document;
    my $doc = $graf->to_document();

Returns the graf as a Clair::Document object. The body of the document is
from the graf's content.

=head1 AUTHOR

Tony Fader L<afader@umich.edu>

=cut

1;
