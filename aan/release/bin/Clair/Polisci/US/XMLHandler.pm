package Clair::Polisci::US::XMLHandler;

use XML::Parser::PerlSAX;
use strict;

sub new {
    my $self = {};
    $self->{grafs} = [];
    return bless($self);
}

sub start_element {
    my ($self, $element) = @_;
    my $name = $element->{Name};
    $self->{text} = "";

    if ($name eq "TITLE") {
        $self->{title} = ""; 
    } elsif ($name eq "CHAMBER") {
        $self->{chamber} = ""; 
    } elsif ($name eq "DATE") {
        $self->{date} = "";
    } elsif ($name eq "GRAF") {
        $self->{current_graf} = { 
            pageref => "",
            speaker => "",
            content => "",
            type => ""
        };
    } 
}

sub end_element {
    my ($self, $element) = @_;
    my $name = $element->{Name};

    if ($name eq "TITLE") {
        $self->{title} = $self->{text};
    } elsif ($name eq "CHAMBER") {
        $self->{chamber} = $self->{text};
    } elsif ($name eq "DATE") {
        $self->{date} = $self->{text};
    } elsif ($name eq "GRAF") {
        push @{ $self->{grafs} }, $self->{current_graf};
    } elsif ($name eq "PAGEREF") {
        $self->{current_graf}->{pageref} = $self->{text};
    } elsif ($name eq "SPEAKER") {
        $self->{current_graf}->{speaker} = $self->{text};
    } elsif ($name eq "SPEECH") {
        $self->{current_graf}->{content} = $self->{text};
        $self->{current_graf}->{type} = "speech";
    } elsif ($name eq "NONSPEECH") {
        $self->{current_graf}->{content} = $self->{text};
        $self->{current_graf}->{type} = "nonspeech";
    }
}

sub characters {
    my ($self, $text) = @_;
    $self->{text} .= $text->{Data};
}

1;
