package Clair::Cluster;

use warnings;
use strict;

use Data::Dumper;

use Clair::Network;
use Clair::Document;
use Clair::Config;
use Math::Random;
use Clair::Utils::SimRoutines;
use Scalar::Util qw(looks_like_number);
use Clair::Network::Centrality::LexRank;

################################################################################
#
# Cluster class
#
################################################################################

sub new {
        my $class = shift;
        my %parameters = @_;

        my %documents = ();

        if (exists $parameters{documents}) {
                my $documents_ref = $parameters{documents};
                %documents = %$documents_ref;
        }

        my $self = bless {
                documents => \%documents,
        id => $parameters{id}
        }, $class;

        return $self;
}

sub get_id {
    my $self = shift;
    return $self->{id};
}

sub set_id {
    my $self = shift;
    my $id = shift;
    $self->{id} = $id;
}

sub insert {
        my $self = shift;

        my $id = shift;
        my $document = shift;

        my $documents_ref = $self->{documents};

        $documents_ref->{$id} = $document;
}


sub has_document {
    my $self = shift;
    my $id = shift;

    return $self->{documents}->{$id};
}


sub documents {
        my $self = shift;

        return $self->{documents};
}


sub classes {
        my $self = shift;

        my $docsref = $self->documents();
        my %classes;
        foreach my $id (keys %$docsref) {
                my $class = $docsref->{$id}->get_class();
                $classes{$class}++ if (defined $class);
        }

        return %classes;
}


sub documents_by_class {
        my $self = shift;

        my $docsref = $self->documents();
        my %docs_by_class;
        foreach my $id (keys %$docsref) {
                my $class = $docsref->{$id}->get_class();
                if (defined $class) {
                        $docs_by_class{$class}->{$id} = 1;
                }
        }

        return %docs_by_class;
}


sub get_class {
        my $self = shift;
        my $id = shift;

        return $self->get($id)->get_class();
}


sub set_class {
        my $self = shift;
        my $id = shift;
        my $label = shift;

        $self->get($id)->set_class($label);
}


sub tf {
        my $self = shift;
        my %params = @_;
        my $type = $params{type} || "stem";

        my %c_tf;
        my $docsref = $self->documents();
        foreach my $id (keys %$docsref) {
                my %doc_tf = $docsref->{$id}->tf(type => $type);
                foreach my $term (keys %doc_tf) {
                        $c_tf{$term} += $doc_tf{$term};
                }
        }

        return %c_tf;
}


sub docterm_matrix {
        my $self = shift;
        my %params = @_;
        my $type = $params{type} || "stem";

        my @matrix;
        my $docsref    = $self->documents();
        my @uniq_words = sort $self->get_unique_words(type => $type);
        my @docids     = sort keys %$docsref;
        foreach my $id (@docids) {
                my %doc_tf = $docsref->{$id}->tf(type => $type);
                my @vector;
                foreach my $word (@uniq_words) {
                        push @vector, $doc_tf{$word} || 0;
                }
                push @matrix, \@vector;
        }

        return (\@matrix, \@docids, \@uniq_words);
}


sub extract_sample_cluster{
  my $self=shift;
  my $sample_size=shift;
  my %hash = ();
  my $i = 0;
  while ($i < $sample_size) {
    my $x = random_uniform_integer(1, 0, $self->count_elements()-1);
    if (not defined $hash{$x}) {
      $hash{$x} = 1;
      $i++;
    }
  }
  my $docs=$self->documents();
  my @docs_keys = keys %$docs;
  my $sample_cluster=new Clair::Cluster();
  foreach my $id (keys %hash)
  {
      $sample_cluster->insert($docs_keys[$id],$self->get($docs_keys[$id]));
  }
  return $sample_cluster;
}

