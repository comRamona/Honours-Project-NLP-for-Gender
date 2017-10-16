use strict;

package Clair::ALE::Search;

=head1 NAME

Clair::ALE::Search - Search the Automatic Link Extrapolator.

=head1 SYNOPSIS

Search the Automatic Link Extrapolator by various criteria.

=head1 DESCRIPTION

=head2 CONSTRUCTOR

=over 4

=item Clair::ALE::Search->new

(limit => limit,
sqlmatch => bool,
regexpmatch => bool,
[no_]source_url => url_string,
[no_]dest_url => url_string,
[no_]link[n]_text,
[no_]link[n]_word,
)

Search for connections that meet the criteria you give.  Valid criteria are:

=over 4

=item limit

Return at most this many connections.

=item source_url 

The first URL in the connection.  Use no_source_url to exclude
connections where the first URL is this one.  The argument to this
should just be a simple string.

=item dest_url

The last URL in the connection.  Use no_dest_url to exclude
connections where the last URL is this one.  The argument to this
should just be a simple string.

=item link_text

The text that links two pages.  For multi-hop links, put a number
after link.  To exclude links with this text, use "no_link_text".

=item link_word

An individual word that links two pages.  For multi-hop links, put a
number after link.  To exclude links which contain these words, use
"no_link_word".

=back

=back

=head2 METHODS

=over 4

=item $search->queryresult

Return the next result from the query, or undef if there are no more
results.

=back

=head2 INSTANCE VARIABLES

This object has no public instance variables.

=head1 EXAMPLES

  my $search = Clair::ALE::Search->(link1_word => 'argle',
                             link2_word => 'bargle');
  while (my $conn = $search->queryresult)
  {
    my $conn = $search->queryresult;
    my $link = $conn->{link}->[0];
    my $url_from = $link->{from};
    my $url_from = $link->{to};
    print "Connect from ",$url_from->{url}," to ",$url_to->{url},
          " in ",$conn->{numlinks}," hops.\n";
  }

=head1 SEE ALSO

L<Clair::Utils::ALE>, L<Clair::ALE::Conn>, L<Clair::ALE::Link>, L<Clair::ALE::URL>.

=cut

use Clair::Utils::ALE;
use Clair::ALE::_SQL;
use Clair::ALE::URL;
use Clair::ALE::Link;
use Clair::ALE::Conn;
use Clair::ALE::Stemmer qw(ale_stemsome ale_stem);
use Clair::ALE::NormalizeURL qw(ale_normalize_url);

use vars qw(%QUERYPARAMS %GLOBALPARAMS);
%QUERYPARAMS = (limit => 'int',
		source_url => 'list',
		dest_url => 'list',
		text => 'list',
		no_source_url => 'list',
		no_dest_url => 'list',
		text => 'list',
		no_text => 'list',
		sqlmatch => 'bool',
		regexpmatch => 'bool',
		word => 'list',
		source_cached => 'bool',
		source_not_cached => 'bool',
		dest_cached => 'bool',
		dest_not_cached => 'bool',
		not_cached => 'bool',
		exists => 'int',
		no_word => 'list',
	       );

%GLOBALPARAMS = (limit => 'int',
		 sqlmatch => 'bool',
		 regexpmatch => 'bool',
		);

sub colname
{
  my $self = shift;
  my($var,$num)=@_;

  if ($var eq 'dest_url')
  {
    return "url".($self->{numlinks}+1).".url";
  }
  elsif ($var eq 'source_url')
  {
    return "url1.url";
  }
  elsif ($var eq 'text')
  {
    return "link$num.link_text";
  }
  elsif ( ($var eq 'source_last_updated') || ($var eq 'source_cached') )
  {
    return "url1.last_updated";
  }
  elsif ( ($var eq 'dest_last_updated') || ($var eq 'dest_cached') )
  {
    return "url".($self->{numlinks}+1).".last_updated";
  }
  elsif ($var eq 'word')
  {
    return "word$num.word";
  }
}

sub new
{
  my $class = shift;
  my $self = {};
  bless $self,$class;

  $self->{_alesql}=Clair::ALE::_SQL->new;
  
  $self->queryparams(@_);
  $self->makesql;
  $self;
}

