package Clair::ALE::Wget;

use strict;

use Exporter;
use vars qw(@ISA @EXPORT_OK);
@ISA=qw(Exporter);
@EXPORT_OK=qw(aleurl2file alefile2url aleurls2files alefiles2urls alecanonurl);

use Clair::Utils::ALE;
use Clair::Utils::ALE qw(%ALE_ENV);
use Clair::ALE::Wget::Hash;
use URI::Escape;

use vars qw(%dirhasher);
sub aleurl2file
{
  local($_)=@_;
  my($prot,$host,$path);
  my $hasher;

  if ($dirhasher{$ALE_ENV{ALECACHE}})
  {
    $hasher = $dirhasher{$ALE_ENV{ALECACHE}};
  }
  else
  {
    $hasher = $dirhasher{$ALE_ENV{ALECACHE}} = Clair::ALE::Wget::Hash->new($ALE_ENV{ALECACHE});
  }
  
  unless (($prot,$host,$path) = m|^([^:]+)://([^/]+)/?([^\x00-\x1f\x7f-\xff]*)?$|)
  {
    warn "Invalid URL in aleurl2file: Couldn't parse URL.\n";
    return undef;
  }
  if (!defined($path))
  {
    $path='';
  }
  
  if ($prot ne 'http')
  {
    warn "Invalid URL in aleurl2file: Only http protocol is recognized.\n";
    return undef;
  }
  $host =~ s/:80$//;
  $_ = join('/',$ALE_ENV{ALECACHE},$hasher->hash($host),$host,uri_escape($path,"\x00-\x1f\x7f-\xff\x20\"\<\>\@\[\\\]\^\`\{\|\}\~\%"));
  s|/$||;
  $_;
}

sub alecanonurl
{
  local($_)=@_;
  my($prot,$host,$path);
  
  unless (($prot,$host,$path) = m|^([^:]+)://([^/]+)/?([^\x00-\x1f\x7f-\xff]*)?$|)
  {
    warn "Invalid URL in aleurl2file: Couldn't parse URL.\n";
    return undef;
  }
  if (!defined($path))
  {
    $path='';
  }
  
  if ($prot ne 'http')
  {
    warn "Invalid URL in aleurl2file: Only http protocol is recognized.\n";
    return undef;
  }
  $host =~ s/:80$//;
  $path=uri_escape($path,"\x00-\x1f\x7f-\xff\x20\"\<\>\@\[\\\]\^\`\{\|\}\~\%");
  $_ = "${prot}://$host/$path";
  s|/$||;
  if ( -d aleurl2file($_) ) { $_ .= "/index.html" };
  $_;
}


sub alefile2url
{
  local($_)=@_;
  my $hasher;

  if ($dirhasher{$ALE_ENV{ALECACHE}})
  {
    $hasher = $dirhasher{$ALE_ENV{ALECACHE}};
  }
  else
  {
    $hasher = $dirhasher{$ALE_ENV{ALECACHE}} = Clair::ALE::Wget::Hash->new($ALE_ENV{ALECACHE});
  }

  $_ = $hasher->unhash($_);
  if (!s#^($ALE_ENV{ALECACHE}|\.)/##)
  {
    warn "Invalid filename in aleurl2file: Prefix doesn't match $ALE_ENV{ALECACHE} (use full pathname, or start with ./)\n";
    return undef;
  }

  s|\./||;
  s/\/index\.html$//;
  s/\/$//;
  $_="http://".uri_unescape($_,"\x00-\x1f\x7f-\xff\x20\"\<\>\@\[\\\]\^\`\{\|\}\~\%");
  if (/\x00-\x1f\x7f-\xff/)
  {
    warn "Invalid filename encountered on line $.; ignoring.\n";
    return undef;
  }
  $_;
}


1;