sub build_idf {
        my $self = shift;
        my $dbm_file = shift;

        my %parameters = @_;

        my $type = 'text';
        if (exists $parameters{type}) {
                $type = $parameters{type};
        }

        if ($type ne 'html' and $type ne 'text' and $type ne 'stem') {
                die "Type must be 'html, 'text', or 'stem'.";
        }

        my %token_hash;
        dbmopen(%token_hash, $dbm_file, 0666);
        %token_hash = ();

        my $count = 0;

        my %documents = %{ $self->{documents} };

        foreach my $doc (values %documents) {
                $count++;
                print "Looking at document $count\n";

                my @words = $doc->split_into_words(type => $type);
                my %looked = ();

                foreach my $w (@words) {
                        $w =~ s/^\\[0-9]+//;
                        $w =~ s/^[\.\"\-\_\+\\\`\~\!\&\(\)\[\]\{\}\'\;\:\&\*\?\,]+//;
                        $w =~ s/[\.\"\-\_\+\\\`\~\!\&\(\)\[\]\{\}\'\;\:\&\*\?\,]+$//;

                        if ($w =~ /^\s*$/ || exists $looked{$w}) { next; }
                        if ($token_hash{$w} and $token_hash{$w} > 0) {
                                $token_hash{$w}++;
                        } else {
                                $token_hash{$w} = 1;
                        }

                        $looked{$w}++;
                }
        }

        foreach my $w (keys %token_hash) {
                if (0.5+$token_hash{$w} != 0) {
                        $token_hash{$w} = log(($count+1)/(0.5+$token_hash{$w}));
                }
        }

        return %token_hash;
}


sub load_documents {
        my $self = shift;
        my $document_expr = shift;
        my %parameters = @_;

        my $doc_type = 'text';
        if (exists $parameters{type}) {
                $doc_type = $parameters{type};

                if ($doc_type ne 'text' and $doc_type ne 'html' and $doc_type ne 'stem') {
                        die "Document type must be \'html\', \'text\', or \'stem\'.";
                }
        }
        my $filename_id = 1;
        if ( (exists $parameters{filename_id} and $parameters{filename_id} == 0) or
             (exists $parameters{count_id} and $parameters{count_id} == 1) ) {
                $filename_id = 0;
        }
        my $count = 0;
        if (exists $parameters{start_count} ) {
                $count = $parameters{start_count};
        }

        open (LS, "ls -1 $document_expr |") or die "Could not run ls: $!";
        while ( <LS> ) {
                chomp;
                my $file = $_;

                my $id;
                if ($filename_id == 1) {
                        $id = $file;
                } else {
                        $id = $count;
                }
                my $doc = new Clair::Document(type => $doc_type, file => $file, id => $id);
                $self->insert($id, $doc);

                $count++;
        }

        close LS;
        return $count;
}


sub load_file_list_from_file {
        my $self = shift;
        my $filename = shift;

        my %parameters = @_;

        my @filelist = ();

        open (LIST, "< $filename") or die "Unable to open file: $filename";
        while ( <LIST> ) {
                chomp;
                my $file = $_;

                push(@filelist, $file);
        }
    close LIST;

        return $self->load_file_list_array(\@filelist, %parameters);
}

sub load_lines_from_file {
        my $self = shift;
        my $filename = shift;

        my %parameters = @_;

        my $doc_type = 'text';
        if (exists $parameters{type}) {
                $doc_type = $parameters{type};

                if ($doc_type ne 'text' and $doc_type ne 'html' and $doc_type ne 'stem') {
                        die "Document type must be \'html\', \'text\', or \'stem.\'";
                }
        }

        my $id_prefix = '';
        if (exists $parameters{id_prefix}) {
                $id_prefix = $parameters{id_prefix};
        }

        open (IN, "< $filename") or die "Coudln't open $filename: $!";
        my $count = 0;
        if (exists $parameters{start_count} ) {
                $count = $parameters{start_count};
        }

        while ( <IN> ) {
                chomp;
                my $sentence = $_;

                my $id = $id_prefix . $count;

                my $doc = new Clair::Document(type => $doc_type, string => $sentence, id => $id);
                $self->insert($id, $doc);

                ++$count;
        }
    close IN;

        return $count;
}

sub load_file_list_array {
        my $self = shift;
        my $filelist_ref = shift;
        my @filelist = @$filelist_ref;

        my %parameters = @_;

        my $doc_type = 'text';
        if (exists $parameters{type}) {
                $doc_type = $parameters{type};

                if ($doc_type ne 'text' and $doc_type ne 'html' and $doc_type ne 'stem') {
                        die "Document type must be \'html\', \'text\', or \'stem.\'";
                }
        }

        my $filename_id = 1;
        if ( (exists $parameters{filename_id} and $parameters{filename_id} == 0) or
             (exists $parameters{count_id} and $parameters{count_id} == 1) ) {
                $filename_id = 0;
        }

        my $count = 0;
        if (exists $parameters{start_count} ) {
                $count = $parameters{start_count};
        }

        foreach my $file (@filelist) {
                my $id;
                if ($filename_id == 1) {
                        $id = $file;
                } else {
                        $id = $count;
                }

                my $doc = new Clair::Document(type => $doc_type, file => $file, id => $id);
                $self->insert($id, $doc);

                $count++;
        }

        return $count;
}

sub strip_all_documents {
        my $self = shift;
        my %documents = %{ $self->{documents} };

        foreach my $doc (values %documents) {
                $doc->strip_html;
        }
}


sub stem_all_documents {
        my $self = shift;
        my %documents = %{ $self->{documents} };

        foreach my $doc (values %documents) {
                $doc->stem;
        }
}


sub get {
        my $self = shift;
        my $id = shift;

        my $documents_ref = $self->{documents};

        return $documents_ref->{$id};
}


sub count_elements {
        my $self = shift;

        my $documents_ref = $self->{documents};

        return scalar keys %$documents_ref;
}

sub create_sentence_based_network {
        my $self = shift;

        my %documents = %{ $self->{documents} };

        my %params = @_;

        my $c = $self->create_sentence_based_cluster();

        my %cos_hash = $c->compute_cosine_matrix(text_type => 'text');

        if (exists $params{threshold} and $params{threshold} != 0) {
                my $threshold = $params{threshold};
                %cos_hash = $c->compute_binary_cosine($threshold);
        }

        my $include_zeros = 0;
        if (exists $params{include_zeros} and $params{include_zeros} == 1) {
                $include_zeros = 1;
        }

        return $c->create_network(cosine_matrix => \%cos_hash, include_zeros => $include_zeros);
}

sub create_sentence_based_cluster {
        my $self = shift;

        my %documents = %{ $self->{documents} };

        my $c = Clair::Cluster::->new();

        foreach my $doc (values %documents) {
                my @sentences = $doc->split_into_sentences;
                my $doc_id = $doc->get_id;

                my $count = 0;

                foreach my $sent (@sentences) {
                        ++$count;
                        my $sent_id = $doc_id . $count;
                        my $new_doc = Clair::Document::->new(type => 'text', string => "$sent", id => "$sent_id");
                        $new_doc->set_parent_document($doc);
                        $c->insert($sent_id, $new_doc);
                }
        }

        return $c;
}



sub create_lexical_network {
  my $self = shift;
  my %params = @_;
  my $docs = $self->documents();

  my $network = Clair::Network->new(directed=>0);
  foreach my $did (keys %$docs) {
    my $doc = $docs->{$did};
    #print $doc->get_text(),"\n";
    my @sents = $doc->split_into_sentences();
      print "Don Num = ", scalar(@sents),"\n";
    foreach my $sent (@sents) {
      chomp $sent;
      my @words = split(/ /, $sent);
      foreach my $word (@words) {
        $word = lc $word;
        if (not $network->has_node($word)) {
            $network->add_node($word, $word);
        }
        foreach my $word2(@words){
          if (not $network->has_edge($word,$word2)) {
              $network->add_weighted_edge($word, $word2,1);
          }else{
              my $w = $network->get_edge_weight($word,$word2);
              $network->set_edge_weight($word,$word2,$w+1);
          }
        }
      }
    }
  }
  return $network;
}


sub compute_cosine_matrix {
        my $self = shift;
        my %parameters = @_;

        my $text_type = "stem";
        if (exists $parameters{text_type}) {
                $text_type = $parameters{text_type};
        }

  my %documents = %{ $self->{documents} };
  my $i = 0;
  my $j = 0;
  my $counter = 0;
  my %cos_hash = ();
  my @all=();
  my $c=0;

  foreach my $doc_key (keys %documents) {
    $i = 0;
    $j++;
    $cos_hash{$doc_key} = ();
    foreach my $doc_key2 (keys %documents) {
         $i++;
         last if ($i>$j-1);
         #print "add $c : $doc_key,$doc_key2 ($i,$j) \n";
         $c++;
         push(@all,[$doc_key,$doc_key2]);
    }
  }
  my $max=scalar(@all);
  if (exists $parameters{sample_size} && $parameters{sample_size}<$max) {
      my $sample_size = $parameters{sample_size};
      my %hash = ();
      my $k = 0;
      while ($k < $sample_size) {
         my $x = random_uniform_integer(1, 0, $c-1);
         if (not defined $hash{$x}) {
             $hash{$x} = 1;
             $k++;
         }
      }
      foreach my $rnd (keys %hash)
      {
               my @pair=$all[$rnd];
               #use Data::Dumper;
               #print Dumper(@pair),"\n";
               my $doc_k1 =$pair[0][0];
               my $doc_k2 =$pair[0][1];
               #print "d1=$doc_k1","\n","d2=$doc_k2","\n";
               my $doc1 = $documents{$doc_k1};
               my $doc2 = $documents{$doc_k2};
               my $txt1 = "";
               my $txt2 = "";
               if ($text_type eq "stem")
               {
                      $txt1 = $doc1->get_stem;
                      $txt2 = $doc2->get_stem;
               }
               elsif ($text_type eq "text")
               {
                      $txt1 = $doc1->{text};
                      $txt2 = $doc2->{text};
               }
               my $cos1;
               $cos1 = GetLexSim($txt1, $txt2);
               $cos_hash{$doc_k1}{$doc_k2} = $cos1;
               $cos_hash{$doc_k2}{$doc_k1} = $cos1;
      }
     $self->{cosine_matrix} = \%cos_hash;
     return %cos_hash;
  }

  $j=0;
  my $size = scalar(keys %documents);
  foreach my $doc1_key (keys %documents) {
          $i = 0;
          $j++;
          my $document1 = $documents{$doc1_key};
	#print Dumper($documents{$doc1_key});
	#print "\n";

          foreach my $doc2_key (keys %documents) {
                  $i++;
                  my $document2 = $documents{$doc2_key};
#print Dumper($documents{$doc2_key});
#print "\n";

                  if ($i < $j) {
                          my $text1 = "";
                          my $text2 = "";
                          if ($text_type eq "stem")
                          {
                                  $text1 = $document1->get_stem;
                                  $text2 = $document2->get_stem;
                          }
                          elsif ($text_type eq "text")
                          {
                                  $text1 = $document1->{text};
                                  $text2 = $document2->{text};
                          }
                          my $cos;
                          $cos = GetLexSim($text1, $text2);

                          $cos_hash{$doc1_key}{$doc2_key} = $cos;
                          $cos_hash{$doc2_key}{$doc1_key} = $cos;
                          $counter++;
                          last if ($counter == $size*($size-1));
                  }
          }
          last if ($counter == $size*($size-1));
  }
  $self->{cosine_matrix} = \%cos_hash;
  return %cos_hash;
}

sub get_largest_cosine {
        my $self = shift;
        my %parameters = @_;

        my %cos_matrix = ();
        if (exists $parameters{cosine_matrix}) {
                %cos_matrix = %{ $parameters{cosine_matrix} };
        }
        elsif (exists $self->{cosine_matrix}) {
                %cos_matrix = %{ $self->{cosine_matrix} };
        }
        else {
                die "Must specify cosine matrix.";
        }

        my $largest_cosine = -1;
        my $largest_key1 = '';
        my $largest_key2 = '';

        foreach my $doc1_key (keys %cos_matrix)
        {
                foreach my $doc2_key (keys %{ $cos_matrix{$doc1_key} })
                {
                        if ($largest_cosine < $cos_matrix{$doc1_key}{$doc2_key})
                        {
                                $largest_cosine = $cos_matrix{$doc1_key}{$doc2_key};
                                $largest_key1 = $doc1_key;
                                $largest_key2 = $doc2_key;
                        }
                }
        }

        my %retHash = ();
        $retHash{'value'} = $largest_cosine;
        $retHash{'key1'} = $largest_key1;
        $retHash{'key2'} = $largest_key2;

        return %retHash;
}

sub compute_binary_cosine {
        my $self = shift;
        my $threshold = shift;

        my %cos_matrix;
        if ($self->{cosine_matrix}) {
                %cos_matrix = %{ $self->{cosine_matrix} };
        } else {
                %cos_matrix = $self->compute_cosine_matrix();
        }

        my %retHash = ();

        foreach my $doc_key (keys %cos_matrix) {
                $retHash{$doc_key} = ();
        }

        foreach my $doc1_key (keys %cos_matrix)
        {
                foreach my $doc2_key (keys %{ $cos_matrix{$doc1_key} })
                {
                        if ($cos_matrix{$doc1_key}{$doc2_key} >= $threshold)
                        {
                                $retHash{$doc1_key}{$doc2_key} = $cos_matrix{$doc1_key}{$doc2_key};
                        }
                        else
                        {
                                $retHash{$doc1_key}{$doc2_key} = 0;
                        }
                }
        }

        return %retHash;
}


sub create_genprob_network {
        my $self = shift;
        my %params = @_;

# Just create a regular cosine network using the genprob matrix
        $params{cosine_matrix} = $params{genprob_matrix};
        my $network = $self->create_network(%params);

# ... but make sure to reset the diagonal to 0
        foreach my $v ($network->get_vertices) {
                $network->set_vertex_attribute($v, "lexrank_transition", 0);
        }

        return $network;

}


sub create_network {
        my $self = shift;

        my %parameters = @_;

        my %cos_matrix = ();
        if (exists $parameters{cosine_matrix}) {
                %cos_matrix = %{ $parameters{cosine_matrix} };
        } elsif (exists $self->{cosine_matrix}) {
                %cos_matrix = $self->{cosine_matrix};
        } else {
                die "Must specify cosine matrix.";
        }

        my $include_zeros = 0;
        if (exists $parameters{include_zeros} && $parameters{include_zeros} == 1) {
                $include_zeros = 1;
        }

        my $property = 'lexrank_transition';
        if (exists $parameters{property}) {
                $property = $parameters{property};
        }

        my $network = Clair::Network->new();

# Add the edges to the graph
# (Vertices will be added automatically)
        foreach my $doc1 (keys %cos_matrix)
        {
                foreach my $doc2 (keys %{ $cos_matrix{$doc1} })
                {
                        if ($cos_matrix{$doc1}{$doc2} != 0 || $include_zeros)
                        {
                                if (not $network->has_node($doc1)) {
                                        $network->add_node($doc1, document => $self->get($doc1));
                                }
                                if ($doc1 ne $doc2) {
                                        if (not $network->has_node($doc2)) {
                                                $network->add_node($doc2, document => $self->get($doc2));
                                        }
                                        $network->add_edge($doc1, $doc2);
                                        $network->set_edge_attribute($doc1, $doc2, $property, $cos_matrix{$doc1}{$doc2});
                                }
                        }
                }
        }

# Set the cos value to 1 on the diagonal
        foreach my $v ($network->get_vertices) {
                $network->set_vertex_attribute($v, $property, 1);
        }

        return $network;
}


sub create_hyperlink_network_from_array {
        my $self = shift;

        my $hyperlinks_ref = shift;
        my @hyperlinks = @$hyperlinks_ref;

        my %parameters = @_;

        my $property = 'pagerank_transition';
        if (exists $parameters{property}) {
                $property = $parameters{property};
        }

        my $network = new Clair::Network;

        foreach my $h (@hyperlinks) {
                my ($u_id, $v_id) = @$h;

                my $u = $self->get($u_id);
                my $v = $self->get($v_id);
                my $add_u = $u_id;
                my $add_v = $v_id;

                if (not $network->has_node($add_u)) {
                        $network->add_node($add_u, document => $u);
                }

                if ($u_id ne $v_id) {
                        if (not $network->has_node($add_v)) {
                                $network->add_node($add_v, document => $v);
                        }

                        $network->add_edge($add_u, $add_v);
                        $network->set_edge_attribute($add_u, $add_v, $property, 1);
                } else {
                        $network->add_node($add_u);
                        $network->set_vertex_attribute($add_u, $property, 1);
                }
        }

        return $network;
}


sub create_hyperlink_network_from_file {
        my $self = shift;

        my $filename = shift;

        my %parameters = @_;
        my @hyperlink_array;

        open(FILE, "< $filename") or die "Coudln't open $filename: $!";

        while (<FILE>) {
                next unless m/(.+) (.+)/;

                my $u = $1;
                my $v = $2;

                my @link = ($u, $v);
                push(@hyperlink_array, \@link);
        }

        close(FILE);

        return $self->create_hyperlink_network_from_array(\@hyperlink_array, %parameters);
}


sub write_cos {
        my $self = shift;
        my $filename = shift;

        my %parameters = @_;

        my %cos_matrix = ();
        if (exists $parameters{cosine_matrix}) {
                %cos_matrix = %{ $parameters{cosine_matrix} };
        } elsif (exists $self->{cosine_matrix}) {
                %cos_matrix = %{ $self->{cosine_matrix} };
        } else {
                die "Must specify cosine matrix.";
        }

        my $round = 0;
        if (exists $parameters{round} and $parameters{round} == 1) {
                $round = 1;
        }

        my $write_zeros = 1;
        if (exists $parameters{write_zeros} && $parameters{write_zeros} == 0) {
                $write_zeros = 0;
                print("write_zero is false!\n");
        }

        open FILE, "> $filename" or die "Coudln't open $filename: $!";

        foreach my $doc1 (keys %cos_matrix) {
                foreach my $doc2 (keys %{ $cos_matrix{$doc1} }) {
                        if ($cos_matrix{$doc1}{$doc2} != 0 || $write_zeros != 0) {
                                my $cos;
                                if ($round) {
                                        $cos = Clair::Util::round_number($cos_matrix{$doc1}{$doc2},4);
                                } else {
                                        $cos = $cos_matrix{$doc1}{$doc2};
                                }
                                print FILE "$doc1 $doc2 $cos\n";
                        }
                }
        }

        close FILE;
}


sub save_documents_to_directory {
        my $self = shift;
        my %docs = %{$self->{documents} };
        my $directory = shift;
        my $type = shift;

        my %parameters = @_;

# Use a count to name the documents, rather than the id
        my $name_count = 1;

        if ( (exists $parameters{name_id} and $parameters{name_id} == 1) or
                        (exists $parameters{name_count} and $parameters{name_count} == 0) ) {
                $name_count = 0;
        }

        my $count = 0;
        foreach my $doc (values %docs) {
                my $filename;
                if ($name_count == 1) {
                        $filename = $directory . '/' . $count;
                } else {
                        $filename = $directory . '/' . $doc->get_id;
                }

                $doc->save(file => $filename, type => $type);

                $count++;
        }

}


sub save_documents_to_file {
        my $self = shift;
        my %docs = %{$self->{documents} };
        my $filename = shift;
        my $type = shift;

        my %parameters = @_;

        open FOUT, "> $filename" or die "Couldn't open file: $!";

        foreach my $doc (values %docs) {
                my $body = "";
                if ($type eq 'text') {
                        $body = $doc->get_text();
                } elsif ($type eq 'html') {
                        $body = $doc->get_html();
                } elsif ($type eq 'xml') {
                        $body = $doc->get_xml();
                } elsif ($type eq 'stem') {
                        $body = $doc->get_stem();
                }
                print FOUT $body;
                print FOUT "\n";
        }

        close FOUT;
}


sub get_unique_words {
        my $self = shift;
        my %params = @_;

        my %words;
        my $docsref = $self->{documents};
        foreach my $id (keys %$docsref) {
                my $doc = $docsref->{$id};
                map { $words{$_} = 1 } $doc->get_unique_words(%params);
        }
        return keys %words;
}


sub compute_genprob_matrix {

        my $self = shift;
        my %params = @_;
        $params{genprob} = $GENPROB unless $params{genprob};

        my %word_map;
        my $i = 0;
        foreach my $word ($self->get_unique_words()) {
                $word_map{$word} = $i++;
        }

        my %docmap;
        my %total_freq;
        my $docsref = $self->{documents};

# Write the term frequency file
        open TF, "> tf.temp" or die "Couldn't open file: $!";
        $i = 0;
        foreach my $id (keys %$docsref) {
                my $doc = $docsref->{$id};
                my %tf = $doc->tf();
                $docmap{$i} = $id;
#my $numwords = scalar keys %tf;
                my $numwords = $doc->split_into_words( type => "stem" );
                foreach my $word (keys %tf) {
                        my $tf = $tf{$word} * $numwords;
                        $total_freq{$word} += $tf;
                        print TF "$i\t$word_map{$word}\t$tf\n";
                }
                $i++;
        }
        close TF;

# Write the MLE file
        open MLE, "> mle.temp" or die "Couldn't open file: $!";
        my $total_words;
        map { $total_words += $total_freq{$_} } keys %total_freq;
        foreach my $word (keys %total_freq) {
                my $val = $total_freq{$word} / $total_words;
                print MLE "$word_map{$word}\t$val\n";
        }
        close MLE;

# Run the command
        my $total_docs = scalar keys %docmap;
        my @lines =
                `$params{genprob} tf.temp mle.temp 1000 $total_docs $total_words`;

        unless (@lines) {
                warn "Bad genprob output";
                return undef;
        }

# remove the temp files
        unlink("tf.temp") or warn "Couldn't unlink tf.temp: $!";
        unlink("mle.temp") or warn "Couldn't unlink mle.temp: $!";

# Save to a matrix
        my %matrix;
        foreach my $line (@lines) {
                chomp $line;
                my ($from, $to, $val) = split / /, $line;
                my $id1 = $docmap{$from};
                my $id2 = $docmap{$to};
                if (defined $id1 && defined $id2 && defined $val) {
                        unless ($matrix{$id1}) {
                                $matrix{$id1} = {};
                        }
                        $matrix{$id1}->{$id2} = $val;
                } else {
                        warn "Bad genprob output";
                        return undef;
                }
        }

# Make sure matrix has zero diagonal
        foreach my $id (keys %matrix) {
                $matrix{$id}->{$id} = 0;
        }

        return %matrix;

}


sub compute_lexrank {

        my $self = shift;
        my %params = @_;

        my $cutoff = 0.15;
        $cutoff = $params{cutoff} if $params{cutoff};

        my $matrix = $self->{cosine_matrix};
        my $cmatrix = {};
        unless ($matrix) {
                my %m = $self->compute_cosine_matrix( type => $params{type} );
                $matrix = \%m;
        }
        foreach my $k1 (keys %$matrix) {
                $cmatrix->{$k1} = {} unless $cmatrix->{$k1};
                foreach my $k2 (keys %{$matrix->{$k1}}) {
                        if ($matrix->{$k1}->{$k2} >= $cutoff) {
                                $cmatrix->{$k1}->{$k2} = $matrix->{$k1}->{$k2};
                        } else {
                                $cmatrix->{$k1}->{$k2} = 0;
                        }
                }
        }

        my $n = $self->create_network(
                        cosine_matrix => $cmatrix,
                        include_zeros => 1
                        );

        my $cent = Clair::Network::Centrality::LexRank->new($n);

        $cent->centrality(%params);

        my %scores;
        my @verts = $n->get_vertices();
        foreach my $v (@verts) {
                $scores{$v} = $n->get_vertex_attribute($v, "lexrank_value");
        }

        return %scores;
}


sub compute_sentence_features {
        my $self = shift;
        my %features = @_;

        foreach my $name (keys %features) {
                $self->compute_sentence_feature( name => $name,
                                feature => $features{$name} );
        }
}


sub compute_sentence_feature {

        my $self = shift;
        my %params = @_;
        my ($name, $sub) = ($params{name}, $params{feature});
        my $norm = $params{normalize};

        return undef unless defined $name and defined $sub;
        my $docs = $self->documents();

        my $state = {};

        foreach my $did (keys %$docs) {

                my $doc = $docs->{$did};
                my @sents = $doc->get_sentences();

                foreach my $i ( 0 .. $#sents ) {

                        my %params = (
                                        document => $doc,
                                        sentence => $sents[$i],
                                        sentence_index => $i,
                                        cluster => $self,
                                        state => $state
                                     );

                        my $value;
                        eval {
                                $value = &$sub(%params);
                        };

                        my $did = $self->get_id() || "no id";
                        if ($@) {
                                warn "Feature $name died processing $i in document $did: $@";
                        } elsif (not defined $value) {
                                warn "Feature $name returned undef for sent $i in doc $did";
                        } else {
                                $doc->set_sentence_feature($i, $name => $value);
                        }

                }

        }

        if ($norm) {
                return $self->normalize_sentence_feature($name);
        }

        return 1;

}


sub normalize_sentence_features {
        my $self = shift;
        my @names = @_;
        foreach my $name (@names) {
                $self->normalize_sentence_feature($name);
        }
}


sub normalize_sentence_feature {

        my $self = shift;
        my $name = shift;
        my $docs = $self->documents();

        return undef unless defined $name;

        my $total = 0;
        foreach my $did (keys %$docs) {
                my @sents = $docs->{$did}->get_sentences();
                $total += scalar @sents;
        }

        my ($min, $max) = (0, 0);
        my ($min_did, $max_did, $min_index, $max_index) = (0) x 4;

        my $first = 1;
        foreach my $did (keys %$docs) {

                my $doc = $docs->{$did};
                my @sents = $doc->get_sentences();

                for (my $i = 0; $i < @sents; $i++) {

                        my $score = $self->get_sentence_feature($did, $i, $name);

                        unless (looks_like_number($score)) {
                                warn "feature $name not numeric";
                                return undef;
                        }

                        if ($first) {
                                $min = $score;
                                $max = $score;
                                $min_did = $did;
                                $max_did = $did;
                                $first = 0;
                        }

                        if ($score > $max) {
                                $max = $score;
                                $max_index = $i;
                                $max_did = $did;
                        }

                        if ($score < $min) {
                                $min = $score;
                                $min_index = $i;
                                $min_did = $did;
                        }

                }
        }

        foreach my $did (keys %$docs) {
                my $doc = $docs->{$did};
                my @sents = $doc->get_sentences();

                for (my $i = 0; $i < @sents; $i++) {
                        my $old_score = $self->get_sentence_feature($did, $i, $name);
                        my $new_score = 1;
                        unless ($max == $min) {
                                $new_score = ($old_score - $min) / ($max - $min);
                        }
                        $self->set_sentence_feature($did, $i, $name => $new_score);
                }

        }

        return 1;

}


sub get_sentence_feature {
        my $self = shift;
        my $docs = $self->documents();
        my $did = shift;
        my $sno = shift;
        my $name = shift;

        if ($self->has_document($did)) {
                my $doc = $docs->{$did};
                return $doc->get_sentence_feature($sno, $name);
        } else {
                return undef;
        }

}


sub get_sentence_features {
        my $self = shift;
        my $docs = $self->documents();
        my $did = shift;
        my $sno = shift;

        if ($self->has_document($did)) {
                my $doc = $docs->{$did};
                return $doc->get_sentence_features($sno);
        } else {
                return undef;
        }
}

sub remove_sentence_features {
        my $self = shift;
        my $docs = $self->documents();

        foreach my $did (keys %$docs) {
                my $doc = $docs->{$did};
                $doc->remove_sentence_features();
        }
}


sub set_sentence_feature {
        my $self = shift;
        my $docs = $self->documents();
        my $did = shift;
        my $sno = shift;
        my %feats = @_;

        if ($self->has_document($did)) {
                my $doc = $docs->{$did};
                return $doc->set_sentence_feature($sno, %feats);
        } else {
                return undef;
        }
}


sub score_sentences {
        my $self = shift;
        my %params = @_;

        my $normalize = $params{normalize};
        $normalize = 1 unless defined $normalize;
        $params{normalize} = 0;

        my $docs = $self->documents();
        foreach my $did (keys %$docs) {
                my $doc = $docs->{$did};
                unless ($doc->score_sentences(%params)) {
                        return undef;
                }
        }

        if ($normalize) {
                $self->normalize_sentence_scores();
        }

        return 1;
}


sub normalize_sentence_scores {

        my $self = shift;
        my $docs = $self->documents();
        my %scores = $self->get_sentence_scores();

        my $total = 0;
        foreach my $list (values %scores) {
                $total += scalar @$list;
        }

        if (keys %scores > 0) {

                my ($min, $max) = (0, 0);
                my ($min_did, $max_did, $min_index, $max_index) = (0) x 4;

                my $first = 1;
                foreach my $did (keys %scores) {
                        my $doc = $docs->{$did};
                        my @doc_scores = $doc->get_sentence_scores();
                        for (my $i = 0; $i < @doc_scores; $i++) {

                                my $score = $doc_scores[$i];

                                if ($first) {
                                        $min = $score;
                                        $max = $score;
                                        $min_did = $did;
                                        $max_did = $did;
                                        $first = 0;
                                }

                                if ($score > $max) {
                                        $max = $score;
                                        $max_index = $i;
                                        $max_did = $did;
                                }

                                if ($score < $min) {
                                        $min = $score;
                                        $min_index = $i;
                                        $min_did = $did;
                                }

                        }
                }

                foreach my $did (keys %scores) {
                        my $doc = $docs->{$did};
                        my @doc_scores = $doc->get_sentence_scores();
                        my @doc_new_scores;
                        if ($max == $min) {
                                @doc_new_scores = (1) x scalar @doc_scores;
                        } else {
                                @doc_new_scores = map { ($_ - $min) / ($max - $min) }
                                @doc_scores;
                        }
                        foreach my $i (0 .. $#doc_new_scores) {
                                $doc->set_sentence_score($i, $doc_new_scores[$i]);
                        }
                }

                return 1;

        } else {
                return undef;
        }

}


sub get_sentence_scores {
        my $self = shift;
        my $docs = $self->documents();

        my %scores;
        foreach my $did (keys %$docs) {
                my $doc = $docs->{$did};
                my @doc_scores = $doc->get_sentence_scores();
                if (@doc_scores) {
                        $scores{$did} = \@doc_scores;
                }
        }

        return %scores;
}


sub get_sentence_score {
        my $self = shift;
        my $did = shift;
        my $sno = shift;

        my %scores = $self->get_sentence_scores();
        if (defined $scores{$did}) {
                my @scores = @{ $scores{$did} };
                if ($sno >= 0 and $sno < @scores) {
                        return $scores[$sno];
                }
        }

        return undef;
}


sub sentence_scores_computed {
        my $self = shift;
        my $docs = $self->documents();

        return 0 unless (scalar keys %$docs > 0);

        foreach my $doc (values %$docs) {
                return 0 unless $doc->sentence_scores_computed();
        }

        return 1;
}


sub compute_document_features {
        my $self = shift;
        my %features = @_;

        foreach my $name (keys %features) {
                $self->compute_document_feature(
                                name => $name,
                                feature => $features{$name} );
        }
}


sub compute_document_feature {
        my $self = shift;
        my %params = @_;
        my ($name, $sub) = ($params{name}, $params{feature});

        return undef unless defined $name and defined $sub;
        my $docs = $self->documents();

        foreach my $did (keys %$docs) {
                my $doc = $docs->{$did};

                my %params = (
                                document => $doc,
                                cluster => $self,
                             );

                my $value;
                eval {
                        $value = &$sub(%params);
                };

                my $did = $self->get_id() || "no id";
                if ($@) {
                        warn "Feature $name died processing document $did: $@";
                } elsif (not defined $value) {
                        warn "Feature $name returned undef for doc $did";
                } else {
                        $doc->set_document_feature($name => $value);
                }
        }

        return 1;

}


sub get_document_feature {
        my $self = shift;
        my $docs = $self->documents();
        my $did = shift;
        my $name = shift;

        if ($self->has_document($did)) {
                my $doc = $docs->{$did};
                return $doc->get_document_feature($name);
        } else {
                return undef;
        }

}


sub get_document_features {
        my $self = shift;
        my $docs = $self->documents();
        my $did = shift;

        if ($self->has_document($did)) {
                my $doc = $docs->{$did};
                return $doc->get_document_features();
        } else {
                return undef;
        }
}

sub remove_document_features {
        my $self = shift;
        my $docs = $self->documents();

        foreach my $did (keys %$docs) {
                my $doc = $docs->{$did};
                $doc->remove_document_features();
        }
}


sub set_document_feature {
        my $self = shift;
        my $docs = $self->documents();
        my $did = shift;
        my %feats = @_;

        if ($self->has_document($did)) {
                my $doc = $docs->{$did};
                return $doc->set_document_feature(%feats);
        } else {
                return undef;
        }
}


sub get_summary {

        my $self = shift;
        my %params = @_;

        unless ($self->sentence_scores_computed()) {
                warn "get_summary called on cluster where scores not defined";
                return undef;
        }

        my %scores = $self->get_sentence_scores();
        my @score_triples;
        foreach my $did (keys %scores) {
                my @doc_scores = @{ $scores{$did} };
                foreach my $i (0 .. $#doc_scores) {
                        push @score_triples, [ $did, $i, $doc_scores[$i] ];
                }
        }

        my $size = $params{size};
        $size = scalar @score_triples unless (defined $size and $size > 0);

        my $docs = $self->documents();
        my @summary;

# This sorting subroutine is used to get the top scores. If two
# documents have the same score, they are ordered such that
# - if they're from the same document, the sentence with the earlier
#   index comes first
# - if they're from different documents, the id of the document is
#   used to order them
        my $sortsub = sub {
                if ($b->[2] == $a->[2]) {
                        if ($b->[0] eq $a->[0]) {
                                return $a->[1] <=> $b->[1];
                        } else {
                                return $a->[0] cmp $b->[0];
                        }
                } else {
                        $b->[2] <=> $a->[2]
                }
        };

# Get the top scoring sentences
        foreach my $triple (sort $sortsub @score_triples) {
                last if (scalar @summary == $size);
                my ($did, $i, $score) = @$triple;
                my $doc = $docs->{$did};
                my @sents = $doc->get_sentences();
                my %features = $self->get_sentence_features($did, $i);
                my $sent = {
                        'did' => $did,
                        'index' => $i,
                        'text' => $sents[$i],
                        'features' => \%features,
                        'score' => $score
                };
                push @summary, $sent;
        }

# If preserve order is set to 0, just return the summary as-is.
# Otherwise, the summary sentences are sorted such that sentences
# from the same document will be in the same relative order. Documents
# will be sorted by the natural ordering of their ids, or by the
# order specified as a parameter (if available).
        $sortsub = sub {
                if ($a->{did} eq $b->{did}) {
                        return $a->{'index'} <=> $b->{'index'};
                } else {
                        return $a->{did} cmp $b->{did};
                }
        };
        my $doc_order = $params{document_order};
        if (defined $doc_order) {
                my %order_map;
                my $i = 1;
                foreach my $did (grep { $self->has_document($_) } @$doc_order) {
                        $order_map{$did} = $i++;
                }
                $sortsub = sub {
                        my ($adid, $bdid)  = ($a->{did}, $b->{did});
                        if ($adid eq $bdid) {
                                return $a->{'index'} <=> $b->{'index'};
                        } elsif (defined $order_map{$adid} and defined $order_map{$bdid}) {
                                return $order_map{$adid} <=> $order_map{$bdid};
                        } elsif (defined $order_map{$adid}) {
                                return -1;
                        } elsif (defined $order_map{$bdid}) {
                                return 1;
                        }
                };
        }

        if (defined $params{preserve_order}) {
                return @summary;
        } else {
                return sort $sortsub @summary;
        }

}

sub get_text {
        my $self = shift;
        my $docs = $self->documents();
        my $text;
        foreach my $did (keys %$docs) {
                $text .= "\n" . $docs->{$did}->get_text();
        }
        return $text;
}

sub load_corpus {
print "c0";
        my $self = shift;
        my $corpus = shift;
print "c1";
        my %parameters = @_;
print "c2";
        my $property = ( defined $parameters{property} ?
                        $parameters{propery} : 'pagerank_transition' );

        my $ignore_EX = ( defined $parameters{ignore_EX} ?
                        $parameters{ignore_EX} : 1 );
print "c3";
        my %docid_to_file = ();
print "c4";
        my $docid_to_file_dbm_file;
        if (defined $parameters{docid_to_file_dbm}) {
	print "c5";
                $docid_to_file_dbm_file = $parameters{docid_to_file_dbm};
        } else {
                my $corpus_data_dir = $corpus->get_directory() . "/corpus-data/" .
                        $corpus->get_name();
                $docid_to_file_dbm_file = $corpus_data_dir . "/" .
                        $corpus->get_name() . "-docid-to-file";
        }

        dbmopen %docid_to_file, $docid_to_file_dbm_file, 0666 or
                die "Cannot open DBM: $docid_to_file_dbm_file\n";

        my %id_hash = ();

        foreach my $id (keys %docid_to_file) {
                if (not exists $id_hash{$id}) {
                        if ($id eq "EX") {
                                $id_hash{$id} = $id;
                        } else {
                                my $filename = $docid_to_file{"$id"};
                                my ($vol, $dir, $fn) = File::Spec->splitpath($filename);
                                my $doc = Clair::Document->new(file => "$filename", id => "$fn",
                                                type => 'html');
                                $self->insert($doc->get_id, $doc);
                                $id_hash{$id} = $doc;
                        }
                }
        }
print "c6";
        return $self;
}


################################################################################
#
# Cluster Documentation
#
################################################################################

=head1 NAME

Clair::Cluster - The great new Clair::Cluster!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

use Clair::Cluster;

my $foo = Clair::Cluster->new( id => "myCluster" );
...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 new

%documents = ($id1, $doc1, $id2, $doc2);
$cluster = new Clair::Cluster(documents => \%documents, id => "myCluster");

Creates a cluster with the specified documents.  If no documents are specified,
        creates an empty cluster. An optional id parameter can be passed to
        identify this cluster with the get_id method.

        =cut

        =head2 get_id

        Returns the id of this cluster, specified in the constructor. Returns undef
        if no id is specified.

        =head2 insert

insert($id, $document)

        Insert the document into the cluster with the associated id

        =cut


        =head2 get

get($id)

        Returns the document from the cluster with that id

        =cut


        =head2 count_elements

        count_elements

        Returns the number of documents in the cluster

        =cut


        =head2 documents_by_class

        %docs_by_class = $c->documents_by_class();

        Returns a hash whose keys correspond to classes,
        each value of which is a reference to a hash with
        keys corresponding to the document ids belonging
        to that class. If a document's class is undefined,
        its id is not contained anywhere in this hash.

        =cut


        =head2 get_class

$label = $c->get_class($did)

        Returns the class of the document having the
        specified id.

        =cut


        =head2 set_class

$c->set_class($did, $label)

        Sets the class of the document having id $did
        to $label.

        =cut


        =head2 tf

        %tf = $c->tf(type => "stem")

        Splits each document in the cluster into terms of the given type,
        then returns a hash containing the term frequencies for the entire
        cluster.

        =cut

        =head2 docterm_matrix

        (\@matrix, \@docids, \@uniqterms) = $c->docterm_matrix(type => "stem")

        Returns 1) a reference to a document-term matrix over the set of
        all the documents and terms in the cluster. Each element of
        @matrix is a pointer to a bag-of-words vector representation
        for a document. Also returns 2) a reference to an array containing
        all document IDs in the cluster, sorted alphabetically, and 3) a
        reference to an array containing all words occurring in the cluster,
        also sorted alphabetically.

        =cut


        =head2 classes

