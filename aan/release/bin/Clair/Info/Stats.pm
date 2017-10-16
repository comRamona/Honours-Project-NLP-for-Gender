package Clair::Info::Stats;

# use FindBin;
# use lib "$FindBin::Bin/../lib/perl5/site_perl/5.8.5";

use strict;
use vars qw/$DEBUG/;

use Clair::Debug;
use Data::Dumper;


sub new
{
	my ($proto, %args) = @_;
	my $class = ref $proto || $proto;

	my $self = bless {}, $class;
	$DEBUG = $args{DEBUG} || $ENV{MYDEBUG};


	# overrides
	while ( my($k, $v) = each %args )
	{
		$self->{$k} = $v if(defined $v);
	}

  return $self;
}



1;
