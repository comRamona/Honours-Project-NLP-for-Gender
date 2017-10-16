package Clair::Utils::CorpusDownload;

use POSIX;
use Clair::Utils::TFIDFUtils;
use File::Path;
use File::Find;
use Lingua::Stem;
use HTML::LinkExtractor;

use Clair::Config;

use FindBin;

use File::Copy qw(copy);
use File::Path qw(mkpath);
use strict;
#use warnings;

our @EXPORT_OK   = qw($verbose);

use vars qw($verbose);

$verbose = 0;

#use ALE::Stemmer qw(ale_stemsome);
# use ALE::Default::NormalizeURL qw(ale_normalize_url);
# use ALE::Wget qw(alecanonurl);

=pod

=head1 NAME

CorpusDownload

=head1 SYNOPSIS

CorpusDownload

=head1 DESCRIPTION

This module supplies the functionality of a subset of the
perltree routines.  Specifically, it downloads the documents
requested, stores them in the TREC corpus format used by
perltree and builds the TF/IDF databases.

=head1 METHODS

=head2 new

$cref = Clair::Utils::CorpusDownload::new(rootdir => "/path/to/project",
  corpusname = "uiuc");

B<rootdir>

(optional) The path to the directory where the corpus
and associated TFIDF will be built and stored.  Default is
"/data0/projects/tfidf".  This path should be an absolute
path, not a relative one.

B<corpusname>

(required) The name of the corpus that will be built.
The corpus will consist of all documents with URLs in
the array @urls that can be located at build time.
The top level of the corpus will be named
$rootdir/$corpusname.

B<buildCorpus>

$cref->buildCorpus(urlref => \@urls, cleanup => 0);

Builds a new corpus consisting of all documents at the URLs
passed in parameter @urls.

B<urlref>

(required) A reference to an array of URLs from which the
corpus should be built.

B<cleanup>

(optional) Remove (default) or retain (parameter 0 passed) metafiles
produced during corpus build.  (Note:  Retaining the metafiles can produce
undesirable side-effects during a rebuild.)

=head2 buildIdf

$cref->buildIdf(stemmed => 0, punc => 0);

Builds the IDF.  The IDF entries are stemmed or not depending on the
parameter passed to the constructor. Punctuation is included depending on
the punc argument.

B<stemmed>

(optional) Set to 1 if the IDF elements should be stemmed,
and 0 otherwise.  Default is 0 (not stemmed).

B<punc>

(optional) Set to 1 to include punctuation. Default is 0.

=head2 build_docno_dbm

$cref->build_docno_dbm();

Builds the DOCNO-to-URL and URL-to-DOCNO database.  The details
of this will be explained in the .pdf file that will be available
soon from the CLAIR website.  Meanwhile, all the user needs to
know is this method must be called before either TF is built.

=head2 buildTf

$cref->buildTf(stemmed => 1);

Builds the TF.  The TF entries are stemmed or not depending on
the parameter passed to the constructor.

Note that build_docno_dbm must have been called before this.

B<stemmed>

(optional) Set to 1 if the IDF elements should be stemmed,
and 0 otherwise.  Default is 0 (not stemmed).

B<NOTE>

If both stemmed and unstemmed TFs are desired, there is no need
to rebuild the docno dbm prior to building the second TF.

Using of the TF and IDF once they are built is described in Tf.pm
and Idf.pm

=cut


# --------------------------------------------------------------
#  Parameters:
#    rootdir : directory for corpus;
#              default is /data0/projects/tfidf
#    corpusname  : name of corpus to be created
# --------------------------------------------------------------
sub new  {

    my $class = shift;
    my %args = @_;
    my $usedocno = 1;

    my $stemmed =  ( defined $args{stemmed} ? $args{stemmed} : 0 );

    my $rootdir = ( defined $args{rootdir} ? $args{rootdir} :
                    "/data0/projects/tfidf" );
    my $corpus   = $args{corpusname};

    my %self = (rootdir => $rootdir, corpus => $corpus);
    bless(\%self, $class);
    return(\%self);

}


# --------------------------------------------------------------
#  sub poach (public)  : uses poacher to return a list of urls
#  reachable from a starting URL.
#
#  Parameters:
#    url : URL to start searching from
#    error_file => ef (optional) : file to store error messages
#    output_file => of (optional) : file to save the output from
#           the poacher script
# --------------------------------------------------------------
sub poach {
        my $self = shift;
        my $url = shift;
        my %parameters = @_;

        my $error_file = '/dev/null';
        if (exists $parameters{error_file}) {
                $error_file = $parameters{error_file};
        }

        my $test = "";
        if (exists $parameters{test}) {
                $test = $parameters{test};
        }

        my $retString = "";
        if ($test ne "") {
          $retString = `$^X $CLAIRLIB_HOME/lib/bin/poacher-new.pl $url -test $test 2> $error_file`;
        } else {
          $retString = `$^X $CLAIRLIB_HOME/lib/bin/poacher-new.pl $url 2> $error_file`;
        }
        print STDERR "--> $^X $CLAIRLIB_HOME/lib/bin/poacher-new.pl\n";
        #print STDERR "$url\n";

        my @lines = split(/\n/, $retString);
        my @urls = ();
        my %unique_urls=();

        foreach my $l (@lines) {
        print STDERR "$l\n" ;
                if ($l =~ /^http/) {
                #if (!exists {map { $_ => 1 } @urls}->{$l})
                #        {
                    if(not defined  $unique_urls{$l}){
                        push(@urls, $l);
                        $unique_urls{$l}=1;
                    }
                #        }
                }
        }
        return \@urls;

}


# --------------------------------------------------------------
#  sub buildCorpusFromFiles (public)  :  build
#  the TREC format corpus from a list of files.
#
#  Parameters:
#    filesref : reference to array of URLs
#    cleanup : set to 0 to retain build metafiles
#    skipCopy : skip copying files
# --------------------------------------------------------------
sub buildCorpusFromFiles  {

    my $self = shift;
    my %args = @_;

    my $rootdir = $self->{rootdir};
    my $corpus = $self->{corpus};

    my $filesref  = $args{filesref};
    my $cleanup =  ( defined $args{cleanup} ? $args{cleanup} : 1 );
    my $safe = ( defined $args{safe} ? $args{safe} : 0 );
    my $skipCopy = (defined $args{skipCopy} ? $args{skipCopy} : 0);

    makeDirs($rootdir, $corpus, safe => $safe);
    my $dir = `pwd`;
    chomp $dir;
    my $dest = "$rootdir/download/$corpus";

    if ( $skipCopy ){
      opendir DIR, $dest;
      if ( scalar(grep( !/^\.\.?$/, readdir(DIR)) == 0)) {
        print STDERR "Tried to skip file copy when $dest files don't exist!\n";
        return;
      }
    }

    if ( ! $skipCopy ) {
      copyFiles($filesref, $corpus, "dest" => $dest, "root" => $rootdir,
              "pwd" => $dir);
    }

    # getUniqList($corpus);
    chdir($dest);
    urlsToCorpus($rootdir, $corpus);
    chdir("../..");
    if ( $cleanup == 1 )  {
        cleanup($rootdir, $corpus);
    }
    chdir($dir);
}