%classes = $c->classes()

        Returns a hash whose keys correspond to classes,
        each value of which equals the number of documents
        in the cluster belonging to that class.

        =cut


        =head2 compute_cosine_matrix

        %cos_hash = compute_cosine_matrix(text_type => 'stem')

        Computes the cosine matrix of the documents in the cluster.  Uses the stemmed version of the
        documents unless text_type is specified (can be 'html', 'text', or 'stem').  Result is a two-
        dimensional hash--get the cosine using $cos_hash{doc1_key}{doc2_key}.

        The result is stored with the class in addition to being returned.

        =cut

        =head2 create_lexical_network

create_lexical_network()

        Convert a cluster of documents to a lexical network

        Each word in the document is a node. A edge exists between two words if they
        occur in the same sentence.  The weight of an edge corresponds to the number
        of times those words occur together.

        =cut

        =head2 get_largest_cosine

        %largest_cosine_hash = get_largest_cosine(cosine_matrix => \%cos_matrix);

        Returns a hash containing the value of the largest cosine and the keys corresponding
        to that value.  Uses the cosine matrix calculated by compute_cosine_matrix unless one is
        provided.

        The value of the largest cosine is stored with the key 'value', while the two keys that
        correspond to the largest cosine are stored in the hash with keys 'key1' and 'key2'.

        =cut


        =head2 compute_binary_cosine

        compute_binary_cosine

        Computes the binary cosine using the cosine matrix calculated by compute_cosine_matrix.
        Returns the cosine hash, similairly to compute_cosine_matrix.  Note that the binary
        cosine is NOT stored with the class.

        =cut


        =head2 create_network

        $n = create_network(cosine_matrix => \%cos_matrix, include_zeros => 1);

        Creates a network using the provided cosine matrix.  If no cosine matrix is specified,
        the one computed by compute_cosine_matrix is used.  Unless include_zeros is specified
        and is equal to 1, all documents that have a cosine of zero between them are not
        connected on the graph.

        =cut


        =head2 write_cos

        write_cos($file, cosine_matrix => \%cos_matrix);

        Writes the cosine matrix to a file.  If no cosine matrix is specified, the one compute
        by compute_cosine_matrix is used.

        =cut


        =head2 save_documents_to_file

