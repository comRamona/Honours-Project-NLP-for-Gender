use strict;

package Clair::ALE::Wget::Hash;

use Exporter;
use vars qw(@ISA @EXPORT_OK);
@ISA=qw(Exporter);

use Clair::Utils::ALE;
use FileHandle;

sub new
{
  my $class=shift;
  my($topdir)=@_;
  my $self = {};
  
  if (! -d $topdir)
  {
    die "Clair::ALE::Wget::Hash - No such directory '$topdir'!\n";
  }
  $self->{topdir}=$topdir;
  if ( -f "$topdir/.hash")
  {
    my $f = FileHandle->new("< $topdir/.hash")
      or die "Error opening '$topdir/.hash': $!\n";
    my $l = <$f>;
    close $f
      or die "Error closing '$topdir/.hash': $!\n";
    chomp($l);
    my($family,$type)=split(' ',$l);
    if ($family eq 'wget')
    {
      if (!defined($type))
      {
	$type = 2;
      }
      if ( ($type > 0) && ($type <= 4) )
      {
	$self->{hashfunc}=make_wget_hashdir($type);
	$self->{unhashfunc}=make_wget_unhashdir($type,$topdir);
      }
      else
      {
	die "wget must have 1-4 levels!\n";
      }
    }
    else
    {
      die "Unknown hash family '$family'!\n";
    }
  }
  else
  {
    $self->{hashfunc}=\&nohash;
    $self->{unhashfunc}=\&nounhash;
  }
  
  bless $self,$class;
}

sub hash
{
  my $self = shift;
  return &{$self->{hashfunc}}(@_);
}

sub unhash
{
  my $self = shift; 
  return &{$self->{unhashfunc}}(@_);
}

sub nohash
{
  return '';
}

sub nounhash
{
  return $_[0];
}

sub make_wget_unhashdir
{
  my($levels,$topdir) = @_;

  if ( !defined($levels) || ($levels < 1) || ($levels > 4) )
  {
    die "wget_unhashdir must have 1-4 levels!\n";
  }
  
  return sub
  {
    my $s = shift;
    my $top;

    if ($s =~ s/^(\.\/)//)
    {
      $top = $1;
    }
    elsif ($s =~ s/^($topdir\/)//)
    {
      $top = $1;
    }
    else
    {
      die "Clair::ALE::Wget::Hash - File '$s' was in unrecognized subdirectory\n";
    }

    for(my $i=0;$i<$levels;$i++)
    {
      $s =~ s/^[^\/]+\///;
    }

    return $top.$s;
  }
}

use vars qw($WGET_HASH_MAX);
$WGET_HASH_MAX = 4294967296;

sub make_wget_hashdir
{
  my($levels) = @_;

  if ( !defined($levels) || ($levels < 1) || ($levels > 4) )
  {
    die "wget_hashdir must have 1-4 levels!\n";
  }
  
  return sub
  {
    my $s = shift;
    my $h;
    my $hd;
    
    $h = ord(substr($s,0,1));
    
    for(my $i=1;$i<length($s);$i++)
    {
      $h = (($h << 5) - $h + ord(substr($s,$i,1))) % $WGET_HASH_MAX;
    }
    
    $hd = "";
    for(my $i=0;$i<$levels;$i++)
    {
      $hd .= sprintf("%02x/",$h % 256);
      $h >>= 8;
    }
    
    return $hd;
  }
}

1;