# --------------------------------------------------------------
#  sub buildCorpus (public)  :  download documents and build
#  the TREC format corpus.
#
#  Parameters:
#    urlsref : reference to array of URLs
#    cleanup : set to 0 to retain build metafiles
# --------------------------------------------------------------
sub buildCorpus  {

    my $self = shift;
    my %args = @_;

    my $rootdir = $self->{rootdir};
    my $corpus = $self->{corpus};

    my $urlsref  = $args{urlsref};
    my $cleanup =  ( defined $args{cleanup} ? $args{cleanup} : 1 );

    makeDirs($rootdir, $corpus);
    chdir($rootdir);
    wgetall2($corpus, $urlsref);
    verifyUrl($corpus);
    getUniqList($corpus);
    urlsToCorpus($rootdir, $corpus);

    chdir("../..");
    if ( $cleanup == 1 )  {
        cleanup($rootdir, $corpus);
    }

}

# Like buildCorpus, but doesn't actually build the corpus.
# Just downloads the URLs and builds a list of unique URLs
sub download_urls  {
    my $self = shift;
    my %args = @_;

    my $rootdir = $self->{rootdir};
    print $rootdir, "\n";
    my $corpus = $self->{corpus};

    my $urlsref  = $args{urlsref};
    my $cleanup =  ( defined $args{cleanup} ? $args{cleanup} : 1 );

    makeDirs($rootdir, $corpus);
    chdir($rootdir);
    wgetall2($corpus, $urlsref);
    verifyUrl($corpus);
    getUniqList($corpus);

    chdir("../..");
    if ( $cleanup == 1 )  {
        cleanup($rootdir, $corpus);
      }
}

#
# function closure so we don't need a global variable
#
sub add_file {
  my $files = shift;
  my $root = shift;

  return sub {
    next if -d $_;
    my $file = $File::Find::name;
#    print $root . " " . $file, "\n";
    push @{$files}, $file;
  }
}

#
# Return list of files in directory
#
sub list_dir {
  my $dir = shift;

  $dir =~ s/^\.\///;
  my @files = ();
  my $root = `pwd`;
  chomp $root;
  find(&add_file(\@files, $root), $dir);

  return @files;
}

sub build_corpus_from_directory {
  my $self = shift;
  my %args = @_;

  my $rootdir = $self->{rootdir};
  my $corpus = $self->{corpus};

  my $dir  = $args{dir};
  my $cleanup =  ( defined $args{cleanup} ? $args{cleanup} : 0 );
  my $safe = ( defined $args{safe} ? $args{safe} : 0 );
  my $skipCopy = ( defined $args{skipCopy} ? $args{skipCopy} : 0);

  my @files = list_dir($dir);

  $self->buildCorpusFromFiles(filesref => \@files, cleanup => $cleanup,
                              safe => $safe, skipCopy => $skipCopy);
}

sub copyFiles {
  my $filesref = shift;
  my @files = @$filesref;

  my $corpus = shift;
  my %args = @_;

  my $dest =  ( defined $args{dest} ? $args{dest} : "" );
  my $root =  ( defined $args{root} ? $args{root} : "" );

  # Write the .uniq file list
  open LIST_UNIQ, "> $root/$corpus.download.uniq";

  # Copy each file
  foreach my $file (@files) {
    # skip the file if it doesn't exist
    if (not -f $file) {
      print STDERR "$file does not exist.\n";
      next;
    }

    # Get the name of the directory (remove the leading '/' and the filename
    if ($file =~ m#^\/?((.*)\/[^\/]*)$#) {
      my $copy_to = $dest . "/" . $1;
      my $directory = $dest . "/" . $2;

      if (not -d $directory) {
        mkpath($directory);
      }

      # Copy the file
      #                        `cp -p $file $copy_to`;
      copy($file, $copy_to) or die "Failed to copy file: $!";
      if (not -e $copy_to) {
        print STDERR "Error copying $copy_to\n";
      } else {
        print LIST_UNIQ "\"http://$copy_to\" \"$1\"\n";
      }
    } else {
      print STDERR "Unable to read line: $file\n";
    }
  }

  close LIST_UNIQ;
}

# --------------------------------------------------------------
#  sub makeDirs (private) : make directory tree for corpus.
#
#  $rootdir/
#    download/
#        $corpus/
#    corpora/
#        $corpus/
#    corpus-data/
#          $corpus/
# --------------------------------------------------------------
=head2 makeDirs

(private) makes directory tree for corpus

=cut

sub makeDirs  {

    my $rootdir = shift;
    my $corpus = shift;

    my %args = @_;

    my $safe = ( defined $args{safe} ? $args{safe} : 0 );

    if ( ! (-d "$rootdir") )  {
        mkdir $rootdir;
    }

    if ( ! (-e "$rootdir/download") )  {
       mkdir("$rootdir/download");
    }

    if ( ! (-e "$rootdir/corpora") )  {
       mkdir("$rootdir/corpora");
    }

    if ( ! (-e "$rootdir/corpus-data") )  {
       mkdir("$rootdir/corpus-data");
    }

    # Only remove files if safe mode is off
    if (!$safe) {
      if ( -e "$rootdir/download/$corpus" )  {
        system("rm -rf $rootdir/download/$corpus");
      }

      if ( -e "$rootdir/corpora/$corpus" )  {
        system("rm -rf $rootdir/corpora/$corpus");
      }

      if ( -e "$rootdir/corpus-data/$corpus" )  {
        system("rm -rf $rootdir/corpus-data/$corpus");
      }
    }

    mkdir "$rootdir/download/$corpus";
    mkdir "$rootdir/corpora/$corpus";
    mkdir "$rootdir/corpus-data/$corpus";
}


sub deleteCorpus() {
        my $self = shift;
        my $rootdir = $self->{rootdir};
        my $corpus = $self->{corpus};

        `rm -rf $rootdir/download/$corpus`;
        `rm -rf $rootdir/corpora/$corpus`;
        `rm -rf $rootdir/corpus-data/$corpus`;
        `rm -rf $rootdir/corpus-data/$corpus-tf`;
        `rm -rf $rootdir/corpus-data/$corpus-tf-s`;
}


# --------------------------------------------------------------
#   sub wgetall2 (private) :
#       + downloads documents from URLs in {urlsref}
#         to directory:
#             $rootdir/$download/$corpus/<host>/<path>
#       + writes wget output to $rootdir/$corpus.list
# --------------------------------------------------------------
=head2 wgetall2

