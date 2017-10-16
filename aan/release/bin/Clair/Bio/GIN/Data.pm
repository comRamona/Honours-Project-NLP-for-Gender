package Clair::Bio::GIN::Data;

use Clair::Config qw($CLAIRLIB_HOME);

sub new{
    my $class = shift;
    my $speculation_words_file = shift | "$CLAIRLIB_HOME/etc/speculation_words.txt";
    my $interaction_words_file = shift | "$CLAIRLIB_HOME/etc/interaction_words.txt";
    my $negation_words_file = shift | "$CLAIRLIB_HOME/etc/negation_words.txt";
    open SPEC, $speculation_words_file or die ("Can't open file $!");
    open INTR, $interaction_words_file or die ("Can't open file $!");
    open NEG, $negation_words_file or die ("Can't open file $!");
    my @speculation_words = <SPEC>;
    my @interaction_words = <INTR>;
    my @negation_words = <NEG>;
    chomp(@speculation_words);
    chomp(@interaction_words);
    chomp(@negation_words);
    my $self = bless{
                      speculation_words => \@speculation_words,
                      interaction_words => \@interaction_words,
                      negation_words => \@negation_words
                    }, $class;
    return $self;
}

sub get_negation_words{
    my $self=shift;
    my $words_ref = $self->{negation_words};
    return $words_ref;
}

sub get_speculation_words{
    my $self=shift;
    my $words_ref  = $self->{speculation_words};
    return $words_ref;
}

sub get_interaction_words{
    my $self=shift;
    my $words_ref = $self->{interaction_words};
    return $words_ref;
}

sub is_interaction_word{
    my $self = shift;
    my $string1 = shift;
    my $interaction_words = $self->{interaction_words};
    my @words=@$interaction_words;
    foreach $word (@$interaction_words){
       chop($word);
       if ($word eq $string1){
         return 1;
       }
     }
     return 0;
}
1;


__END__

=pod

=head1 NAME

Clair::Bio::GIN::Data - Interface to the data used by Clair::GIN and Clair::GIN::Interaction

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

       use Clair::Bio::GIN::Data;
       $data = new Clair::Bio::GIN::Data();
       $neg_ref = $data->get_negation_words();
       @neg_words = @$neg_ref;
       $data->is_interaction_word($word);

=head1 METHODS

=head2 new

Function  : Creates a new instance of the Clair::Bio::GIN::Data

Usage     : $data = new Clair::Bio::GIN([$speculation_words_file, $interaction_words_file, $negation_words_file]) ;

Parameters: $speculation_words_file: a file containing a list of speculation words,
$interaction_words_file: a file containing a list of interaction words,
$negation_words_file: a file containing a list of negation words.

Returns   : Clair::Bio::GIN::Data obejct

=head2 get_negation_words

Function  : Returns an array of negation words.

Usage     : $neg_ref = $data->get_negation_words();

Parameters: Nothing

Returns   : A reference for an array of strings (Negation words).

=head2 get_speculation_words

Function  : Returns an array of the speculation words.

Usage     : $spec_ref = $data->get_speculation_words();

Parameters: Nothing

Returns   : A reference for an array of strings (Speculation words).

=head2 get_interaction_words

Function  : Returns an array of the interaction words.

Usage     : $inter_ref = $data->get_interaction_words();

Parameters: Nothing

Returns   : A reference for an array of strings (Interaction words).

=head2 is_interaction_word

Function  : Checks whether a given word is an interaction word or not.

Usage     : $is_interaction = $data->is_interaction_word($word);

Parameters: A string (The word).

Returns   : 1 if the word is an interaction word and 0 otherwise.

=head1 AUTHOR

Amjad Abu Jbara << <clair at umich.edu> >>

Arzucan Ozgur << <clair at umich.edu> >>

=head1 SEE ALSO

Clair::Bio::GIN, Clair::Bio::GIN::Interaction

=cut