save_documentss_to_file($filename, $type)

        Save the documents to a single file, one document per line.
        Only really makes sense for sentence-based documents.

        =cut


        =head2 build_idf

        build_idf($dbm_file, type => 'text')

        Computes idf values from the documents in the cluster.  Returns a hash of each word
        to the idf value.  The type parameter is optional, the default is 'text', but it can
        also be set to 'stem' or 'html'.

        =cut


        =head2 create_hyperlink_network_from_array

        create_hyperlink_network_from_array(\@array, property => 'pagerank_transition')

        Creates a network based with a link for each hyperlink in the array.  Each hyperlink
        should be represented as an array with the source, then the destination.

        The pagerank_transition property will be set appropriately so that pagerank can be
        run later, but another property can be set instead by defining the optional
        property parameter.

        =cut


        =head2 create_hyperlink_network_from_file

        create_hyperlink_network_from_file($filename, property => 'pagerank_transition')

        Creates a network based with a link for each hyperlink in the file.  Each hyperlink
        should be represented as a line in the file with the source, a space, and then the
        destination.

        The pagerank_transition property will be set appropriately so that pagerank can be
        run later, but another property can be set instead by defining the optional
        property parameter.

        =cut


        =head2 create_sentence_based_cluster

        create_sentence_based_cluster

        Creates a new cluster containing the sentences of each document from the original cluster.
        Each sentence becomes a new Clair::Document with the document it came from set as the parent
        document.  Its id is the parent's id with the sentence number appended to it (for example,
                        if it's the first sentence in a document with id 'blue', it's new id will be 'blue1').

        =cut


        =head2 create_sentence_based_network