(private) downloads documents from URLS in {urlsref}, using
GNU wget

=cut

sub wgetall2  {

    my $corpus = shift;
    my $urlsref = shift;

    chdir("download/$corpus");
    my $listfile = "../../$corpus.list";

    print "Preparing to download files...\n";
    foreach my $url (@{$urlsref})  {
      system("wget -Nnv -t 2 -x -w 1 '$url' >>$listfile 2>&1");
    }
    print "Download complete\n\n";
}

# --------------------------------------------------------------
#  sub verifyUrl (private) : compare URL list with download
#  results to find failed downloads, duplicate downloads and
#  empty downloads.
#
#  Write list of files correctly downloaded to $corpus.do2nload
#  in the form:  "<location>" "<url>"
# --------------------------------------------------------------
#   (current directory is $rootdir/download/$corpus/ directory)
# --------------------------------------------------------------
=head2

(private) identify failed, duplicate and empty downloads

=cut

sub verifyUrl  {

    my $corpus = shift();
    my $directory = ".";

    my $listfile  = "../../$corpus.list";
    my $dloadfile = "../../$corpus.download";
    print "Verifying URLs ...\n";

    my %urls = ();

    open(EMPTY, ">empty");
    open(DUPLICATES, ">duplicates");
    open(NOTDOWNLOADED, ">notdownloaded");
    open(OUTPUT, ">$dloadfile");
    open(URLS, "<$listfile");

    foreach my $line (<URLS>)  {

       chomp($line);
       if ($line =~ m/URL:(.+) \[.+\] -> \"(.+)\"/)  {
           if (!(exists $urls{$1}) && (-e "$directory/$2"))  {
             print OUTPUT "\"$1\" \"$2\"\n" ;
           }
           if(exists $urls{$1})  {
             print DUPLICATES "$1 $2\n" ;
           }
           unless (-e "$directory/$2")  {
             print NOTDOWNLOADED "$1 $2\n";
           }
           if (-z "$directory/$2")  {
             print EMPTY "\"$1\" \"$2\"\n";
           }
           if (-e "$directory/$2")  {
             $urls{$1}=1;
           }
       }
    }

    close(EMPTY);
    close(DUPLICATES);
    close(NOTDOWNLOADED);
    close(OUTPUT);
    close(URLS);

}

# --------------------------------------------------------------
#  sub getUniqList($corpus) (private)
# --------------------------------------------------------------
=head2 getUniqList

(private) compile list of unique downloads

=cut

sub getUniqList  {

    my $corpus = shift();
    my $infile = "../../$corpus.download";
    my $outfile = "../../$corpus.download.uniq";
    my $errfile = "../../$corpus.download.duplicates";
    print "Computing unique URL set...\n";

    my %urls = ();
    my %locs = ();

    open (IN, "<$infile");
    open (OUT, ">$outfile");
    open (ERR, ">$errfile");

    foreach my $line (<IN>)  {

        if ($line =~ m/\"(.+)\" \"(.+)\"/)  {

            unless (exists $urls{$1} || exists $locs{$2})  {
                print OUT "\"$1\" \"$2\"\n";
            }
            if (exists $urls{$1} || exists $locs{$2})  {
                print ERR "\"$1\" \"$2\"\n"
            }
            $urls{$1}=1;
            $locs{$2}=1;
        }

    }
    close(IN);
    close(OUT);
    close(ERR);
}

# --------------------------------------------------------------
#  sub cleanup (private) : remove auxiliary files
# --------------------------------------------------------------
=head2 cleanup

(private) remove metafiles

=cut

sub cleanup  {

   my $rootdir = shift();
   my $corpus = shift();

   system("rm $corpus.list");
   system("rm $corpus.download");
   system("rm $corpus.download.duplicates");
   system("rm $corpus.download.uniq");
   system("rm download/$corpus/empty");
   system("rm download/$corpus/duplicates");
   system("rm download/$corpus/notdownloaded");

}

# --------------------------------------------------------------
#  sub urlsToCorpus (private) : build TREC format corpus
# --------------------------------------------------------------
=head2 urlsToCorpus

(private) build corpus in TREC format from downloaded documents

=cut

sub urlsToCorpus  {

    my $rootdir = shift();
    my $corpus = shift();

    my $dir = `pwd`;
    chomp $dir;
    chdir("../../corpora/$corpus");

    my $urls = "../../$corpus.download.uniq";
    my $locations = "../../download/$corpus";
    print "Creating corpus files...\n";

                my $DOWNLOAD_PATH = `pwd`;
                chomp $DOWNLOAD_PATH;
                $DOWNLOAD_PATH .= "/" . $locations;

    open(PAGES, "<$urls") or
       print "Could not open url file $urls\n";
    my $documentID=0;

                my $DOC_TO_FILE_DBM_NAME = "../../corpus-data/$corpus/$corpus-docid-to-file";
                my %docid_to_file;
                dbmopen %docid_to_file, $DOC_TO_FILE_DBM_NAME, 0666 ||
                        die "Unable to open database $DOC_TO_FILE_DBM_NAME";
                %docid_to_file = ();

    foreach my $line (<PAGES>)  {
        $documentID++;

        # ---------------------------------------------------------
        # put leading zeros on document ID
        # ---------------------------------------------------------
        my $justified_document_ID="$documentID";
            for (my $i=1; $i<1000000; $i=$i*10) {
            if($documentID<$i)  {
                $justified_document_ID="0$justified_document_ID";
            }
        }

        # ---------------------------------------------------------
        # 8000 documents per directory
        # 200 documents per file,
        # 40 files per directory
        # ---------------------------------------------------------
        #    0-199  go into file 0 directory 0
        #  200-399  go into file 1 directory 0
        #            < ... >
        # 8000-8199 go into file 0 directory 1
        # 8200-8399 go into file 1 directory 1
        #            < ... >
        # ---------------------------------------------------------

        my $file_name=(floor($documentID/200)%40);
        my $directory_name=floor($documentID/(40*200));

        if ($file_name<10) {
            $file_name="0$file_name";
        } else {
            $file_name="$file_name";
        }

        if ($directory_name<10) {
            $directory_name="00$directory_name";
        } elsif ($directory_name<100) {
            $directory_name="0$directory_name";
        } else {
            $directory_name="$directory_name";
        }

        # ---------------------------------------------------------
        #  $line is of the form ["header" "location"]
        # ---------------------------------------------------------
        #  Make corpus file with header
        #            (dir-file-docno)
        #
        #   <DOC>
        #   <DOCNO>04-34-00054321</DOCNO>
        #   <DOCHDR>header</DOCHDR>
        #         { text from URL file }
        #   </DOC>
        # ---------------------------------------------------------
        mkdir $directory_name unless (-e $directory_name);
        open (CORPUSFILE, ">>$directory_name/$file_name");
        chomp $line;

        print STDERR "$line\n" unless $line =~ m/\"(.+)\" \"(.+)\"/;
        next unless $line =~ m/\"(.+)\" \"(.+)\"/;

        my $one=$1;
        my $two=$2;
        open (URLFILE, "<$locations/$two") or
            print STDERR "Could not open file $locations/$two\n";

                                $docid_to_file{"$directory_name-$file_name-$justified_document_ID"} = "$DOWNLOAD_PATH/$two";

        print CORPUSFILE "<DOC>\n";
        print CORPUSFILE
            "<DOCNO>" .
            "$directory_name-$file_name-$justified_document_ID" .
            "</DOCNO>\n";
        print CORPUSFILE "<DOCHDR>\n";
        print CORPUSFILE "$one\n";
        print CORPUSFILE "</DOCHDR>\n";
        print CORPUSFILE <URLFILE>;
        print CORPUSFILE "\n";
        close URLFILE;

        print CORPUSFILE "</DOC>\n";
        close CORPUSFILE;
    }
    close PAGES;

                dbmclose %docid_to_file;
    chdir $dir;
}

