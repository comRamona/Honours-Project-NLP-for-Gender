package Clair::Utils::Idf;

use strict;

use File::Spec;
#use ALE::Stemmer qw(ale_stemsome);
use Lingua::Stem;
use Clair::Config;

#--------------------------------------------------------------
=pod

=head1 NAME

Idf

=head1 SYNOPSIS

    $idfref = Idf->new("myidf");
    my $val = $idf->getIdfForWord($word);

=head1 DESCRIPTION

The IDF object is an open database.  Once the constructor
is called, the database remains open until the reference
($idfref) goes out of scope.  At that point, the database
is closed automatically.

The point is that when the IDF is opened, a significant portion
of database is read into a hash.  The Idf object makes it
possible to access the IDF multiple times without rereading the
hash.

=head1 METHODS

=head2 new

$idfref = Idf->new($rootdir, $corpusname);

Opens IDF database

=head2 getIdfForWord

getIdfForWord($word)

Returns IDF value for word or 3 if word is not found

=head2 DESTROY

(called automatically) Closes IDF database

=cut


sub new  {
   my $class = shift;
   my %args = @_;

   my $rootdir = "/data0/projects/tfidf";
   if ( $args{rootdir} )  {
      $rootdir = $args{rootdir};
   }

   if ( ! $args{corpusname} )  {
      print "Corpus name must be specified\n";
      return;
   }
   my $corpusname = $args{corpusname};

   my $stemmed =  ( defined $args{stemmed} ? $args{stemmed} : 0 );

   my %idf;
   my $dbmname = ( $stemmed ?
       "$rootdir/corpus-data/$corpusname/$corpusname-idf-s" :
       "$rootdir/corpus-data/$corpusname/$corpusname-idf");

   dbmopen %idf, $dbmname, 0666 or
       die "Can't open idf:  $dbmname\n";

   my %self = ('rootdir' => $rootdir,
               'corpusname'  => $corpusname,
               'stemmed'  => $stemmed,
               'idfref' => \%idf );

   bless (\%self, $class);
   return (\%self);

}

sub getIdfForWord {

  my $self = shift();
  my $word = shift();
  my $idfref = $self->{idfref};

  if ( $self->{stemmed} )  {
     my $stemmer = Lingua::Stem->new(-locale => 'EN-US');
     $stemmer->stem_caching({-level => 2});
     my @temp0 = ();
     push (@temp0,$word);
#     @temp1 = ale_stemsome(@temp0);
     my $temp1 = $stemmer->stem(@temp0);
     $word = pop(@$temp1);
  }

  if (defined $idfref->{$word})  {
    return $idfref->{$word};
  }
  return $DEFAULT_UNKNOWN_IDF;

}

=head2 getIdfs

getIdf()

Returns all the IDF values as a hash of word -> value

=cut

sub getIdfs {
  my $self = shift();
  my $word = shift();
  my $idfref = $self->{idfref};

  my %idfs = ();
  foreach my $k (keys %{$idfref}) {
    $idfs{$k} = $idfref->{$k};
  }

  return %idfs;
}


sub DESTROY  {
  my $self = shift();
  dbmclose %{$self->{idfref}};
}

1;