create_sentence_based_network(threshold => 0.2, include_zeros => 0)

        Creates a new network containing the sentences of each document from the cluster and links
        for each node with an appropriate lexical similarity.

        Each sentence becomes a new Clair::Document with the document it came from set as the parent
        document.  Its id is the parent's id with the sentence number appended to it (for example,
                        if it's the first sentence in a document with id 'blue', it's new id will be 'blue1').

        The lexical similarity is computed for the new cluster.  If an optional threshold is specified
        that is not zero, then similarities that are less than the threshold are set to zero.

        A link is only made if the lexical similarity between two sentences is greater than zero OR the
        optional parameter include_zeros has been set to 1.


        =cut


        =head2 load_documents

        load_documents("docs/*.txt", type => 'text', filename_id => 1)

        Loads all documents matching the expression given as the first parameter into the cluster.

        If the optional type is provided, then each document is given that type, or text as the
        default.  The id of the document will be the filename, unless optional parameter
        filename_id is specified as 0 or optional parameter filename_count is specified as 1, in which
        case each document will be specified a unique number (the first document given 1, the second 2,
                        and so on).

        =cut


        =head2 load_file_list_array

        load_file_list_array($filename, type => 'text', filename_id => 1)

        Loads all the documents in the array given as the first parameter
        and adds them to the cluster.

        If the optional type is provided, then each document is given that type, or text as the
        default.  The id of the document will be the filename, unless optional parameter
        filename_id is specified as 0 or optional parameter filename_count is specified as 1, in which
        case each document will be specified a unique number (the first document given 1, the second 2,
                        and so on).

        =cut


        =head2 load_file_list_from_file

        load_file_list_from_file($filename, type => 'text', filename_id => 1)

        Loads the documents listed in the file whose name is given as the
        first parameter and adds them to the cluster.  Each file should be listed alone on a line.

        If the optional type is provided, then each document is given that type, or text as the
        default.  The id of the document will be the filename, unless optional parameter
        filename_id is specified as 0 or optional parameter filename_count is specified as 1, in which
        case each document will be specified a unique number (the first document given 1, the second 2,
                        and so on).

        =cut


        =head2 load_sentences_from_file

        load_sentences_from_file($filename, type => 'text', id_prefix => '')

        Loads each sentence from a file as a separate document and adds it to the cluster.

        If the optional type parameter is specified, the new documents will be created as that
        type (text is the default).  If an id_prefix is specified, that string will be prepended
        to each sentence's number to form the id.

        =cut

        =head2 load_corpus

        Load a corpus directory into a cluster
        Pass in a Clair::Corpus object

        =cut

        =head2 save_documents_to_directory

        save_documents_to_directory($directory, 'text', name_count => 1)

        Saves each document from the cluster to the specified directory.  The second parameter
        specifies whether the html, text, or stem version of the document is saved.  If the
        optional parameter name_count is set to 0 or the optional parameter name_id is set to 1,
        the document's id is used as the filename.  Otherwise (and by default), the first document
        saved is saved with filename '1', the second with filename '2', and so on.

        =cut


        =head2 stem_all_documents

        stem_all_documents

        Goes through each document in the cluster and calls stem on it.

        =cut


        =head2 strip_all_documents

        strip_all_documents

        Goes through each document in the cluster and calls strip_html on it.

        =cut


        =head2 documents

        documents

        Returns the hash of documents in the cluster.

        =cut


        =head2 compute_lexrank

        Computes lexrank on this cluster. Any parameters will be passed to the
        Clair::Network method compute_lexrank.

        =cut


        =head2 get_unique_words

        $c->get_unique_words(type => 'stem')

        Returns a list of unique words out of all the documents in the cluster.
        Defaults to extracting these words from stemmed versions of the documents,
        but can be set to text or html by passing an optional type argument:
        get_unique_words(type => 'stem')

        =cut


        =head2 compute_genprob_matrix

        my %matrix = $cluster->compute_genprob_matrix(
                        genprob => $path_to_genprob
                        );

        Computes the generation probability matrix for this cluster. Returns a
        hashmap of hashrefs in the form $hash{$id1}->{$id2} mapping two document
        ids to the generation probability of document $id2 given document $id1.
        To use this method with LexRank, use the create_genprob_network method.
        Takes a parameter "genprob" that maps to the binary executable tf2gen.
        This value defaults to the $GENPROB variable set in Clair::Config.


        =head2 create_genprob_network

        my %genprob = $cluster->compute_genprob_matrix();
        my $network = $cluster->create_genprob_network(
                        genprob_matrix => \%genprob,
                        include_zeros => 1
                        );

        Creates a Clair::Network object from the given genprob matrix. See the
        description for create_network for more information.

        =cut

