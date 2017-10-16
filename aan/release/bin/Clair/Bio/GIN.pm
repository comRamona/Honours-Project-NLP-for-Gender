package Clair::Bio::GIN;

use Clair::Bio::GIN::Data;
use Clair::Utils::Parse;
use Clair::SentenceSegmenter::Text;
use Clair::Bio::GIN::Interaction;
use Clair::Config;
use Data::Dumper;

sub new{
  my $class=shift;
  my $self = bless{ },$class;
  return $self;
}

sub tag_genes{
  my $self=shift;
  my $sentence = shift;
  #print $sentence;
  $current_dir=`pwd`;
  chdir $GENIATAGGER_PATH;
  open FILE, "echo $sentence | ./geniatagger|";
  my @protiens=();
  while(<FILE>){
           $line=$_;
         chomp($line);
         @cols=split(/\s+/,$line);
         if ($cols[4] =~ /protein/i){
               push  @protiens,$cols[0];
         }
  }
  chdir $current_dir;
  return \@protiens;
}

sub tag_interaction_words{
  my $self=shift;
  my $sentence = shift;
  my @interaction_words=();
#  print $sentence,"\n";
  my $data=new Clair::Bio::GIN::Data();
  my @words = Clair::Utils::TFIDFUtils::split_words($sentence,0);
  foreach my $word (@words){
      if($data->is_interaction_word($word)){
          push @interaction_words, $word;
      }
  }
  return \@interaction_words;
}

sub dependency_parse{
     my $self=shift;
     my $sentence = shift;
     return Clair::Utils::Parse::standford_parse($sentence);
}

sub is_speculative{
    my $self = shift;
    my $sentence = shift;
    $data = new Clair::Bio::GIN::Data();
    $specultations_terms_ref = $data->get_speculation_words();
    foreach $term (@$specultations_terms_ref){
         if ($sentence =~ m/$term/)
         {
              return 1;
         }
    }
    return 0;
}

our @interactions = ();

