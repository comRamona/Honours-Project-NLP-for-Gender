package Clair::Utils::WebSearch;

use strict;
use vars qw(@ISA @EXPORT);

use Net::Google;

use LWP::UserAgent;
use HTTP::Request;
use URI::URL;
use URI::Escape;
use HTML::Parser 3.00 ();

use Clair::Config;

#--------------------------------------------------------------
#  CPAN describes locale as "Perl pragma to use and avoid
#  POSIX locales for built-in operations
#--------------------------------------------------------------
use locale;
use POSIX qw( locale_h );
setlocale( LC_CTYPE, 'iso_8859_1' );


#--------------------------------------------------------------
=pod

=head1 NAME

WebSearch

=head1 SYNOPSIS

my @results = @{WebSearch::googleGet($query, $maxresults)};

my $content = WebSearch::download($urlstring, $filename);

=head1 METHODS

=head2 googleGet

USAGE:  my $hitlist = WebSearch::googleGet($query, $nbhits);

$query: a string to search for on Google 

$nbhits: number of top document URLs to return 

$hitlist: an array that stores the results returned

=head2 downloadUrl

USAGE:  download($url, $filename)

downloads URL content (removes scripts and style tags)

stores in URI::URL-escaped file 

=cut

#--------------------------------------------------------------

sub googleGet  {
    my $query = shift;
    my $nbHits = shift;

    # See the clairlib web page for instructions on obtaining
		# a Google key and setting the default key in lib/Clair/Config.pm
		my $key = shift || $GOOGLE_DEFAULT_KEY;

    my @results = ();
    my @urls = ();

    @results=get_urls_netgoogle($query, ($nbHits+20), $key);

    my $counter = 0;
    foreach my $i (0..$nbHits+20) {

        my $check = &checkurl($results[$i]);
        next if $check == 1;
        next if ($results[$i] !~ /\w/);

        if (($results[$i] !~ /\b(question answering|QA|trec)\b/i) and 
            ($results[$i] !~ /(ps|gz|pdf|jpg)$/)) {
                      $counter++;
                      push(@urls, $results[$i]);
                      last if ($counter == $nbHits);
        }

        last if ($i == $#results);
     }

     return (\@urls);
}


sub get_urls_netgoogle {
     my $query=shift;
     my $num=shift;

     # See the clairlib web page for instructions on obtaining
		 # a Google key and setting the default key in lib/Clair/Config.pm
		 my $key = shift || $GOOGLE_DEFAULT_KEY;
		 
     my $google = Net::Google->new(key=>$key);
     my $search = $google->search();

     my @urls = ();

     $search->query($query);
     $search->lr(qw(en));
     $search->max_results($num);

     foreach my $result (@{$search->results()}) {
          
					my $title = $result->title();
          my $url = $result->URL();
          my $description = $result->snippet();

          $title =~ s/<.*?>//g;
          $description =~ s/<.*?>//g;

          push (@urls, "$url\t$title\t$description");
     }

     return @urls;

}

sub checkurl {

  my $f_bad=0;
  my $t_url=shift;
  my @badurls=("www-personal.umich.edu/~zzheng/answerbus/",
               "www-personal.umich.edu",
               "misshoover.si.umich.edu/",
               "www.umich.edu/~zzheng",
               "www.isi.edu/natural-language/projects/webclopedia/",
               "carleton.ca/~sscott2/",
               "trec.nist.gov",
               "www.cs.utexas.edu",
               "www.limsi.fr/Individu/QA/",
               "www.clairvoyancecorp.com/",
               "medialab.di.unipi.it/Project/QA/");

  foreach my $badurl (@badurls) {
     if ($t_url=~ m/$badurl/gi) {
            #  print "found one bad url $_ \n";
            $f_bad=1;
            last;
     }
  }
  return $f_bad;
 
}


sub download  {

    my $ua =  LWP::UserAgent->new();
    my $line = shift();
    my $filename = shift();
    # $filename = uri_escape($filename, "^A-Za-z0-9");

    # open OUTPUT, ">/dev/null";
                                                                                     
    my $Cont;
    print "downloading...$line\n";
                                                                                     
    $ua->timeout(5);
    my $ans=$ua->request(HTTP::Request->new("GET",url($line)));
                                                                
    if ($ans->is_success){
                                                                
        $Cont= $ans->content();
        if (length($Cont)>2500000) {
            print STDERR "$line is too large:", length($Cont),"\n";
        } else {
            open(OUTFILE, ">$filename");
            print OUTFILE $Cont;
            close OUTFILE;
        }
    } else {
        print "Can't download $line\n";
    }
                                                  
    return $Cont;

}

1;