# mjschal adds a local copy of ale_normalize_url, local_normalize_url:
sub local_normalize_url
{
  local($_) = @_;

  if (defined $_) {
    s/\t/%09/g;
    s/\r/%0D/g;
    s/\n/%0A/g;
    s/\/index\.html$//;
    s/\/$//;

    /[\x00-\x1f\x7f-\xff]/ ? undef : $_;
  } else {
        return undef;
  }
}


# --------------------------------------------------------------
#  sub buildIdf (public) : build IDF
# --------------------------------------------------------------
sub buildIdf  {

   my $self = shift();

   my %args = @_;
   if ( defined $args{stemmed} )  {
       $self->{stemmed} = $args{stemmed};
   }
   if ( defined $args{punc} ) {
      $self->{punc} = $args{punc};
   }
   my $punc = $self->{punc};
   my $rootdir = $self->{rootdir};
   my $corpus = $self->{corpus};
   my $stemmed = $self->{stemmed};

   my $orig_dir = `pwd`;
   chomp $orig_dir;
   chdir("$rootdir");

   # -------------------------------------------------------
   # TFIDFUtils needs this set
   # -------------------------------------------------------
   $ENV{TFIDF_DIR} = "./corpus-data/$corpus";

   my $BASE_DIR = "./corpora/$corpus";
   my $tfidf_dir = "./corpus-data/$corpus";
   my %url_list;
   my $NAME = "$corpus";
   my $IDF_DBM_NAME = ( $stemmed ?
                        "$tfidf_dir/$NAME-idf-s" :
                        "$tfidf_dir/$NAME-idf");

   mkdir $BASE_DIR;
   opendir(DIR, $BASE_DIR) or die "Unable to open directory $BASE_DIR\n";
   my @subdirs = sort(grep /\d+/, readdir DIR);
   closedir DIR;

   my %df = ();
   my $num_docs = 0;
   my $num_err_docs = 0;

   open(OUT, ">$tfidf_dir/$corpus.build-idf.log");

   foreach my $subdir (@subdirs)  {

       my $dir = "$BASE_DIR/$subdir";
       next unless (-d $dir);
       print OUT "Processing $dir\n";

       opendir DIR, $dir or die "Cannot open directory $dir\n";
       my @files = sort(grep /\d+/, readdir DIR);
       closedir DIR;

       foreach my $file (@files) {

           $file = "$dir/$file";
           print OUT "\t$file ";
           my $doc = "";

           open FILE, $file or die;
           while (<FILE>) {
               chomp;
               $doc .= $_ . " ";

               if (m|</DOC>|) {
                    $doc =~ m|<DOC>.*?<DOCHDR>.*</DOCHDR>.*</DOC>| or warn
                      "warning: Improperly formatted document in $file\n";
                    next unless
                    $doc =~ m|<DOC>.*?<DOCHDR>.*(http:[^ ]*) .*</DOCHDR>(.*)</DOC>|;
                    my $url=$1;
                    chomp $url;
                    print OUT "On $url\n";
                    $url=local_normalize_url($url);
                    next if (defined $url_list{$url});
                    $url_list{$url}=1;

                    my $html = $2;

                    my $text = extract_text_from_html($html);
                    $text =~ s/&.*?;//g;

                    $self->process_document_text($text, \%df, $punc);
                    $doc = "";
                    $num_docs++;
               }
           }
           close FILE;
           print OUT "\n";
      }
      print OUT "\n";
   }
   print OUT "Building IDF DBM: $IDF_DBM_NAME\n";
   print OUT "Stemmed = $stemmed\n";

   my %idf;
   dbmopen %idf, $IDF_DBM_NAME, 0666 ||
       die "Unable to open database $IDF_DBM_NAME";
   %idf = ();

   my $LOG_2 = log(2);
   my $num_words = 0;

   # -------------------------------------------------------
   #  Create the idf hash
   # -------------------------------------------------------
   while ( my ($word, $df) = each %df ) {
       my @url_keys=keys %url_list;
       my $number_normalized_urls=$#url_keys+1;
       $idf{$word} = -log(1 - exp(-$df/$number_normalized_urls)) / $LOG_2;
       $num_words++;
       print OUT "." unless $num_words % 1000;
   }
   dbmclose %idf;

   print OUT "\n\n";
   print OUT "$num_words words\n";

   close(OUT);

   chdir($orig_dir);
}

# --------------------------------------------------------------
=head2 process_document_text

(private) split text into words and store words in hash

=cut

sub process_document_text  {

    my $self = shift;
    my $text = shift;
    my $dfref = shift;
    my $punc = shift;
    my $notuniq;

    unless(scalar(@_) == 0){
        $notuniq = shift;
    }
    else{
        $notuniq = 0;
    }

    my @words = split_words($text, $punc);
    @words = lc_words(@words);

    #premgane: we don't need this for tc
    unless($notuniq == 1){
        @words = uniq(@words);
   }


    if ( $self->{stemmed} )  {
        #mjschal was here, changing the stemming method
        my $stemmer = Lingua::Stem->new(-locale => 'EN-US');
        $stemmer->stem_caching({-level => 2});
        my $s_words = $stemmer->stem(@words);
        @words = grep(/./,@$s_words);
    }

    # update the %df hash.
    foreach my $w (@words) {
        $w =~ s/\s+//g;
        next if $w eq '';
        if (exists $dfref->{$w}) {
            $dfref->{$w}++;
        } else {
            $dfref->{$w} = 1;
        }
    }

    # print ".";
    # Return the document length
    return scalar(@words);
}

