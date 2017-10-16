package Clair::Bio::EUtils::ESearchHandler;

=head1 NAME

Clair::Bio::EUtils::ESearchHandler - an XML handler for parsing ESearch results

=head1 SYNOPSIS

    use XML::Parser::PerlSAX;
    use Clair::Bio::EUtils::ESearchHandler;

    my $handler = new Clair::Bio::EUtils::ESearchHandler;
    my $parser = new XML::Parser::PerlSAX( Handler => $handler );

    # Parse from some source
    $parser->parse( Source => ... );

    # Access parsed fields
    print "Count: $handler->{Count}\n";
    print "RetMax: $handler->{RetMax}\n";
    print "RetStart: $handler->{RetStart}\n";
    print "QueryKey: $handler->{QueryKey}\n";
    print "WebEnv: $handler->{WebEnv}\n";
    print "IdList: " . join(" ", @{$handler->{IdList}}) ."\n";

=head1 REQUIRES

XML::Parser::PerlSAX;

=head1 AUTHOR

Tony Fader, afader@umich.edu

=head1 SEE ALSO

XML::Parser::PerlSAX

=cut

use strict;
use XML::Parser::PerlSAX;

sub new {
    my $self = {};

    # Stores element body
    $self->{_chars} = "";
    $self->{_path} = "";

    # Public fields
    $self->{IdList} = [];
    $self->{Count} = 0;
    $self->{RetMax} = 0;
    $self->{RetStart} = 0;
    $self->{QueryKey} = 0;
    $self->{WebEnv} = "";

    return bless($self);
}

sub start_element {
    my ($self, $element) = @_;
    $self->{_chars} = "";
    $self->{_path} .= "/$element->{Name}";
}

sub end_element {

    my ($self, $element) = @_;
    my $name = $element->{Name};

    if ($self->{_path} eq "/eSearchResult/Count") {
        $self->{Count} = $self->{_chars};
    } elsif ($self->{_path} eq "/eSearchResult/RetMax") {
        $self->{RetMax} = $self->{_chars};
    } elsif ($self->{_path} eq "/eSearchResult/RetStart") {
        $self->{RetStart} = $self->{_chars};
    } elsif ($self->{_path} eq "/eSearchResult/QueryKey") {
        $self->{QueryKey} = $self->{_chars};
    } elsif ($self->{_path} eq "/eSearchResult/WebEnv") {
        $self->{WebEnv} = $self->{_chars};
    } elsif ($self->{_path} eq "/eSearchResult/IdList/Id") {
        push @{ $self->{IdList} }, $self->{_chars};
    }

    $self->{_path} =~ s/\/$name$//;

}

sub characters {
    my ($self, $text) = @_;
    $self->{_chars} .= $text->{Data};
}

sub end_document {
    my $self = shift;
    delete $self->{_path};
    delete $self->{_chars};
}

1;
