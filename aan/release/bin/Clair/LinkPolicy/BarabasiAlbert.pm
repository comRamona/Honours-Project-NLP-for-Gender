package Clair::LinkPolicy::BarabasiAlbert;

use strict;
use Carp;

=head1 NAME

Clair::LinkPolicy::BarabasiAlbert - Class implementing the Barabasi Albert link model.

=cut

=head1 SYNOPSIS

=cut

=head1 DESCRIPTION

BarabasiAlbert
  Class implementing the Barabasi Albert link model.

INHERITS FROM:
  LinkPolicy

REQUIRED RESOURCES:
  XXX

METHODS IMPLEMENTED BY THIS CLASS:
  new			Object Constructor
  create_corpus	Creates a corpus using this link policy.

=cut

=head2 new
Generic object constructor for all link policies. Should
  only be called by subclass constructors.

  base_collection	=> $collection_object
  type		=> $name_of_this_linker_type

=cut

sub new {
  my $class = shift;

  my $self = bless { @_ }, $class;

  # Verify parameters
  unless ((exists $self->{base_collection}) &&
          (exists $self->{base_collection})) {
    croak "LinkPolicy constructor requires parameters:
		base_collection	=> $collection_of_documents
		type		=> $this_policy_type\n";
  }

  return $self;
}

=head2 create_corpus 

Generates a corpus using the Barabasi-Albert model.

=cut

sub create_corpus {

}

1;
