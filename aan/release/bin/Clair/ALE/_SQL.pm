use strict;

package Clair::ALE::_SQL;

=head1 NAME

Clair::ALE::_SQL - Internal SQL adapter for use by ALE

=head1 SYNOPSIS

This module is used internally by the other ALE modules to connect to an
SQL database.  Other modules (particularly L<Clair::ALE::Search|Clair::ALE::Search>)
will use this automatically, so you shouldn't have to use it yourself
unless you're writing an ALE module.

It is a thin frontend for the DBI module.  It's main purpose is to make
it easy to change databases or database structures without having to
change any other code.

=cut

use strict;

use Clair::Utils::ALE;
use Clair::Utils::ALE qw(%ALE_ENV);
use DBI;
use Carp;

use vars qw(%SETTABLE);
%SETTABLE=(
	   DSN => 1,
	   username => 1,
	   password => 1,
	   AutoCommit => 1,
	  );


sub new
{
  my $class = shift;
  my $self = {};
  bless $self,$class;

  $self->setdefaults;
  $self->set(@_);

  $self;
}

sub _refresh_tablenames
{
    my $self = shift;
    my $alespace_prefix;
    if (!$ALE_ENV{ALESPACE} or ($ALE_ENV{ALESPACE} eq 'default'))
    {   
        $alespace_prefix="";
    }
    else
    {
        $alespace_prefix="$ALE_ENV{ALESPACE}_";
    }
    $self->{_links_table} = $alespace_prefix."links";
    $self->{_words_table} = $alespace_prefix."words";
    $self->{_urls_table} = $alespace_prefix."urls";
}

sub links_table {
    my $self = shift;
    $self->_refresh_tablenames();
    return $self->{_links_table};
}

sub words_table {
    my $self = shift;
    $self->_refresh_tablenames();
    return $self->{_words_table};
}

sub urls_table {
    my $self = shift;
    $self->_refresh_tablenames();
    return $self->{_urls_table};
}

sub setdefaults
{
  my $self = shift;

  my $user = 'root';
  my $pass = '';
  if ($ALE_ENV{ALE_DB_USER}) {
    $user = $ALE_ENV{ALE_DB_USER}; 
  }
  if ($ALE_ENV{ALE_DB_PASS}) {
    $pass = $ALE_ENV{ALE_DB_PASS};
  }
  return $self->set(
		    DSN => 'DBI:mysql:database=clair',
		    username => $user,
		    password => $pass,
		    AutoCommit => 1,
		   );
}

sub set
{
  my $self = shift;
  my($var,$val);
  
  while($var=shift)
  {
    $val = shift;
    if ($SETTABLE{$var})
    {
      $self->{$var}=$val;
    }
  }
  $self;
}

sub connect
{
  my $self = shift;
  
  if (!$self->{_dbh})
  {
    print "$self->{DSN}\n";
    $self->{_dbh} = DBI->connect($self->{DSN}, 
				 $self->{username},
				 $self->{password},
				 {AutoCommit => $self->{AutoCommit},
				  PrintError => 0,
				 })
      or croak "ALE::_SQL couldn't connect to database: ".DBI->errstr."\n";
  }
  $self;
}

sub disconnect
{
  my $self = shift;
  
  if ($self->{_dbh})
  {
    $self->{_dbh}->disconnect;
    delete $self->{_dbh};
  }
  $self;
}

sub quote
{
  my $self = shift;
  
  $self->connect;
  return $self->_quote(@_);
}

sub _quote
{
  return $_[0]->{_dbh}->quote($_[1]);
}

sub query
{
  my $self = shift;
  my($sql)=@_;
  
  $self->{_sql}=$sql;
  if ($ALE_ENV{SQLDEBUG}) { print "SQL: $sql\n"; }
  $self->connect;
  $self->{_sth} = $self->{_dbh}->prepare($sql)
    or croak "Error preparing SQL statement '$sql': ".$self->{_dbh}->errstr;
  $self->{_sth}{mysql_use_result}=1;
  $self->{_sth}->execute
    or croak "Error executing SQL statement '$sql': ".$self->{_dbh}->errstr;

  $self;
}

sub queryresult
{
  my $self = shift;
  $self->{_sth}
    or croak "Attempted to get query results without running query!";
  my $row = $self->{_sth}->fetchrow_hashref;
  if (!$row)
  {
    $self->{_sth}->finish
      or croak "Error finishing SQL statement '$self->{_sql}': ".$self->{_dbh}->errstr;
  }
  return $row;
}

sub queryone
{
  my $self = shift;

  $self->query(@_);
  my $r = $self->queryresult;
  if ($r)
  {
    $self->querycancel;
  }
  $r;
}

sub do
{
  my $self = shift;

  if ($ALE_ENV{DEBUGSQL})
  {
    print "SQL: @_\n";
  }
  $self->connect;
  $self->{_dbh}->do(@_);
}

sub querycancel
{
  my $self = shift;

  $self->{_sth}->finish
    or croak "Error finishing SQL statement '$self->{_sql}': ".$self->{_dbh}->errstr;
}

sub commit
{
  my $self = shift;
  $self->{_dbh}->commit;
}

sub rollback
{
  my $self = shift;
  $self->{_dbh}->rollback;
}

sub insertid
{
  my $self = shift;
  return $self->{_dbh}->{mysql_insertid};
}

sub errstr
{
  my $self = shift;
  return $self->{_dbh}->errstr;
}

sub errdie
{
  my $self = shift;

  croak join("",@_) . ": Database error ".$self->errstr;
}

1;