=head2 compute_sentence_features( %features )

        Computes a set of features on all sentences. %features should be a hash
        mapping names to feature subroutine references. See compute_sentence_feature
        for more information.

        =cut

=head2 compute_sentence_feature( name => $name, feature => $subref, normalize => 1 )

        Computes the given feature for each sentence in the cluster. The feature
        parameter should be a reference to a subroutine. The subroutine will be
        called with the following parameters defined:

        =over 4

        =item * cluster - a reference to the cluster object

        =item * document - a reference to the document object

        =item * sentence - the sentence text

        =item * sentence_index - the index of the sentence

        =item * state - A hash reference that is kept in memory between calls to the subroutine. This lets $subref save precomputed values or keep track of inter-sentence relationships.

        =back

        The parameter cluster is not passed when the same method is called on
        L<Clair::Document>. Thus calling compute_sentence_feature from Clair::Cluster
        gives an extra cluster context passed to the feature subroutine.

        A feature subroutine should return a value. Any exceptions thrown by the
        feature subroutine will be caught and a warning will be shown. If a feature
        subroutine returns an undefined value, the feature will not be set and a
        warning will be shown. This method returns undef if either name or feature
        are not defined.

        The normalize parameter, if set to a true value, will scale the values of this
        feature so that the minimum value is 0 and the maximum value is 1. Nothing
        will happen if any of the feature values are non-numeric.

        =cut

