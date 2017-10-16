package Clair::Bio::EUtils::ESearch;

=head1 NAME

Clair::Bio::EUtils::ESearch - a Perl interface to the ESearch utility

=head1 SYNOPSIS
    
    my $esearch = new Clair::Bio::EUtils::ESearch( 
        term => "asthma[mh] OR hay fever[mh]",
        retmax => "100"
    );

    my $idlistref = $esearch->{IdList};
    foreach my $id (@$idlistref) {
        print "$id\n";
    }

=head1 DESCRIPTION

The ESearch utility is used to query a database and return a list of 
ids. For example, search PubMed for articles and return a list of PMIDs.
For a complete description, see the ESearch specification on the Entrez
website.

=head1 METHODS

=head2 get_esearch_args

Returns a hash of the arguments passed to ESearch.

=head2 new

    my $esearch = new Clair::Bio::EUtils::ESearch(
        [key => value]
    );

Performs a search given a hash of the key value pairs described on the 
ESearch website. The tool, email, and retmode parameters are set by the
module and cannot be overridden.

Once a successful search has been completed, the results are available as
key/value pairs in the Clair::Bio::EUtils::ESearch object. These are

=over

=item IdList

A list of the IDs returned by ESearch.

=item Count

The total number of items returned.

=item RetMax

The maximum number specified in the query.

=item RetStart

The starting index specified in the query.

=item QueryKey, WebEnv

See the EUtils documentation on how to use these variables.

=back

=head1 REQUIRES

Clair::Bio::EUtils
Clair::Bio::EUtils::ESearchHandler
LWP::Simple
XML::Parser::PerlSAX

=head1 AUTHOR

Tony Fader, afader@umich.edu

=head1 SEE ALSO

The ESearch specification on the Entrez site: 
http://www.ncbi.nlm.nih.gov/entrez/query/static/esearch_help.html.

=cut

use strict;
use Carp;
use Clair::Bio::EUtils qw( $ESEARCH_URL $TOOL $EMAIL build_url );
use Clair::Bio::EUtils::ESearchHandler;
use LWP::Simple;
use XML::Parser::PerlSAX;

sub new {
    my $class =shift;
    my $self = {};
    my %params = @_;
    my %esearch_args = (
        db => "PubMed",
        usehistory => "y",
    );

    # Merge with the defaults
    foreach my $key (keys %params) {
        $esearch_args{$key} = $params{$key};
    }

    # Set the required parameters
    $esearch_args{tool} = $TOOL;
    $esearch_args{email} = $EMAIL;
    $esearch_args{retmode} = "xml";

    $self->{_esearch_args} = \%esearch_args;

    my $url = build_url( base => $ESEARCH_URL, args => \%esearch_args );

    my $handler = new Clair::Bio::EUtils::ESearchHandler;
    my $parser = new XML::Parser::PerlSAX( Handler => $handler );
    eval {
        $parser->parse(get($url));
    };
    croak "Couldn't parse ESearch results: $@" if $@;

    # Copy the results from the handler
    foreach my $key (keys %$handler) {
        $self->{$key} = $handler->{$key};
    }

    return bless($self, $class);

}

sub get_esearch_args {
    my $self = shift;
    if (defined $self->{_esearch_args}) {
        return %{ $self->{_esearch_args} };
    } else {
        return undef;
    }
}

1;
