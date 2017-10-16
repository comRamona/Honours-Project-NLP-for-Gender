package Clair::Bio::GIN::Interaction;

use Clair::Bio::GIN::Data;


sub new{
  my $class=shift;
  my $gene1=shift;
  my $gene2=shift;
  my $interaction_word=shift;
  my $sentence=shift;
  my $direction = 1; # 1 means from gene1 to gene2. 0 is the reverse.
  $direction=shift;
  my $self = bless {
                    gene1 => $gene1,
                    gene2 => $gene2,
                    interaction_word => $interaction_word,
                    sentence => $sentence,
                    direction => $direction
                    }, $class;
  return $self;
}

sub is_negation{
    my $self = shift;
    my $sentence = $self->{sentence};
    my $data= new Clair::Bio::GIN::Data();
    my $negative_terms_ref = $data->get_negation_words();
    my @negative_terms = @$negative_terms_ref;
    $_ = $sentence;
    foreach my $term (@negative_terms){
            chop($term);
         if (/\b$term\b/i)
         {
              return 1;
         }
    }
    return 0;
}

sub get_gene1{
    my $self=shift;
    return $self->{gene1};
}

sub get_gene2{
    my $self=shift;
    return $self->{gene2};
}

sub get_interaction_word{
    my $self=shift;
    return $self->{interaction_word};
}


sub get_direction{
    my $self=shift;
    return $self->{direction};
}


sub set_gene1{
    my $self=shift;
    my $gene1=shift;
    $self->{gene1}=$gene1;
}


sub set_gene2{
    my $self=shift;
    my $gene2=shift;
    $self->{gene2}=$gene2;
}


sub set_interaction_word{
    my $self=shift;
    my $interaction_word=shift;
    $self->{interaction_word}=$interaction_word;
}


sub set_direction{
    my $self=shift;
    my $direction=shift;
    $self->{direction}=$direction;
}

sub toggle_direction{
    my $self=shift;
    if($self->{direction}==1){
        $self->{direction}=0;
    }else{
        $self->{direction}=1;
    }
}

1;

__END__

=pod

=head1 NAME

Clair::Bio::GIN::Interaction - A data structure to represent an interaction
(sentence, gene1, gene2, interaction word, direction)

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

       use Clair::Bio::GIN::Interaction;
       $interaction = new Clair::Bio::GIN::Interaction($gene1,$gene2,$interaction_word,$sentence,$direction);
       $interaction->is_negation();

=head1 METHODS

=head2 new

Function  : Creates a new instance of the Clair::Bio::GIN::Interaction

Usage     : $interaction = new Clair::Bio::GIN::Interaction($gene1,$gene2,$int_word,$sentence,[$dir]) ;

Parameters: The first gene, The second Gene, The interaction Word, The sentence,
The interaction direction.

Returns   : Clair::Bio::GIN::Interaction obejct

=head2 is_negation

Function  : Checks whether the interaction is negated or not.

Usage     : $is_negated = $interaction->is_negation();

Parameters: Nothing

Returns   : 1 if the interaction is negated and the 0, otherwise.

=head1 AUTHOR

Amjad Abu Jbara << <clair at umich.edu> >>

Arzucan Ozgur << <clair at umich.edu> >>

=head1 SEE ALSO

Clair::Bio::GIN, Clair::Bio::GIN::Data

=cut