=head2 normalize_sentence_feature($name)

        Scales the values of the given feature so that the minimum value is 0 and
        the maximum value is 1. Nothing will happen if any of the feature values are
        non-numeric.

=head2 normalize_sentence_features(@names)

        Scales the values of the given features such that for each feature the
        minimum value is 0 and the maximum value is 1.

        =cut

=head2 get_sentence_features($did, $i)

        Returns a hash mapping the features to values of sentence $i in document
        $did.

        =cut

=head2 get_sentence_feature($did, $i, $name)

        Returns the value of the given feature $name for the given sentence $i in
        the document $did (where $i is the index of the sentence starting at 0).
        Returns undef if $did isn't a valid document id, $i isn't in the range of
        sentences, or $name isn't a valid feature.

        =cut

        =head2 remove_sentence_features

        Removes all of the features from all of the sentences.

        =cut

=head2 set_sentence_feature($did, $i, %features)

        Sets the given set of features for the given document $did and sentence $i.
        Returns undef if the sentence corresponding to $did, $i doesn't exist.

        =cut

=head2 score_sentences( combiner => $subref, normalize => 0, weights => \%weights )

        Scores the sentences using the given combiner. A combiner subroutine will
        be passed a hash comtaining feature names mapped to values and should return
        a real number. By default, the sentence scores will be normalized unless
        normalize is set to 0. If the combiner does not return an appropriate value
        for each sentence, score_sentences returns undef and the sentence scores are
        left uncomputed.

        Alternatively, if a hash reference is specified for the parameter weights, then
        the returned score will be a linear combination of the features specified
        in weights according to their given weights. This option will override the
        combiner parameter.

        =head2 normalize_sentence_scores

        Scales the scores of sentences such that the highest score is 1 and lowest is
        0. Returns undef if the scores are not defined.

        =head2 get_text

        Returns the text of each document concatenated together. A newline separates
        the text from each document.

        =head2 sentence_scores_computed

        Returns true if all of the sentence in this cluster have scores. False
        otherwise.

        =cut