sub queryparams
{
  my $self = shift;
  my($var,$val);

  while($var = shift)
  {
    my $link;
    if ($var =~ s/^link([1-9])_//)
    {
      $link = $1;
    }
    else
    {
      $link = 1;
    }

    $val = shift;
    if ($GLOBALPARAMS{$var})
    {
      $self->{query}{$var}=$val;
    }
    elsif ($QUERYPARAMS{$var})
    {
      if ($QUERYPARAMS{$var} eq 'list')
      {
	if (ref($val) eq 'ARRAY')
	{
	  if ($var =~ /word$/)
	  {
	    push(@{$self->{query}{$var}[$link]}, ale_stemsome(@$val));
	  }
	  elsif ($var =~ /url$/)
	  {
	    push(@{$self->{query}{$var}[$link]}, map { ale_normalize_url($_) } @$val);
	  }
	  else
	  {
	    push(@{$self->{query}{$var}[$link]}, @$val);
	  }
	  $self->{query}{link}[$link]=1;
	}
	else
	{
	  if ($var =~ /word$/)
	  {
	    push(@{$self->{query}{$var}[$link]}, ale_stem($val));
	  }
	  else
	  {
	    push(@{$self->{query}{$var}[$link]}, $val);
	  }
	  $self->{query}{link}[$link]=1;
	}
      }
      else
      {
	$self->{query}{$var}[$link] = $val;
	$self->{query}{link}[$link]=1;
      }
    }
    else
    {
      warn "Unrecognized query variable '$var'\n";
    }
  }
  $self;
}

sub makesql
{
  my $self = shift;
  $self->queryparams(@_);
  my $defop;
  my $numlinks;
  my @where = ();
  my $alesql = $self->{_alesql};
  my $links_table = $alesql->links_table();
  my $words_table = $alesql->words_table();
  my $urls_table = $alesql->urls_table();
  
  # Find out how many links we have.
  for(my $i=0;$i<10;$i++)
  {
    if ($self->{query}{link}[$i])
    {
      $numlinks=$i;
    }
  }
  if (!$numlinks)
  {
    $numlinks=1;
  }
  $self->{numlinks}=$numlinks;
  
  if ($self->{query}{sqlmatch})
  {
    $defop = 'LIKE';
  }
  elsif ($self->{query}{regexp_match})
  {
    $defop = 'RLIKE';
  }
  else
  {
    $defop = '=';
  }
  my $numurls=$numlinks+1;
  $self->{sqlpart}{sel} = "SELECT ".
    join(", ",
	 "url1.urlid AS from_id",
	 "url1.url AS from_url",
	 (map { ("url$_.urlid AS url${_}_id", "url$_.url AS url${_}_url") } (2..($numurls-1))),
	 (map { ("link$_.link_text AS link${_}_text","link$_.linkid AS link${_}_id") } (1..$numlinks)),
	 "url$numurls.urlid AS to_id",
	 "url$numurls.url AS to_url",
	);
#  $self->{sqlpart}{sel} = 'SELECT source_url.docid AS source_docid, source_url.url AS source_url, dest_url.docid AS dest_docid, dest_url.url AS dest_url, link_num, type, text AS text';

  if ($self->{query}{limit})
  {
    $self->{sqlpart}{limit} = "\tLIMIT ".$self->{query}{limit};
  }

  $self->{sqlpart}{from} = "FROM ";
  if (($self->{query}{word}&&@{$self->{query}{word}[1]})||($self->{query}{word}&&@{$self->{query}{noword}[1]}))
  {
    $self->{sqlpart}{from} .= "$words_table AS word1, ";
    push(@where,"word1.linkid = link1.linkid");

    my $numwords;
    my @words = ();
    if ($self->{query}{word})
    {
      $numwords += scalar(@{$self->{query}{word}[1]});
    }
    if ($self->{query}{noword})
    {
      $numwords += scalar(@{$self->{query}{noword}[1]});
    }

    for(my $count=1;$count<$numwords;$count++)
    {
      my $let = chr(ord('a')+$count);
      $self->{sqlpart}{from} .= " $words_table AS word1$let, ";
      push(@where,"word1$let.linkid = word1.linkid");
    }
  }
  
  $self->{sqlpart}{from} .= 
      " $links_table AS link1"
      . ", $urls_table AS url1"
      . ", $urls_table AS url2";
  push(@where,"link1.link_from = url1.urlid");
  push(@where,"link1.link_to = url2.urlid");
  if ($numlinks > 1)
  {
    $self->{sqlpart}{from} .= "\n,".join(",\n",
	   map { my $urlnum=$_+1;
		 ((@{$self->{query}{word}[$_]}||@{$self->{query}{noword}[$_]})
		  ? "$words_table AS word$_ NATURAL LEFT JOIN "
		  : ""
		 ) . "$links_table AS link$_ LEFT JOIN $urls_table AS url$urlnum ON link$_.link_to = url$urlnum.urlid" }
	   (2..$numlinks));
  }

  $self->{sqlpart}{where} =
    "\tWHERE (".
      join(") \n\t  AND (",
           @where,
	   # Make sure specified query requirements are satisfied.
	   (map { my $linknum=$_;
		 (
		  (map { $self->onewhere('',$self->colname($_,$linknum),$defop,@{$self->{query}{$_}[$linknum]}); } qw(source_url dest_url text word)),
		  (map { $self->onewhere('NOT',$self->colname(nono($_),$linknum),$defop,@{$self->{query}{$_}[$linknum]}) } qw(no_source_url no_dest_url no_text no_word)),
		  (map { $self->onewhere('',$self->colname($_,$linknum),'IS NOT NULL',map { '' } @{$self->{query}{$_}[$linknum]}) } qw(source_cached dest_cached)),
		  (map { $self->onewhere('',$self->colname(nono($_),$linknum),'IS NULL',map { '' } @{$self->{query}{$_}[$linknum]}) } qw(source_not_cached dest_not_cached)),
		 ),
	       } (1..$numlinks)),
	   # And join all of the links together properly.
	   (map { "link".($_-1).".link_to = link$_.link_from" } (2..$numlinks)),
	  ) . ")";
  if ($self->{sqlpart}{where} eq "\tWHERE ()")
  {
    $self->{sqlpart}{where} = '';
  }
  $self->{sql} = join("\n",map { $self->{sqlpart}{$_} or ''} qw(sel from where limit));
  $self->{sql};
}

sub nono
{
  my($s)=@_;
  $s =~ s/^no_//;
  $s;
}

sub onewhere
{
  my $self = shift;
  my($notp, $fieldname, $op, @fieldvals)=@_;
  my $letnum = 0;
  my $let;
  my $usefield;
  
#  print "**@fieldvals**\n";
  return map {
               if ($letnum) { $let = chr(ord('a')+($letnum));}
	       else { $let = "" };
	       $letnum++;
	       ($usefield = $fieldname) =~ s/\./$let./;
#	       print "***",$self->{_alesql}->quote($_),"***\n";
	       join(' ',$notp,$usefield,$op,$_?$self->{_alesql}->quote($_):'','')
	     } @fieldvals;
}

sub query
{
  my $self = shift;
  my($sql)=@_;
  
  $self->{_alesql}->query($sql);
}

sub queryresult
{
  my $self = shift;
  my @l;
  
  if (!$self->{_querystarted})
  {
    $self->query($self->{sql});
    $self->{_querystarted}=1;
  }
  
  # For each result, we return a connection.
  my $r = $self->{_alesql}->queryresult(@_);
  if (!$r)
  {
    delete $self->{_querystarted};
    return undef;
  }

  for(my $i=1;$i<=$self->{numlinks};$i++)
  {
    my($fp,$sp);

    if ($i==1)
    {
      $fp="from_";
    }
    else
    {
      $fp="url${i}_";
    }
    if ($i==$self->{numlinks})
    {
      $sp = "to_";
    }
    else
    {
      $sp = "url".($i+1)."_";
    }

    my $url1 = Clair::ALE::URL->new(url => $r->{$fp."url"},
			     id => $r->{$fp."id"});

    my $url2 = Clair::ALE::URL->new(url => $r->{$sp."url"},
			     id => $r->{$sp."id"});
    next unless ($r->{'link'.$i.'_text'});
    my $link = Clair::ALE::Link->new(from => $url1,
			      to => $url2,
			      text => $r->{'link'.$i.'_text'},
			      id => $r->{'link'.$i.'_id'});
    push(@l,$link);
  }
  return Clair::ALE::Conn->new(@l);
}