# --------------------------------------------------------------
#  Global variable used by all Tf subroutines
# --------------------------------------------------------------
my %batch = ();
# --------------------------------------------------------------


# --------------------------------------------------------------
#  sub buildTf (public) : build TF
# --------------------------------------------------------------
sub buildTf  {

   my $self = shift();

   my %args = @_;
   if ( defined $args{stemmed} )  {
       $self->{stemmed} = $args{stemmed};
   }
   if ( defined $args{punc} ) {
      $self->{punc} = $args{punc};
   }
   my $punc = $self->{punc};
   my $rootdir = $self->{rootdir};
   my $corpus = $self->{corpus};
   my $stemmed = $self->{stemmed};

   my $orig_dir = `pwd`;
   chomp($orig_dir);

   chdir("$rootdir");

   print "Building TF...\n";

   # -------------------------------------------------------
   # TFIDFUtils needs this set
   # -------------------------------------------------------
   $ENV{TFIDF_DIR} = "./corpus-data/$corpus";

   my $BASE_DIR = "./corpora/$corpus";
   my $TF_BASE_DIR = ( $stemmed ?
                       "./corpus-data/$corpus-tf-s" :
                       "./corpus-data/$corpus-tf");

   # -------------------------------------------------------
   #  Note:  this is to prevent multiple entries from
   #  multiple builds.
   # -------------------------------------------------------
   if (-d $TF_BASE_DIR)  {
       system("rm -rf $TF_BASE_DIR");
   }
   mkdir $TF_BASE_DIR;

   opendir DIR, $BASE_DIR or die "Unable to open directory $BASE_DIR\n";
   my @subdirs = sort(grep /\d+/, readdir DIR);
   closedir DIR;

   open(OUT, ">./corpus-data/$corpus/$corpus.build-tf.log");

   foreach my $subdir (@subdirs) {

       my $dir = "$BASE_DIR/$subdir";
       print OUT "Processing $dir\n";

       opendir DIR, $dir or die;
       my @files = sort(grep /\d+/, readdir DIR);
       closedir DIR;

       foreach my $file (@files) {

           $file = "$dir/$file";
           print OUT "\t$file ";
           my $doc = "";

           open BFILE, $file or die;
           if ($verbose) { print STDERR "Parsing $file\n"; }
           while (<BFILE>)   {
               chomp;
               $doc .= $_ . " ";

               if (m|</DOC>|) {

                  if ($doc =~ m|<DOC> <DOCNO>(.*?)</DOCNO>.*?</DOCHDR>(.*)</DOC>|) {

                  my $docno = $1;
                  my $html = $2;
                  my $text = extract_text_from_html($html);
                  $self->process_document($docno, $text, $punc);
                  $doc = "";
                  } else {
                          warn "warning: Document does not match expected pattern\n";
                        next;
                  }
              }
          }
          if ($verbose) { print STDERR "Done parsing $file\n"; }
          close BFILE;
          print OUT "\n";
          if ($verbose) { print STDERR "Batch processing\n"; }
          $self->process_batch();
          print OUT "\n";
       }
    }
    chdir($orig_dir);
}

# --------------------------------------------------------------
#  sub process_document (private)
# --------------------------------------------------------------
sub process_document {

    my $self = shift;
    my $docno = shift;
    my $text = shift;
    my $punc = shift;

    my @words = split_words($text, $punc);
    @words = lc_words(@words);
    if ( $self->{stemmed} ) {
        #mjschal was here, changing the stemming method
        my $stemmer = Lingua::Stem->new(-locale => 'EN-US');
        $stemmer->stem_caching({-level => 2});
        my $s_words = $stemmer->stem(@words);
        @words = grep(/./,@$s_words);
    }
    my %count = count_hash(@words);
    my %position = position_hash(@words);

    # update the tf files.
    while (my ($w, $c) = each %count) {
        $self->queue_tf_entry($w, $docno, $c, $position{$w});
    }

    # print ".";
}


# --------------------------------------------------------------
#  sub queue_tf_entry (private)
# --------------------------------------------------------------
sub queue_tf_entry {

    my $self = shift();
    my ($word, $docno, $count, $positionsRef) = @_;

    unless (exists $batch{$word}) {
        $batch{$word} = {};
    }
    $batch{$word}->{$docno}->{count} = $count;
    $batch{$word}->{$docno}->{positions} = $positionsRef;
}


# --------------------------------------------------------------
#  sub process_batch (private) : write files for all
#  words currently in %batch hash.
# --------------------------------------------------------------
sub process_batch {

    my $self = shift();

    if ($verbose) { print STDERR "\tUpdating TF files\n"; }
    my $num = 0;
    my @words = sort keys %batch;

    foreach my $w (@words) {
        $self->add_tf_entries($w, $batch{$w});
        # print "." unless ++$num % 100;
    }

    # print " ($num word TF files updated)";

    %batch = ();
    # undef %batch;
}

# --------------------------------------------------------------
#  sub add_tf_entries (private) : create file for $word
# --------------------------------------------------------------
sub add_tf_entries {
    my $self = shift();
    my $rootdir = $self->{rootdir};
    my $corpus = $self->{corpus};
    my $stemmed = $self->{stemmed};

    my $word = shift();
    my $countpos_ref = shift();
    my $dir;

    # this is a workaround for the fact that as_text() doesn't insert
    # spaces where stuff is.
    if (length $word > 50) {
        print STDERR "\nOverlong word '$word' encountered.  Skipping...\n";
        return;
    }

    if (length $word == 1) {
        $dir = ($stemmed ?
                "./corpus-data/$corpus-tf-s/$word" :
                "./corpus-data/$corpus-tf/$word");

    } else {
        my $dir1 = substr $word, 0, 1;
        my $dir2 = substr $word, 0, 2;
        $dir = ($stemmed ?
                "./corpus-data/$corpus-tf-s/$dir1/$dir2" :
                "./corpus-data/$corpus-tf/$dir1/$dir2");

    }

    # make sure the directory exists.
    mkpath $dir unless -d $dir;

    my $file = "$dir/$word.tf";

    open TFFILE, ">> $file" or
        die "Unable to open file '$file'";

    # PHRASE INDEXING!!!
    foreach my $docno (sort keys %$countpos_ref) {
        my $id = compress_docid($docno, $corpus);
        my @positions = map (base10_to_base36($_), sort @{$countpos_ref->{$docno}->{positions}});
        print TFFILE "$id $countpos_ref->{$docno}->{count} " . join(" ", @positions) . "\n";
    }
    close TFFILE;
}


