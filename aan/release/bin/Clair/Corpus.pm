package Clair::Corpus;

use DB_File;


=pod

=head1 NAME

Clair::Corpus - Class for dealing with TREC corpus format data

=head1 SYNOPSIS

Clair::Corpus

=head1 DESCRIPTION

This module loads and stores TREC format corpuses.  It also contains
functions for indexing the corpus.

=head1 METHODS

=head2 new

$cref = Corpus::new(rootdir => "/path/to/project", corpusname = "uiuc");

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

=cut

sub new  {
  my $class = shift;

  my %args = @_;
  my $usedocno = 1;  
  
  my $stemmed = (defined $args{stemmed} ? $args{stemmed} : 0);
  my $rootdir = (defined $args{rootdir} ? $args{rootdir} : 
                 "/data0/projects/tfidf");
  my $corpus = $args{corpusname};

  my $self = {rootdir => $rootdir, corpus => $corpus};

  bless($self, $class);

  return $self;
}

=head2 get_term_counts

Returns a hash table of terms and term counts (frequencies) 

=cut

sub get_term_counts {
  my $self = shift;

  my %args = @_;
  if ( defined $args{stemmed} ) {
    $self->{stemmed} = $args{stemmed};
  }

  my $rootdir = $self->{rootdir};
  my $corpus = $self->{corpus};
  my $stemmed = $self->{stemmed};
  my $base_dir = "$rootdir/corpus-data/$corpus";
  print "$base_dir\n";
  my $tc_fname = ($stemmed ? 
                  "$base_dir/$corpus-tc-s" : "$base_dir/$corpus-tc");

  my %freq = ();
  my %tf;

  dbmopen %tf, $tc_fname, 0666 or die "Couldn't open $tc_fname: $!\n";
  foreach my $term (keys %tf) {
    $freq{$term} = $tf{$term};
  }
  dbmclose %tf;

  return %freq;
}

=head2 get_name

Returns the name of the corpus

=cut

sub get_name {
  my $self = shift;

  return $self->{corpus};
}

=head2 get_directory

Returns the base directory the corpus is in

=cut

sub get_directory {
  my $self = shift;

  return $self->{rootdir};
}

1;