sub extract_interactions{
  my $self=shift;
  my $text=shift;
  my $seg=new Clair::SentenceSegmenter::Text();
  my @sentences = $seg->split_sentences($text);
  my @sents = ();
  my @intwords =();
  my @tags = ();
  my @parses = ();
  print Dumper(@sentences);
  foreach $sent (@sentences){

        my $protiens_ref = $self->tag_genes($sent);
        my $intwords_ref = $self->tag_interaction_words($sent);
        print Dumper(@$intwords_ref);
        foreach my $intw (@$intwords_ref){
               foreach my $p1 (@$protiens_ref){
                       foreach my $p2 (@$protiens_ref){
                               print "a";
                               push @tags, "$p1|#|$p2";
                               push @parses, $self->dependency_parse($sent);
                               push @sents, $sent;
                               push @intwords,$intw;
                       }
               }
        }
  }
  print Dumper(@sents),"\n";
  print Dumper(@tags),"\n";
  print Dumper(@parses),"\n";
  print Dumper(@intwords),"\n";
  my %rel; #two-dimensional hash of relations rel{parent}{child}=rel_type
  my $sent_id = 0;
  my $type = "";
  #while (defined($line = <INFILE1>)) { #read the parse file
  foreach $parse (@parse){
        @lines = split(/\n/,$parse);
        foreach $line (@lines){
                chomp($line);
                #$line=lc($line);
                $_=$line;
                s/\s+$//;
                /^([^\(]*)\((.*)\)$/;
                my $rel_type = $1;
                my ($parent,$child) = split(/\,\ /,$2,2);
                $rel{$parent}{$child}=$rel_type;
        }
        #processing of the sentence is done
                #read tags file
                my $line2 = pop(@tags);
                chomp($line2);

                my @fields = split(/\|#\|/,$line2);
                my $prot1 = $fields[0]; #actualString
                my $prot2 = $fields[1]; #actualString

                my $sent = pop(@sentences);
                chomp($sent);

                $type = pop(@intwords);
                chomp($type);

                ##doc_id

                #### ACTIVE RULES ####
                for my $k1 (keys(%rel)) {
                        for my $k2 (keys(%{$rel{$k1}})) {

                                rule0($k1, $k2, $prot1, $prot2, $sent); ### e.g. prot1-prot2 interaction

                                if ($rel{$k1}{$k2} eq "nsubj"){ ### rule 1, 3, 7
                                        rule1($k1, $k2, $prot1, $prot2, $sent);
                                        rule3($k1, $k2, $prot1, $prot2, $sent);
                                        rule7($k1, $k2, $prot1, $prot2, $sent);
                                }#if rel nsubj
                                elsif ($rel{$k1}{$k2} eq "prep_of"){ ### rule 4, 6, 7, 8, 9
                                        rule4($k1, $k2, $prot1, $prot2, $sent);
                                        rule6($k1, $k2, $prot1, $prot2, $sent);
                                        rule7($k1, $k2, $prot1, $prot2, $sent);
                                        rule8($k1, $k2, $prot1, $prot2, $sent);
                                        rule9($k1, $k2, $prot1, $prot2, $sent);
                                }
                                elsif ($rel{$k1}{$k2} eq "prep_between"){ ### rule 5
                                        rule5($k1, $k2, $prot1, $prot2, $sent);
                                }
                                #### END ACTIVE RULES ####

                                #### PASSIVE RULES ####
                                elsif ($rel{$k1}{$k2} eq "nsubjpass"){ ### rule 2
                                        rule2($k1, $k2, $prot1, $prot2, $sent);
                                }

                        }#for $k2
                }#for $k1

                %rel=(); #initialize rel hash for the next sentence

    }
    return @interactions;
}


sub rule0{

        my ($k1, $k2, $prot1, $prot2, $sent) = @_;

        $k1 =~ /^(.*)\-(\d+)$/;
        my $p = $1; #parent (interaction word)

        if (($type eq lc($p)) && not_neg($k1)){

                if ($k2 =~ /^(.*)\-(.*)\-(\d+)$/){
                                my $c1 = $1;
                                my $c2 = $2;

                                if (($c1 eq $prot1) &&  ($c2 eq $prot2)){
                                        print "$pmid|#|$sent_id|#|$type|#|$prot1|#|$prot2|#|$sent\n";
                                        push @interactions, Clair::Bio::GIN::Interaction->new($prot1,$prot2,$type,$sent,1);
                                }
                                elsif (($c1 eq $prot2) &&  ($c2 eq $prot1)){
                                        print "$pmid|#|$sent_id|#|$type|#|$prot2|#|$prot1|#|$sent\n";
                                        push @interactions, Clair::Bio::GIN::Interaction->new($prot2,$prot1,$type,$sent,1);
                                }
                }
        }

}

###########################################################################################
##############Rule 1: Active sentence: nsubj, predicate, dobj##############################
##############first level child or second level child connected with conj_and is a prot####
###########################################################################################

sub rule1{

        my ($k1, $k2, $prot1, $prot2, $sent) = @_;

        $k1 =~ /^(.*)\-(\d+)$/;
        my $p = $1;

        $k2 =~ /^(.*)\-(\d+)$/;
        my $c = $1;

        if (($type eq lc($p)) && not_neg($k1)){
                if (name_match($k2, $prot1)){
                        for my $c2  (keys(%{$rel{$k1}})) {
                                if ($rel{$k1}{$c2} eq "dobj"){

                                        $c2 =~ /^(.*)\-(\d+)$/;
                                        my $ch2 = $1;

                                        if (name_match($c2, $prot2)){ #first level child

                                                print "$pmid|#|$sent_id|#|$type|#|$prot1|#|$prot2|#|$sent\n";
                                                push @interactions, Clair::Bio::GIN::Interaction->new($prot1,$prot2,$type,$sent,1);

                                        }#if protx
                                        else{ ## look to second-level child connected with conj_and
                                                for my $c3  (keys(%{$rel{$c2}})) {
                                                        if (($rel{$c2}{$c3} eq "conj_and")){

                                                                $c3 =~ /^(.*)\-(\d+)$/;
                                                                my $ch3 = $1;

                                                                if (name_match($c3, $prot2)){

                                                                        #my $output = $prot1."|#|".$prot2."|#|".$doc_id."|#|".$pmid."|#|".$sent_id."|#|".$sent."|#|".$p."|#|".$start_date."|#|".$pub_date;
                                                                        #print $output, "\n";

                                                                        print "$pmid|#|$sent_id|#|$type|#|$prot1|#|$prot2|#|$sent\n";
                                                                        push @interactions, Clair::Bio::GIN::Interaction->new($prot1,$prot2,$type,$sent,1);
                                                                }
                                                        }
                                                }#for
                                        }
                                }#if dobj

                        }#for c2
                }#if c
                #elsif ($c =~ $prot2){
                elsif (name_match($k2, $prot2)){
                        for my $c2  (keys(%{$rel{$k1}})) {
                                if ($rel{$k1}{$c2} eq "dobj"){

                                        $c2 =~ /^(.*)\-(\d+)$/;
                                        my $ch2 = $1;

                                        if (name_match($c2, $prot1)){

                                                print "$pmid|#|$sent_id|#|$type|#|$prot2|#|$prot1|#|$sent\n";
                                                push @interactions, Clair::Bio::GIN::Interaction->new($prot1,$prot2,$type,$sent,1);

                                        }#if protx

                                        else{ ## look to second-level child connected with conj_and
                                                for my $c3  (keys(%{$rel{$c2}})) {
                                                        if (($rel{$c2}{$c3} eq "conj_and")){

                                                                $c3 =~ /^(.*)\-(\d+)$/;
                                                                my $ch3 = $1;

                                                                if (name_match($c3, $prot1)){

                                                                        print "$pmid|#|$sent_id|#|$type|#|$prot2|#|$prot1|#|$sent\n";
                                                                        push @interactions, Clair::Bio::GIN::Interaction->new($prot2,$prot1,$type,$sent,1);

                                                                }
                                                        }
                                                }#for
                                        }

                                }#if dobj

                        }#for c2
                }#if c

        }# if exists
}

######################################################################
##############Rule 2: passive sentence: nsubjpass, predicate, agent###
######################################################################

sub rule2{

        my ($k1, $k2, $prot1, $prot2, $sent) = @_;

        $k1 =~ /^(.*)\-(\d+)$/;
        my $p = $1;

        $k2 =~ /^(.*)\-(\d+)$/;
        my $c = $1;


        if (($type eq lc($p)) && not_neg($k1)){
                if (name_match($k2, $prot1)){
                        for my $c2  (keys(%{$rel{$k1}})) {
                                if ($rel{$k1}{$c2} eq "agent"){

                                        $c2 =~ /^(.*)\-(\d+)$/;
                                        my $ch2 = $1;

                                        if (name_match($c2, $prot2)){ #end of rule 1

                                                print "$pmid|#|$sent_id|#|$type|#|$prot2|#|$prot1|#|$sent\n";
                                                push @interactions, Clair::Bio::GIN::Interaction->new($prot1,$prot2,$type,$sent,1);

                                        }#if protx
                                }#if dobj

                        }#for c2
                }#if c
                #elsif ($c =~ $prot2){
                elsif (name_match($k2, $prot2)){
                        for my $c2  (keys(%{$rel{$k1}})) {
                                if ($rel{$k1}{$c2} eq "agent"){

                                        $c2 =~ /^(.*)\-(\d+)$/;
                                        my $ch2 = $1;

                                        if (name_match($c2, $prot1)){

                                                print "$pmid|#|$sent_id|#|$type|#|$prot1|#|$prot2|#|$sent\n";
                                                push @interactions, Clair::Bio::GIN::Interaction->new($prot1,$prot2,$type,$sent,1);

                                        }#if protx
                                }#if dobj

                        }#for c2
                }#if c

        }# if exists
}

###########################################################################################
##############Rule 3: Active sentence: nsubj, predicate, prep_with#########################
##############first level child or second level child connected with conj_and is a prot####
###########################################################################################

sub rule3{

        my ($k1, $k2, $prot1, $prot2, $sent) = @_;

        $k1 =~ /^(.*)\-(\d+)$/;
        my $p = $1;

        $k2 =~ /^(.*)\-(\d+)$/;
        my $c = $1;


        if (($type eq lc($p)) && not_neg($k1)){
                if (name_match($k2, $prot1)){
                        for my $c2  (keys(%{$rel{$k1}})) {
                                if ($rel{$k1}{$c2} eq "prep_with"){

                                        $c2 =~ /^(.*)\-(\d+)$/;
                                        my $ch2 = $1;

                                        if (name_match($c2, $prot2)){ #first level child

                                                print "$pmid|#|$sent_id|#|$type|#|$prot1|#|$prot2|#|$sent\n";
                                                push @interactions, Clair::Bio::GIN::Interaction->new($prot1,$prot2,$type,$sent,1);

                                        }#if protx
                                        else{ ## look to second-level child connected with conj_and
                                                for my $c3  (keys(%{$rel{$c2}})) {
                                                        if (($rel{$c2}{$c3} eq "conj_and")){

                                                                $c3 =~ /^(.*)\-(\d+)$/;
                                                                my $ch3 = $1;

                                                                if (name_match($c3, $prot2)){

                                                                        print "$pmid|#|$sent_id|#|$type|#|$prot1|#|$prot2|#|$sent\n";
                                                                        push @interactions, Clair::Bio::GIN::Interaction->new($prot1,$prot2,$type,$sent,1);
                                                                }
                                                        }
                                                }#for
                                        }
                                }#if dobj

                        }#for c2
                }#if c
                #elsif ($c =~ $prot2){
                elsif (name_match($k2, $prot2)){
                        for my $c2  (keys(%{$rel{$k1}})) {
                                if ($rel{$k1}{$c2} eq "prep_with"){

                                        $c2 =~ /^(.*)\-(\d+)$/;
                                        my $ch2 = $1;

                                        if (name_match($c2, $prot1)){

                                                print "$pmid|#|$sent_id|#|$type|#|$prot2|#|$prot1|#|$sent\n";
                                                push @interactions, Clair::Bio::GIN::Interaction->new($prot1,$prot2,$type,$sent,1);

                                        }#if protx

                                        else{ ## look to second-level child connected with conj_and
                                                for my $c3  (keys(%{$rel{$c2}})) {
                                                        if (($rel{$c2}{$c3} eq "conj_and")){

                                                                $c3 =~ /^(.*)\-(\d+)$/;
                                                                my $ch3 = $1;

                                                                if (name_match($c3, $prot1)){

                                                                        print "$pmid|#|$sent_id|#|$type|#|$prot2|#|$prot1|#|$sent\n";
                                                                        push @interactions, Clair::Bio::GIN::Interaction->new($prot2,$prot1,$type,$sent,1);;

                                                                }
                                                        }
                                                }#for
                                        }

                                }#if dobj

                        }#for c2
                }#if c

        }# if exists
}


###########################################################################################
##############Rule 4: Active sentence: prep_of, predicate, prep_by#########################
##############first level child or second level child connected with conj_and is a prot####
###########################################################################################

sub rule4{

        my ($k1, $k2, $prot1, $prot2, $sent) = @_;

        $k1 =~ /^(.*)\-(\d+)$/;
        my $p = $1;

        $k2 =~ /^(.*)\-(\d+)$/;
        my $c = $1;

        if (($type eq lc($p)) && not_neg($k1)){
                if (name_match($k2, $prot1)){
                        for my $c2  (keys(%{$rel{$k1}})) {
                                if ($rel{$k1}{$c2} eq "prep_by"){

                                        $c2 =~ /^(.*)\-(\d+)$/;
                                        my $ch2 = $1;

                                        if (name_match($c2, $prot2)){ #first level child

                                                print "$pmid|#|$sent_id|#|$type|#|$prot2|#|$prot1|#|$sent\n";
                                                push @interactions, Clair::Bio::GIN::Interaction->new($prot2,$prot1,$type,$sent,1);

                                        }#if protx
                                        else{ ## look to second-level child connected with conj_and
                                                for my $c3  (keys(%{$rel{$c2}})) {
                                                        if (($rel{$c2}{$c3} eq "conj_and")){

                                                                $c3 =~ /^(.*)\-(\d+)$/;
                                                                my $ch3 = $1;

                                                                if (name_match($c3, $prot2)){

                                                                        print "$pmid|#|$sent_id|#|$type|#|$prot2|#|$prot1|#|$sent\n";
                                                                        push @interactions, Clair::Bio::GIN::Interaction->new($prot2,$prot1,$type,$sent,1);

                                                                }
                                                        }
                                                }#for
                                        }
                                }#if dobj

                        }#for c2
                }#if c
                #elsif ($c =~ $prot2){
                elsif (name_match($k2, $prot2)){
                        for my $c2  (keys(%{$rel{$k1}})) {
                                if ($rel{$k1}{$c2} eq "prep_by"){

                                        $c2 =~ /^(.*)\-(\d+)$/;
                                        my $ch2 = $1;

                                        if (name_match($c2, $prot1)){

                                                print "$pmid|#|$sent_id|#|$type|#|$prot1|#|$prot2|#|$sent\n";
                                                push @interactions, Clair::Bio::GIN::Interaction->new($prot1,$prot2,$type,$sent,1);

                                        }#if protx

                                        else{ ## look to second-level child connected with conj_and
                                                for my $c3  (keys(%{$rel{$c2}})) {
                                                        if (($rel{$c2}{$c3} eq "conj_and")){

                                                                $c3 =~ /^(.*)\-(\d+)$/;
                                                                my $ch3 = $1;

                                                                if (name_match($c3, $prot1)){

                                                                        print "$pmid|#|$sent_id|#|$type|#|$prot1|#|$prot2|#|$sent\n";
                                                                        push @interactions, Clair::Bio::GIN::Interaction->new($prot1,$prot2,$type,$sent,1);

                                                                }
                                                        }
                                                }#for
                                        }

                                }#if dobj

                        }#for c2
                }#if c

        }# if exists
}

###########################################################################################
##############Rule 5: Active sentence: predicate, prep_between, conj_and###################
##############first level child or second level child connected with conj_and is a prot####
###########################################################################################

sub rule5{

        my ($k1, $k2, $prot1, $prot2, $sent) = @_;

        $k1 =~ /^(.*)\-(\d+)$/;
        my $p = $1;

        $k2 =~ /^(.*)\-(\d+)$/;
        my $c = $1;

        if (($type eq lc($p)) && not_neg($k1)){
                if (name_match($k2, $prot1)){
                        for my $c2  (keys(%{$rel{$k2}})) {
                                if ($rel{$k2}{$c2} eq "conj_and"){
                                        $c2 =~ /^(.*)\-(\d+)$/;
                                        my $ch2 = $1;

                                        if (name_match($c2, $prot2)){ #first level child

                                                print "$pmid|#|$sent_id|#|$type|#|$prot1|#|$prot2|#|$sent\n";
                                                push @interactions, Clair::Bio::GIN::Interaction->new($prot1,$prot2,$type,$sent,1);
                                        }#if protx

                                }#if dobj

                        }#for c2
                }#if c
                #elsif ($c =~ $prot2){
                elsif (name_match($k2, $prot2)){
                        for my $c2  (keys(%{$rel{$k2}})) {
                                if ($rel{$k2}{$c2} eq "conj_and"){
                                        $c2 =~ /^(.*)\-(\d+)$/;
                                        my $ch2 = $1;

                                        if (name_match($c2, $prot1)){

                                                print "$pmid|#|$sent_id|#|$type|#|$prot2|#|$prot1|#|$sent\n";
                                                push @interactions, Clair::Bio::GIN::Interaction->new($prot2,$prot1,$type,$sent,1);
                                        }#if protx

                                }#if dobj

                        }#for c2
                }#if c

        }# if exists
}

###########################################################################################
##############Rule 6: Active sentence: prep_of, predicate, prep_with#######################
##############first level child or second level child connected with conj_and is a prot####
###########################################################################################

sub rule6{

        my ($k1, $k2, $prot1, $prot2, $sent) = @_;

        $k1 =~ /^(.*)\-(\d+)$/;
        my $p = $1;

        $k2 =~ /^(.*)\-(\d+)$/;
        my $c = $1;

        if (($type eq lc($p)) && not_neg($k1)){
                if (name_match($k2, $prot1)){
                        for my $c2  (keys(%{$rel{$k1}})) {
                                if ($rel{$k1}{$c2} eq "prep_with"){
                                        $c2 =~ /^(.*)\-(\d+)$/;
                                        my $ch2 = $1;

                                        if (name_match($c2, $prot2)){ #first level child

                                                print "$pmid|#|$sent_id|#|$type|#|$prot2|#|$prot1|#|$sent\n";
                                                push @interactions, Clair::Bio::GIN::Interaction->new($prot2,$prot1,$type,$sent,1);

                                        }#if protx
                                        else{ ## look to second-level child connected with conj_and
                                                for my $c3  (keys(%{$rel{$c2}})) {
                                                        if (($rel{$c2}{$c3} eq "conj_and")){
                                                                $c3 =~ /^(.*)\-(\d+)$/;
                                                                my $ch3 = $1;
                                                                if (name_match($c3, $prot2)){

                                                                        print "$pmid|#|$sent_id|#|$type|#|$prot2|#|$prot1|#|$sent\n";
                                                                        push @interactions, Clair::Bio::GIN::Interaction->new($prot2,$prot1,$type,$sent,1);
                                                                }
                                                        }
                                                }#for
                                        }
                                }#if dobj

                        }#for c2
                }#if c
                #elsif ($c =~ $prot2){
                elsif (name_match($k2, $prot2)){
                        for my $c2  (keys(%{$rel{$k1}})) {
                                if ($rel{$k1}{$c2} eq "prep_with"){
                                        $c2 =~ /^(.*)\-(\d+)$/;
                                        my $ch2 = $1;

                                        if (name_match($c2, $prot1)){

                                                print "$pmid|#|$sent_id|#|$type|#|$prot1|#|$prot2|#|$sent\n";
                                                push @interactions, Clair::Bio::GIN::Interaction->new($prot1,$prot2,$type,$sent,1);

                                        }#if protx

                                        else{ ## look to second-level child connected with conj_and
                                                for my $c3  (keys(%{$rel{$c2}})) {
                                                        if (($rel{$c2}{$c3} eq "conj_and")){
                                                                $c3 =~ /^(.*)\-(\d+)$/;
                                                                my $ch3 = $1;
                                                                if (name_match($c3, $prot1)){

                                                                        print "$pmid|#|$sent_id|#|$type|#|$prot1|#|$prot2|#|$sent\n";
                                                                        push @interactions, Clair::Bio::GIN::Interaction->new($prot1,$prot2,$type,$sent,1);
                                                                }
                                                        }
                                                }#for
                                        }

                                }#if dobj

                        }#for c2
                }#if c

        }# if exists
}

###########################################################################################
##############Rule 7: Active sentence: nsubj, predicate, prep_to###########################
##############first level child or second level child connected with conj_and is a prot####
###########################################################################################

sub rule7{

        my ($k1, $k2, $prot1, $prot2, $sent) = @_;

        $k1 =~ /^(.*)\-(\d+)$/;
        my $p = $1;

        $k2 =~ /^(.*)\-(\d+)$/;
        my $c = $1;

        if (($type eq lc($p)) && not_neg($k1)){
                if (name_match($k2, $prot1)){
                        for my $c2  (keys(%{$rel{$k1}})) {
                                if ($rel{$k1}{$c2} eq "prep_to"){
                                        $c2 =~ /^(.*)\-(\d+)$/;
                                        my $ch2 = $1;

                                        if (name_match($c2, $prot2)){ #first level child

                                                print "$pmid|#|$sent_id|#|$type|#|$prot1|#|$prot2|#|$sent\n";
                                                push @interactions, Clair::Bio::GIN::Interaction->new($prot1,$prot2,$type,$sent,1);

                                        }#if protx
                                        else{ ## look to second-level child connected with conj_and
                                                for my $c3  (keys(%{$rel{$c2}})) {
                                                        if (($rel{$c2}{$c3} eq "conj_and")){
                                                                $c3 =~ /^(.*)\-(\d+)$/;
                                                                my $ch3 = $1;
                                                                if (name_match($c3, $prot2)){
                                                                        print "$pmid|#|$sent_id|#|$type|#|$prot1|#|$prot2|#|$sent\n";
                                                                        push @interactions, Clair::Bio::GIN::Interaction->new($prot1,$prot2,$type,$sent,1);
                                                                }
                                                        }
                                                }#for
                                        }
                                }#if dobj

                        }#for c2
                }#if c
                #elsif ($c =~ $prot2){
                elsif (name_match($k2, $prot2)){
                        for my $c2  (keys(%{$rel{$k1}})) {
                                if ($rel{$k1}{$c2} eq "prep_to"){
                                        $c2 =~ /^(.*)\-(\d+)$/;
                                        my $ch2 = $1;

                                        if (name_match($c2, $prot1)){

                                                print "$pmid|#|$sent_id|#|$type|#|$prot2|#|$prot1|#|$sent\n";
                                                push @interactions, Clair::Bio::GIN::Interaction->new($prot2,$prot1,$type,$sent,1);

                                        }#if protx

                                        else{ ## look to second-level child connected with conj_and
                                                for my $c3  (keys(%{$rel{$c2}})) {
                                                        if (($rel{$c2}{$c3} eq "conj_and")){
                                                                $c3 =~ /^(.*)\-(\d+)$/;
                                                                my $ch3 = $1;
                                                                if (name_match($c3, $prot1)){

                                                                        print "$pmid|#|$sent_id|#|$type|#|$prot2|#|$prot1|#|$sent\n";
                                                                        push @interactions, Clair::Bio::GIN::Interaction->new($prot2,$prot1,$type,$sent,1);

                                                                }
                                                        }
                                                }#for
                                        }

                                }#if dobj

                        }#for c2
                }#if c

        }# if exists
}

###########################################################################################
####Rule 8: Active sentence: binding, prep_of, domains prep_of Prot1 prep_to Prot2#########
####first level child or second level child connected with conj_and is a prot##############
###########################################################################################

sub rule8{

        my ($k1, $k2, $prot1, $prot2, $sent) = @_;

        $k1 =~ /^(.*)\-(\d+)$/;
        my $p = $1;

        $k2 =~ /^(.*)\-(\d+)$/;
        my $c = $1;

        if (($type eq lc($p)) && not_neg($k1) && ($c =~ /domain/i)){

                        for my $c2  (keys(%{$rel{$k2}})) {
                                if ($rel{$k2}{$c2} eq "prep_of"){
                                        $c2 =~ /^(.*)\-(\d+)$/;
                                        my $ch2 = $1;

                                        if (name_match($c2, $prot1)){
                                                for my $c3  (keys(%{$rel{$c2}})) {
                                                        if (($rel{$c2}{$c3} eq "prep_to")){
                                                                $c3 =~ /^(.*)\-(\d+)$/;
                                                                my $ch3 = $1;
                                                                if (name_match($c3, $prot2)){
                                                                        print "$pmid|#|$sent_id|#|$type|#|$prot1|#|$prot2|#|$sent\n";
                                                                        push @interactions, Clair::Bio::GIN::Interaction->new($prot1,$prot2,$type,$sent,1);
                                                                }

                                                        }

                                                }

                                        }#if name_match(prot1)

                                        elsif (name_match($c2, $prot2)){
                                                for my $c3  (keys(%{$rel{$c2}})) {
                                                        if (($rel{$c2}{$c3} eq "prep_to")){
                                                                $c3 =~ /^(.*)\-(\d+)$/;
                                                                my $ch3 = $1;
                                                                if (name_match($c3, $prot1)){
                                                                        print "$pmid|#|$sent_id|#|$type|#|$prot2|#|$prot1|#|$sent\n";
                                                                        push @interactions, Clair::Bio::GIN::Interaction->new($prot2,$prot1,$type,$sent,1);
                                                                }

                                                        }

                                                }

                                        }#elsif name_match(prot2)


                                }#if prep_of

                        }#for c2

        }# if type eq
}

###########################################################################################
##############Rule 9: Active sentence: predicate, prep_of, prep_with###################
##############first level child or second level child connected with conj_and is a prot####
###########################################################################################

sub rule9{

        my ($k1, $k2, $prot1, $prot2, $sent) = @_;

        $k1 =~ /^(.*)\-(\d+)$/;
        my $p = $1;

        $k2 =~ /^(.*)\-(\d+)$/;
        my $c = $1;

        if (($type eq lc($p)) && not_neg($k1)){
                if (name_match($k2, $prot1)){
                        for my $c2  (keys(%{$rel{$k2}})) {
                                if ($rel{$k2}{$c2} eq "prep_with"){
                                        $c2 =~ /^(.*)\-(\d+)$/;
                                        my $ch2 = $1;

                                        if (name_match($c2, $prot2)){ #first level child

                                                print "$pmid|#|$sent_id|#|$type|#|$prot1|#|$prot2|#|$sent\n";
                                                push @interactions, Clair::Bio::GIN::Interaction->new($prot1,$prot2,$type,$sent,1);

                                        }#if protx

                                }#if dobj

                        }#for c2
                }#if c
                #elsif ($c =~ $prot2){
                elsif (name_match($k2, $prot2)){
                        for my $c2  (keys(%{$rel{$k2}})) {
                                if ($rel{$k2}{$c2} eq "prep_with"){
                                        $c2 =~ /^(.*)\-(\d+)$/;
                                        my $ch2 = $1;

                                        if (name_match($c2, $prot1)){

                                                print "$pmid|#|$sent_id|#|$type|#|$prot2|#|$prot1|#|$sent\n";
                                                push @interactions, Clair::Bio::GIN::Interaction->new($prot2,$prot1,$type,$sent,1);

                                        }#if protx

                                }#if dobj

                        }#for c2
                }#if c

        }# if exists
}

###########################################################################################
##############                Protein Name Match function       ###########################
###########################################################################################

sub name_match{

        my ($p, $prot) = @_;

        #$prot = lc($prot); #convert protein name to lower-case

        $p =~ /^(.*)\-(\d+)$/;
        my $p_c = $1;

        #my @p_fields = split(/-/,$p);

        #my $p_c = $p_fields[0];

        #for (my $i = 1; $i < $#p_fields; $i++){
        #        $p_c = $p_c." ".$p_fields[$i];
        #}


        my $matches = 0;

        #print $prot . " ---- " . quotemeta("$p_c") . "\n";
        if ($prot eq $p_c){
                $matches = 1;
                #print $p_c, "\n";
        }
        elsif ($prot =~ $p_c){
                $matches = 0;
                for my $c  (keys(%{$rel{$p}})) {
                        #my @c_fields = split(/-/,$c);
                        #my $c_c = $c_fields[0];

                        $c =~ /^(.*)\-(\d+)$/;
                        my $c_c = $1;

                        #for (my $i = 1; $i < $#c_fields; $i++){
                        #        $c_c = $c_c." ".$c_fields[$i];
                        #}


                        if ($prot =~ $c_c){
                                #if ($c_c !~ "-"){
                                $matches = 1;
                                last;
                                #}
                        }

                }#for

        }

        return $matches;

}

###########################################################################################
##############                Identify negation                 ###########################
###########################################################################################

sub not_neg{
## negation is true, if the predicate has a negation child
        my ($predicate) = @_;
        my $not_negation = 1;
        for my $c  (keys(%{$rel{$predicate}})) {
                        if ($rel{$predicate}{$c} eq "neg"){
                                $not_negation = 0;
                                last;
                        }
        }
        return $not_negation;
}

1;

__END__

=pod

=head1 NAME

Clair::Bio::GIN - Gene Interaction Extraction

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

       use Clair::Bio::GIN;
       $sentence=shift;
       $gin = Clair::Bio::GIN->new();
       $interaction_words = $gin->tag_interaction_words($sentence);
       foreach $word (@$interaction_words){
                print $word,"\n";
       }
       $genes = $gin->tag_genes($sentence);
       foreach $gene (@$genes){
                print $gene,"\n";
       }
       if($gin->is_speculative($sentence)==1){
              print "Speculative\n";
       }else{
              print "Not Speculative\n";
       }
       print $gin->dependency_parse($sentence);
       @interations = $gin->extract_interactions($sentence);
       # @interactions is an array of Clair::Bio::GIN::Interaction objects

=head1 METHODS

=head2 new

Function  : Creates a new instance of the Clair::Bio::GIN

Usage     : $gin = Clair::Bio::GIN->new();

Parameters: nothing

returns   : Clair::Bio::GIN obejct

=head2 tag_genes

Function  : Finds the protiens and genes in a sentence.

Usage     : $genes = $gin->tag_genes($sentence);

Parameters: A sentence

returns   : A reference for an array of strings (gene names).

=head2 tag_interaction_words

Function  : Finds the interaction words in a sentence.

Usage     : $interaction_words = $gin->tag_interaction_words($sentence);

Parameters: A sentence

returns   : A reference for an array of strings (interaction words.)

=head2 dependency_parse

Function  : Parses a sentence using the stanford dependancy parser.

Usage     : $parse = $gin->dependency_parse($sentence);

Parameters: A sentence

returns   : A string (The output of the stanford depedancy parser,)

=head2 is_speculative

Function  : Checks whether a sentence is speculative or not.

Usage     : $gin->is_speculative($sentence);

Parameters: A sentence

returns   : 1 if speculative and 0, otherwise.

=head2 extract_interactions

Function  : Extracts the gene interactions from a text.

Usage     : @interactions = $gin->extract_interactions($text);

Parameters: A text (string)

returns   : An array of Clair::Bio::GIN::Interaction instances.

=head1 AUTHOR

Amjad Abu Jbara << <clair at umich.edu> >>

Arzucan Ozgur << <clair at umich.edu> >>

=cut