# --------------------------------------------------------------
#  sub build_docno_dbm (public) : build expansion and
#  compression dbms for DOCNOs, and the DOCNO-to-URL
#  and URL-to-DOCNO dbms.
# --------------------------------------------------------------
sub build_docno_dbm  {

   my $self = shift();
   my $rootdir = $self->{rootdir};
   my $corpus = $self->{corpus};
   print "Building docno-to-URL database...\n";

   # -------------------------------------------------------
   #  alecanonurl needs this set
   # -------------------------------------------------------
   my $currdir = `pwd`;
   chomp($currdir);
   $ENV{ALECACHE} = "$currdir";

   # -------------------------------------------------------
   #  TFIDFUtils need this set
   # -------------------------------------------------------
   $ENV{TFIDF_DIR} = "./corpus-data/$corpus";

   chdir("$rootdir");
   my $BASE_DIR = "./corpora/$corpus";
   my $COMPRESS_DBM_NAME = "./corpus-data/$corpus/$corpus-compress-docid";
   my $EXPAND_DBM_NAME   = "./corpus-data/$corpus/$corpus-expand-docid";
   my $TO_URL_DBM_NAME   = "./corpus-data/$corpus/$corpus-docid-to-url";
   my $FROM_URL_DBM_NAME = "./corpus-data/$corpus/$corpus-url-to-docid";

   opendir DIR, $BASE_DIR or die "Unable to open directory $BASE_DIR\n";
   my @subdirs = sort(grep /\d+/, readdir DIR);
   closedir DIR;

   my @docids = ();
   my @urls = ();

   foreach my $subdir (@subdirs) {
       my $dir = "$BASE_DIR/$subdir";
       opendir DIR, $dir or die;
       my @files = sort grep /\d+/, readdir DIR;
       closedir DIR;

       foreach my $file (@files) {

           $file = "$dir/$file";
           if ($verbose) { print STDERR "Processing $file\n"; }
           my $next_has_url = 0;
           open FILE, $file or die;

           while (<FILE>) {
               chomp;

               if (m|<DOCNO>(...-..-......)</DOCNO>|) {
                   push @docids, $1;
               } elsif (m|<DOCHDR>|) {
                   $next_has_url = 1;
               } elsif ($next_has_url) {
#                   m|^(http\://[^\s]+)| or die "$_\n";
                   m|^(http[s]?\://[^\s]+)| or die "$_\n";
                   my $url = $1;
                   my $save_url = $url;

                   # NEW! convert the url to wget canonical form.
                   # $url = alecanonurl($url);

                   # alecanonurl complains if there are illegal characters,
                   # so if it does (and this is only about 10 times total for
                   # wt2g), just use the original (non-canonicalized) url.
                   unless (defined $url) {
                       print "\n\tBAD: $save_url";
                       $url = $save_url;
                   }

                   push @urls, $url;
                   $next_has_url = 0;
               }
           }
           close FILE;
           print "\n";
       }
       print "\n";
   }

   print scalar(@docids), " docids\n";
   print scalar(@urls), " urls ";
   print "(", scalar(uniq(@urls)), " unique)\n";

   die "Unequal numbers of docids and urls" unless
       (scalar @urls) == (scalar @docids);

   # -------------------------------------------------------------------
   # NOTE: I removed the expand/compress stuff because I didn't need to rebuild
   # them.  Just uncomment all commanted lines below to rebuild them too.
   # -------------------------------------------------------------------

   my %compress = ();
   dbmopen %compress, $COMPRESS_DBM_NAME, 0666 or
       die "Can't open '$COMPRESS_DBM_NAME'";
   %compress = ();

   my %expand = ();
   dbmopen %expand, $EXPAND_DBM_NAME, 0666 or
       die "Can't open '$EXPAND_DBM_NAME'";
   %expand = ();

   my %to_urls = ();
   dbmopen %to_urls, $TO_URL_DBM_NAME, 0666 or
      die "Can't open '$TO_URL_DBM_NAME'";
   %to_urls = ();

   my %from_urls = ();
   dbmopen %from_urls, $FROM_URL_DBM_NAME, 0666 or
      die "Can't open '$FROM_URL_DBM_NAME'";
   %from_urls = ();

   my $count;
   for ($count = 0; $count < @docids; $count++) {
       my $docid = $docids[$count];
       my $url = $urls[$count];
       my $comp = base10_to_base36($count+1);

       $compress{$docid} = $comp;
       $expand{$comp} = $docid;

       # NEW! print an error message if we have a collision.
       if ($from_urls{$url}) {
           print "\nCOLLISION: '$from_urls{$url}' and '$docid' both point to:\n";
           print "\t$url\n";
       }

       $to_urls{$docid} = $url;
       $from_urls{$url} = $docid;

       if ($verbose) { print STDERR "." unless $count % 100; }
   }

   print "\n";
   print "$count documents\n";
   print scalar(keys(%compress)), " keys in the docid compression dbm\n";
   print scalar(keys(%expand)), " keys in the docid expansion dbm\n";
   print scalar(keys(%to_urls)), " keys in the docid to url dbm\n";
   print scalar(keys(%from_urls)), " keys in the url to docid dbm\n";

   print "docno length: ", length($docids[0]), "\n";
   print "max id length: ", length(base10_to_base36($count)), "\n";

   #warn unless scalar keys %compress == $count;
   #warn unless scalar keys %expand == $count;
   #warn unless scalar keys %to_urls == $count;
   #warn unless scalar keys %from_urls == $count;

   dbmclose %compress;
   dbmclose %expand;
   dbmclose %to_urls;
   dbmclose %from_urls;

   chdir($currdir);
}

sub write_links  {
        my $self = shift;
        my %args = @_;

        my $rootdir = $self->{rootdir};
        my $corpus = $self->{corpus};

        my %urltoid;
        my $fn = "$rootdir/corpus-data/$corpus/$corpus-url-to-docid";
        dbmopen %urltoid, $fn,
          0666 or print STDERR "Error opening docid dbm file: $fn.\n";

        my $linkfile = "$rootdir/corpus-data/$corpus/$corpus.links";
        if (exists $args{filename}) {
                $linkfile = $args{filename};
        }

        open (LINKS, "> $linkfile");

        # my $indexer = ALE::Index->new()
        #   or die "Error creating new indexer: $!\n";

        # if (exists $args{drop_tables} and $args{drop_tables} == 1)
        # {
        #         $indexer->drop_tables();
        # }
        # $indexer->create_tables();

        # Get the names of the files in the corpus
        my @corpus_files = `find '$rootdir/corpora/$corpus' -name '??' -print`;

        use constant    STATE_BEFOREDOC => 0;
        use constant    STATE_BEFOREHDR => 1;
        use constant        STATE_INHDR => 2;
        use constant      STATE_SKIPHDR => 3;
        use constant STATE_BEFOREHDREND => 4;
        use constant       STATE_INBODY => 5;

        use vars qw($state $contents $url);
        $state=STATE_BEFOREDOC;

        foreach my $file (@corpus_files) {
                chomp $file;

                my @text = `cat '$file' 2>/dev/null`;
                foreach my $line (@text) {
                        $_ = $line;
                        if (($state == STATE_BEFOREDOC) && (/^<DOC>\s*$/))
                        {
                                $state = STATE_BEFOREHDR;
                        }
                        elsif (($state == STATE_BEFOREHDR) && (/^<DOCHDR>\s*$/))
                        {
                                $state = STATE_INHDR;
                        }
                        elsif ($state == STATE_INHDR)
                        {
                                chomp($url=$_);
                                warn " Warning: Problem with url: $url\n" unless $url =~ m!(http:[^ ]*)!;
                                $url=$1;
                                $state = STATE_SKIPHDR;
                        }
                        elsif (($state == STATE_SKIPHDR) && (/^<\/DOCHDR>\s*$/))
                        {
                                $contents = "";
                                $state = STATE_INBODY;
                        }
                        elsif (($state == 1) && (/^<\/DOCHDR>\s*$/))
                        {
                                $contents="";
                                $state=2;
                        }
                        elsif ($state == STATE_INBODY)
                        {
                                if (/^<\/DOC>\s*$/)
                                {
                                        # addlinks($url,\$contents, \%urltoid, $indexer);
                                        addlinks($url,\$contents, \%urltoid);
                                        $state = STATE_BEFOREDOC;
                                }
                                else
                                {
                                        $contents .= $_;
                                }
                        }
                }
        }

        close LINKS;
        dbmclose %urltoid;
}

sub addlinks
{
  # my($url,$contents, $utoid, $indexer) = @_;
  my($url,$contents, $utoid) = @_;
        my %urltoid = %$utoid;

  $url = local_normalize_url($url);

  # $indexer->clearurl($url);
  my $lx = HTML::LinkExtractor->new(undef,$url)
    or die "Error creating LinkExtractor: $!\n";
  $lx->strip(1);
  $lx->parse($contents);

  foreach my $l (@{$lx->links()})
  {
    my($type,$text,$href);

    if ($$l{tag} eq 'a')
    {
      ($type,$text,$href)=($$l{tag},$$l{_TEXT},$$l{href});
    }
    else
    {
      next;
    }

$href=local_normalize_url($href);
# print "$url -> $href\n";


    # if (!$indexer->foundlink($url,$type,$text,$href))
    # {
    #   return undef;

    # }
    # else
    # {
      if((defined $urltoid{$url}) && (defined $urltoid{$href}))
      { print LINKS "$urltoid{$url} $urltoid{$href}\n";}
      elsif (defined $urltoid{$url} )
      { print LINKS "$urltoid{$url} EX\n";}
      elsif (defined $urltoid{$href} )
      { print LINKS "EX $urltoid{$href}\n";}
      else
      {
        print LINKS "EX EX\n";
      }
    # }
  }

  # $indexer->completeurl($url);

#  print "PID $$ FILE $ARGV URL $url\n";
}

# Reads a list of urls from a file (each url on its own line)
# Returns a reference to the array of urls
sub readUrlsFile {
        my $self = shift;

        my $filename = shift;
        my @urls;

        open (URLS, "< $filename");

        while (<URLS>) {
                chomp($_);
                push(@urls, $_);
        }

        return \@urls;
}

=head2 build_term_counts

token_counts

Returns an array of term counts in the corpus

This is used by the synth corpus tools

=cut

sub build_term_counts {
  my $self = shift;

  my %args = @_;
  if ( defined $args{stemmed} ) {
    $self->{stemmed} = $args{stemmed};
  }

  my $rootdir = $self->{rootdir};
  my $corpus = $self->{corpus};
  my $stemmed = $self->{stemmed};

  my $orig_dir = `pwd`;
  chomp $orig_dir;

  chdir("$rootdir");

  # -------------------------------------------------------
  # TFIDFUtils needs this set
  # -------------------------------------------------------
  $ENV{TFIDF_DIR} = "./corpus-data/$corpus";

  my $BASE_DIR = "./corpora/$corpus";
  my $tfidf_dir = "./corpus-data/$corpus";
  my %url_list;
  my $NAME = "$corpus";
  my $IDF_DBM_NAME = ( $stemmed ?
                       "$tfidf_dir/$NAME-tc-s" :
                       "$tfidf_dir/$NAME-tc");

  mkdir $BASE_DIR;
  opendir(DIR, $BASE_DIR) or die "Unable to open directory $BASE_DIR\n";
  my @subdirs = sort(grep /\d+/, readdir DIR);
  closedir DIR;

  my %df = ();
  my $num_docs = 0;
  my $num_err_docs = 0;

  open(OUT, ">$tfidf_dir/$corpus.build-tc.log");

  foreach my $subdir (@subdirs) {
    my $dir = "$BASE_DIR/$subdir";
    next unless (-d $dir);
    print OUT "Processing $dir\n";
    opendir DIR, $dir or die "Cannot open directory $dir\n";
    my @files = sort(grep /\d+/, readdir DIR);
    closedir DIR;

    foreach my $file (@files) {

      $file = "$dir/$file";
      print OUT "\t$file ";
      my $doc = "";

      open FILE, $file or die;
      while (<FILE>) {
        chomp;
        $doc .= $_ . " ";

        if (m|</DOC>|) {
          $doc =~ m|<DOC>.*?<DOCHDR>.*</DOCHDR>.*</DOC>| or warn
            "Warning: Improperly formatted document in $file\n";
          next unless
            $doc =~ m|<DOC>.*?<DOCHDR>.*(http:[^ ]*) .*</DOCHDR>(.*)</DOC>|;
          my $url=$1;
          chomp $url;
          print OUT "On $url\n";
          $url=local_normalize_url($url);
          next if (defined $url_list{$url});
          $url_list{$url}=1;

          my $html = $2;

          my $text = extract_text_from_html($html);
          $text =~ s/&.*?;//g;

          my $count = $self->process_document_text($text, \%df, undef, 1);
          $doc = "";
          $num_docs++;
        }
      }
      close FILE;
      print OUT "\n";
    }
    print OUT "\n";
  }
  print OUT "Building IDF DBM: $IDF_DBM_NAME\n";
  print OUT "Stemmed = $stemmed\n";

  my %idf;
  dbmopen %idf, $IDF_DBM_NAME, 0666 ||
    die "Unable to open database $IDF_DBM_NAME";
  %idf = ();

  my $LOG_2 = log(2);
  my $num_words = 0;

  # -------------------------------------------------------
  #  Create the idf hash
  # -------------------------------------------------------
  my @url_keys = keys %url_list;
  my $number_normalized_urls = $#url_keys+1;
  while ( my ($word, $df) = each %df ) {
    $idf{$word} = $df;
    $num_words++;
    print OUT "." unless $num_words % 1000;
  }
  dbmclose %idf;

  print OUT "\n\n";
  print OUT "$num_words words\n";
  print OUT "$number_normalized_urls number_normalized_urls\n";

  close(OUT);

  chdir($orig_dir);
}


=head2 build_doc_len_dist

build_doc_len_dist

Build the document length file

=cut

sub build_doc_len {
  my $self = shift;

  my %args = @_;
  if ( defined $args{stemmed} ) {
    $self->{stemmed} = $args{stemmed};
  }

  my $rootdir = $self->{rootdir};
  my $corpus = $self->{corpus};
  my $stemmed = $self->{stemmed};

  my $orig_dir = `pwd`;
  chomp $orig_dir;
  chdir("$rootdir");

  # -------------------------------------------------------
  # TFIDFUtils needs this set
  # -------------------------------------------------------
  $ENV{TFIDF_DIR} = "./corpus-data/$corpus";

  my $BASE_DIR = "./corpora/$corpus";
  my $tfidf_dir = "./corpus-data/$corpus";
  my %url_list;
  my $NAME = "$corpus";
  my $DOCLEN_DBM_NAME = ( $stemmed ?
                       "$tfidf_dir/$NAME-doclen-s" :
                       "$tfidf_dir/$NAME-doclen");

  mkdir $BASE_DIR;
  opendir(DIR, $BASE_DIR) or die "Unable to open directory $BASE_DIR\n";
  my @subdirs = sort(grep /\d+/, readdir DIR);
  closedir DIR;

  my %df = ();
  my $num_docs = 0;
  my $num_err_docs = 0;

  open(OUT, ">$tfidf_dir/$corpus.build-doclen.log");

  print OUT "Building DOCLEN DBM: $DOCLEN_DBM_NAME\n";
  print OUT "Stemmed = $stemmed\n";

  my %doclen;
  dbmopen %doclen, $DOCLEN_DBM_NAME, 0666 ||
    die "Unable to open database $DOCLEN_DBM_NAME";
  %doclen = ();

  foreach my $subdir (@subdirs) {
    my $dir = "$BASE_DIR/$subdir";
    next unless (-d $dir);
    print OUT "Processing $dir\n";
    opendir DIR, $dir or die "Cannot open directory $dir\n";
    my @files = sort(grep /\d+/, readdir DIR);
    closedir DIR;

    foreach my $file (@files) {
      $file = "$dir/$file";
      print OUT "\t$file ";
      my $doc = "";

      open FILE, $file or die;
      while (<FILE>) {
        chomp;
        $doc .= $_ . " ";

        if (m|</DOC>|) {
          $doc =~ m|<DOC>.*?<DOCNO>.*</DOCNO>.*<DOCHDR>.*</DOCHDR>.*</DOC>| or warn
            "Warning: Improperly formatted document in $file\n";
          next unless
            $doc =~ m|<DOC>.*?<DOCNO>(.*)</DOCNO>.*<DOCHDR>.*(http:[^ ]*) .*</DOCHDR>(.*)</DOC>|;
          my $docid=$1;
          chomp $docid;
          print OUT "On $docid\n";
#          $docid=ale_normalize_docid($url);
          next if (defined $url_list{$docid});
          $url_list{$docid}=1;

          my $html = $3;

          my $text = extract_text_from_html($html);
          $text =~ s/&.*?;//g;

          my $count = $self->process_document_text($text, \%df);
          $doclen{$docid} = $count;
          $doc = "";
          $num_docs++;
        }
      }
      close FILE;
      print OUT "\n";
    }
    print OUT "\n";
  }

  dbmclose %doclen;

  close(OUT);

  chdir($orig_dir);
}

=head2 get_doc_len_dist

get_doc_len_dist()

Gets the document length distribution.  Returns a hash with each key
being a document length, and the values being the number of documents with
that length

=cut

sub get_doc_len_dist() {
  my $self = shift;

  my %args = @_;
  if ( defined $args{stemmed} ) {
    $self->{stemmed} = $args{stemmed};
  }

  my $rootdir = $self->{rootdir};
  my $corpus = $self->{corpus};
  my $stemmed = $self->{stemmed};

  my $orig_dir = `pwd`;
  chomp $orig_dir;
  chdir("$rootdir");

  # -------------------------------------------------------
  # TFIDFUtils needs this set
  # -------------------------------------------------------
  $ENV{TFIDF_DIR} = "./corpus-data/$corpus";

  my $BASE_DIR = "./corpora/$corpus";
  my $tfidf_dir = "./corpus-data/$corpus";
  my %url_list;
  my $NAME = "$corpus";
  my $DOCLEN_DBM_NAME = ( $stemmed ?
                       "$tfidf_dir/$NAME-doclen-s" :
                       "$tfidf_dir/$NAME-doclen");

  my %doclen;
  dbmopen %doclen, $DOCLEN_DBM_NAME, 0666 ||
    die "Unable to open database $DOCLEN_DBM_NAME";

  my %hash = ();
  my $oldlen = -1;

  foreach my $k (sort {$doclen{$a} cmp $doclen{$b}} keys %doclen) {
    my $len = $doclen{$k};
    if ($oldlen == $len) {
      # duplicate document length
      $hash{$len}++;
    } else {
      $hash{$len} = 1;
    }
    $oldlen = $len;
  }

  dbmclose %doclen;

  chdir($orig_dir);

  return %hash;
}

=head2 get_term_counts

get_term_counts()

Gets the term counts.  Returns a hash with each key being a term/token
and the corresponding value the number of occurences of that term in the
collection.

=cut

sub get_term_counts() {
  my $self = shift;

  my %args = @_;
  if ( defined $args{stemmed} ) {
    $self->{stemmed} = $args{stemmed};
  }

  my $rootdir = $self->{rootdir};
  my $corpus = $self->{corpus};
  my $stemmed = $self->{stemmed};

  my $orig_dir = `pwd`;
  chomp $orig_dir;
  chdir("$rootdir");

  # -------------------------------------------------------
  # TFIDFUtils needs this set
  # -------------------------------------------------------
  $ENV{TFIDF_DIR} = "./corpus-data/$corpus";

  my $BASE_DIR = "./corpora/$corpus";
  my $tfidf_dir = "./corpus-data/$corpus";
  my %url_list;
  my $NAME = "$corpus";
  my $TC_DBM_NAME = ( $stemmed ?
                       "$tfidf_dir/$NAME-tc-s" :
                       "$tfidf_dir/$NAME-tc");

  my %tc;
  dbmopen %tc, $TC_DBM_NAME, 0666 ||
    die "Unable to open database $TC_DBM_NAME";

  my %hash = ();
  my $oldlen = -1;

  foreach my $k (keys %tc) {
    $hash{$k} = $tc{$k};
  }

  dbmclose %tc;

  chdir($orig_dir);

  return %hash;
}



1;