=head2 compute_document_features( %features )

        Computes a set of features on all documents in the cluster. %features should
        be a hash mapping names to feature subroutine references. See
        compute_document_feature for more information.

        =cut

=head2 compute_document_feature( name => $name, feature => $subref )

        Computes the given feature for each document in the cluster. The feature
        parameter should be a reference to a subroutine. The subroutine will be
        called with the following parameters defined:

        =over 2

        =item * cluster - a reference to the cluster object

        =item * document - a reference to the document object

        =back

        The parameter cluster is not passed when the same method is called on
        L<Clair::Document>. Thus calling compute_document_feature from Clair::Cluster
        gives an extra cluster context passed to the feature subroutine.

        A feature subroutine should return a value. Any exceptions thrown by the
        feature subroutine will be caught and a warning will be shown. If a feature
        subroutine returns an undefined value, the feature will not be set and a
        warning will be shown. This method returns undef if either name or feature
        are not defined.

        =cut

        =head2 get_document_features

%features = $c->get_document_features($did)

        Returns a hash mapping the features to values of document $did.

        =cut

        =head2 get_document_feature

$val = $c->get_document_feature($did, $name)

        Returns the value of the given feature $name for document $did.
        Returns undef if $did isn't a valid document id, or $name isn't
        a valid feature.

        =cut

        =head2 remove_document_features

$c->remove_document_features()

        Removes all of the features from all of the documents in the cluster.

        =cut

        =head2 set_document_feature

$c->set_document_feature($did, %features)

        Sets the given set of features for the given document $did.
        Returns undef if the document corresponding to $did doesn't exist.

        =cut

=head2 get_summary(size => $size, preserve_order => 0, document_order => $ref)

        Returns a summary of this cluster based on the sentence scores. If the
        scores haven't been computed, it will return undef. A summary is an array
        of hash references. Each hash reference represents a sentence and contains
        the following key/value pairs:

        =over 4

        =item * did - The document id of the document that this sentence came from

        =item * index - The index of this sentence in the document, starting at 0

        =item * text - The text of this sentence

        =item * features - A hash reference of this sentence's features

        =item * score - The score of this sentence.

        =back

        The size parameter sets the maximum length (number of sentences) of the
        summary.

        The preserve_order parameter controls how the sentences are ordered. If
        preserve_order is set to 0, then the sentences will be returned in
        descending order by score. If two sentences have the same score and are from
        the same document, then they are returned such that the sentence with the
        lower index is first. If two sentences have the same score and are from
different documents, then the natural order (i.e., the perl cmp operator)
        on the documents' ids will be used. If preserve_order is set to 1 or
        not defined, the order of the sentences in the summary is determined by
first sorting the sentences based on document (using cmp on the document ids)
        and then within the documents using the sentence index (preserving the
                        original order of sentences).

        The order of the documents can be overridden by specifying an ordering on the
        document ids using the document_order parameter. If an array containing the
        list of document ids in some order is specified, then it will be used
        instead of perl's cmp operator to determine the order of the documents.

        =head1 AUTHOR

        Clair, C<< <clair at umich.edu> >>

        =head1 BUGS

        Please report any bugs or feature requests to
        C<bug-clair-cluster at rt.cpan.org>, or through the web interface at
        L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=clairlib-dev>.
        I will be notified, and then you'll automatically be notified of progress on
        your bug as I make changes.

        =head1 SUPPORT

        You can find documentation for this module with the perldoc command.

        perldoc Clair::Document

        You can also look for information at:

        =over 4

        =item * AnnoCPAN: Annotated CPAN documentation

        L<http://annocpan.org/dist/clairlib-dev>

        =item * CPAN Ratings

        L<http://cpanratings.perl.org/d/clairlib-dev>

        =item * RT: CPAN's request tracker

        L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=clairlib-dev>

        =item * Search CPAN

        L<http://search.cpan.org/dist/clairlib-dev>

        =back

        =head1 COPYRIGHT & LICENSE

        Copyright 2006 Clair, all rights reserved.

        This program is free software; you can redistribute it and/or modify it
        under the same terms as Perl itself.

        =cut

        1; # End of Clair::Cluster
