package Clair::LinkPolicy::LinkPolicyBase;

use strict;
use Carp;
use Clair::Utils::CorpusDownload;

=head1 NAME

Clair::LinkPolicy::LinkPolicyBase - Base class for creating corpora from collections

=cut

=head1 SYNOPSIS

=cut

=head1 DESCRIPTION

Base class for document linking

METHODS IMPLEMENTED BY THIS CLASS:
  new_linker		Base Class Constructor

METHODS REQUIRED BY SUBCLASSES:
  create_corpus	Creates a corpus using this link policy.

=cut

=head2 new_linker

Generic object constructor for all link policies. Should
  only be called by subclass constructors.

REQUIRED PARAMETERS:

  base_collection	=> $collection_object
		        The collection whose documents will make
			up the corpus we create with this linker.
  base_dir	        => $collection_directory

  model_name		=> $name_of_this_linker_model_name

=cut

sub new_linker {
  my $class = shift;

  my $self = bless { @_ }, $class;

  # Verify parameters
  unless ((exists $self->{base_collection}) &&
          (exists $self->{model_name}) &&
          (exists $self->{base_dir})) {
    croak "LinkPolicy constructor requires parameters:
		base_collection	=> collection_of_documents
                base_dir => directory_of_corpus
		model_name	=>  this_policy_model_name\n";
  }

#  $self->{download_base} = "$ENV{PERLTREE_HOME}/download";
  $self->{download_base} = $self->{base_dir} . "/download";
  $self->{corpus_data} = $self->{base_dir} . "/corpus-data";
  $self->{corpora_base} = $self->{base_dir} . "/corpora";
  return $self;
}

=head2 create_corpus 

Generates a corpus using this link policy and the given base
  collection. Because this method is policy-specific, it must
  be implemented by children classes.

=cut

sub create_corpus {
  my $self = shift;
  my $corpus = shift;

  # save current directory
  my $pwd = `pwd`;
  chomp $pwd;

  my $dest = $self->{base_dir} . "/download/$corpus";
  chdir($dest);
  Clair::Utils::CorpusDownload::urlsToCorpus($self->{base_dir}, $corpus);

  # restore directory
  chdir $pwd;
}

=head2 create_html_no_anchors

This method should be called by the child class's "create_corpus"
  method - it reads in the .links file and creates the
  appropriate HTML documents.

Use this method if the anchor text of the links is irrelevant.

=cut

#
# TODO: Consolidate work in this method and the "with_anchors" version.
#
sub create_html_no_anchors {
  my $self = shift;
  my %params = @_;

  # Verify params
  unless ((exists $params{src_doc_dir}) && (exists $params{html_dir}) &&
          (exists $params{links_file}) && (exists $params{base_url})) {
    croak "LinkPolicy->create_html_with_anchors takes params:
	src_doc_dir	=> directory where source documents are located
	html_dir	=> directory where the html docs will go
	links_file	=> file with links specification
	base_url	=> base URL to use in html hyperlinks\n";
  }

  my $base_url = $params{base_url};
  my $src_dir = $params{src_doc_dir};
  my $link_file = $params{links_file};
  my $html_dir = $params{html_dir};

  # Verify input directory
  unless (-d $src_dir) {
    croak "Directory $src_dir does not exist\n";
  }

  # Make sure output html directory exists
  unless (-d $html_dir) {
    mkdir ($html_dir, 0775) ||
      croak "Could not create HTML output directory $html_dir\n";
  }

  my @files;
  my @urlToFileMap;
  my $cur_file;
  my $html_doc;
  my $link_model = read_links_no_anchors ($link_file);

  # Get filenames from input dir
  opendir (SD, $src_dir) || die "Cant open directory $src_dir\n";

  # While loop used to filter out stupidness
  while (defined ($cur_file = readdir (SD))) {
    next if $cur_file =~ /^\.+/;          # Skip dotfiles
    next if $cur_file =~ /pairs/;         # Skip pairs stuff
    push (@files, $cur_file);
  }
  closedir (SD);
  
  # Finally, Iterate over input files and create appropriate
  #  output HTML documents.
  #
  #  And make some noise doing it.
  #
  for (my $itor = 0; $itor < @files; $itor++) {
    $html_doc = textfile2html_no_anchors
      ($base_url, $src_dir, $files[$itor], $link_model);
  
    # Now, output HTML file
    open (HTMLOUT, ">$html_dir/$files[$itor].html") ||
      die "Cant create file $html_dir/$files[$itor].html\n";
  
    # Print URL-to-file map
    # update URL-to-file map
    push (@urlToFileMap, "\"http://$base_url/$files[$itor].html\" " .
                         "\"$base_url/$files[$itor].html\"");
  
    # Output doc terms
    foreach (@$html_doc) {
      print HTMLOUT "$_\n";
    }
    close (HTMLOUT);
  }
  return \@urlToFileMap;
}

=head2 create_html_with_anchors

This method should be called by the child class's "create_corpus"
  method - it reads in the .links file and creates the
  appropriate HTML documents.

This method assumes that there is a third column in the .links file,
  which is the anchor text to be used in linking.

REQUIRED PARAMETERS:
 src_doc_dir	=> directory where source documents are located
 html_dir	=> directory where the html docs will go
 links_file	=> file with links specification
 base_url	=> base URL to use in html hyperlinks

=cut

sub create_html_with_anchors {
  my $self = shift;
  my %params = @_;

  # Verify params
  unless ((exists $params{src_doc_dir}) && (exists $params{html_dir}) &&
          (exists $params{links_file}) && (exists $params{base_url})) {
    croak "LinkPolicy->create_html_with_anchors takes params:
	src_doc_dir	=> directory where source documents are located
	html_dir	=> directory where the html docs will go
	links_file	=> file with links specification
	base_url	=> base URL to use in html hyperlinks\n";
  }

  my $base_url = $params{base_url};
  my $src_dir = $params{src_doc_dir};
  my $link_file = $params{links_file};
  my $html_dir = $params{html_dir};

  # Verify input directory
  unless (-d $src_dir) {
    croak "Directory $src_dir does not exist\n";
  }

  # Make sure output html directory exists
  unless (-d $html_dir) {
    mkdir ($html_dir, 0775) ||
      croak "Could not create HTML output directory $html_dir\n";
  }

  my @files;
  my @urlToFileMap;
  my $cur_file;
  my $html_doc;
  my $link_model = read_links_with_anchors ($link_file);

  # Get filenames from input dir
  opendir (SD, $src_dir) || die "Cant open directory $src_dir\n";

  # While loop used to filter out stupidness
  while (defined ($cur_file = readdir (SD))) {
    next if $cur_file =~ /^\.+/;          # Skip dotfiles
    push (@files, $cur_file);
  }
  closedir (SD);

  #
  # Finally, Iterate over input files and create appropriate
  #  output HTML documents.
  #
  #  And try not to break things doing it.
  #
  for (my $itor = 0; $itor < @files; $itor++) {
    $html_doc = textfile2html_with_anchors
      ($base_url, $src_dir, $files[$itor], $link_model);
  
    # Now, output HTML file
    open (HTMLOUT, ">$html_dir/$files[$itor].html") ||
      die "Cant create file $html_dir/$files[$itor].html\n";
  
    # update URL-to-file map
    push (@urlToFileMap, "\"http://$base_url/$files[$itor].html\" " .
                         "\"$base_url/$files[$itor].html\"");
  
    # Output doc terms
    foreach (@$html_doc) {
      print HTMLOUT "$_\n";
    }
    close (HTMLOUT);
  }

  return \@urlToFileMap;
}

=head2 textfile2html_no_anchors

Returns HTML text in a term array based on the given link model and
 the given raw text file name and link model.

=cut

sub textfile2html_no_anchors {
  my ($url, $src_dir, $src_file, $linkmodel) = @_;
  my ($target, $anchor);
  my @line;
  my $remaining;
  my %anchor2targets;   # Maps anchors to target docs
  my @html;
  my $term;

  # Make sure we can open this file
  open (SRC, "$src_dir/$src_file") || die "Cant open $src_dir/$src_file\n";

  # Read-in document
  while (<SRC>) {
    push (@html, $_);
  }

  close (SRC);

  # Create hyperlinks (with no anchor text) if this
  #   document is to be linked to other documents.
  if (exists $linkmodel->{$src_file}) {
    # Create links for this document
    foreach $target (split (/\ /, $linkmodel->{$src_file})) {
      push (@html, "<a href=\"http://$url/$target.html\"></a>\n");
    }
  }

  # Affix standard HTML code
  unshift (@html,
    ("<html>", "<head>", "<title>", "$src_file",
     "</title>", "</head>", "<body>"));
  push (@html, qw (</body> </html>));

  # Now, return our fancy new html doc
  return \@html;
}

=head2 textfile2html_with_anchors

Returns HTML text in a term array based on the given link model and
 the given raw text file name and link model.

=cut

sub textfile2html_with_anchors {
  my ($url, $src_dir, $src_file, $linkmodel) = @_;
  my ($target, $anchor);
  my @line;
  my $remaining;
  my %anchor2targets;   # Maps anchors to target docs
  my @document;
  my @html;
  my $term;

  # Make sure we can open this file
  open (SRC, "$src_dir/$src_file") || die "Cant open $src_dir/$src_file\n";

  # Read-in document
  while (<SRC>) {
    chomp;
    foreach $term (split) {
      push (@document, $term);
    }
  }

  close (SRC);

  # Construct a mini-model of links for this document
  #  Make sure we have links from this document
  if (exists $linkmodel->{$src_file}) {
    #print "Links in $src_file:\n";
    @line = split (/\ /, $linkmodel->{$src_file});

    # Iterate over links
    while (@line > 1) {
      ($target, $anchor) = splice (@line, @line - 2, 2);
      $anchor2targets{$anchor} .= "$target ";
    }

    # Now, remove repeated pointers from a term to the same files
    foreach $term (keys %anchor2targets) {
      $anchor2targets{$term} = uniq_terms ($anchor2targets{$term});
      #print "\t$term -> $anchor2targets{$term}\n";
    }

    # Iterate over the document in search of link anchors
    for ($term = 0; $term < @document; $term++) {
      # Should we create a link at this term?
      if ((exists $anchor2targets{$document[$term]}) &&
          ($anchor2targets{$document[$term]} ne "")) {

        # Grab next target from our specification
        ($remaining, $target) = pop_term ($anchor2targets{$document[$term]});

        # Update our model to account for inserting this link.
        $anchor2targets{$document[$term]} = $remaining;

        # Insert the link
        $html[$term] = "<a href=\"http://$url/$target.html\">" .
                        $document[$term] . "</a>";
      } else {
        # No link to create...just insert term.
        $html[$term] = $document[$term];
      }
    }
  } else {
    # No links for this file.
    @html = @document;
  }

  # Affix standard HTML code
  unshift (@html,
    ("<html>", "<head>", "<title>", "$src_file",
     "</title>", "</head>", "<body>"));
  push (@html, qw (</body> </html>));

  # Now, return our fancy new html doc
  return \@html;
}

sub read_links_no_anchors {
  my $infile = shift;
  my %model;
  my ($from, $to);

  open (LF, $infile) || die "Cant open $infile\n";

  # Grab links, add them to our model
  while (<LF>) {
    chomp;
    ($from, $to) = split;
    $model{$from} .= "$to ";
  }

  close (LF);

  return \%model;
}

sub read_links_with_anchors {
  my $infile = shift;
  my %model;
  my ($from, $to, $anchor);

  open (LF, $infile) || die "Cant open $infile\n";

  # Grab links, add them to our model
  while (<LF>) {
    chomp;
    ($from, $to, $anchor) = split;
    $model{$from} .= "$to $anchor ";
  }

  close (LF);

  return \%model;
}

=head2 uniq_terms

Takes a string, and removes repeated occurrences of terms.
 All whitespace is replaced by a single space.

=cut

sub uniq_terms {
  my $str = shift;
  my @uniq;
  my %seen;

  foreach my $term (split /\s+/, $str) {
    unless (exists $seen{$term}) {
      # This is the first we've seen this term.
      $seen{$term}++;           # Record that we've now seen this term
      push (@uniq, $term);      # Save this term.
    }
  }
  return "@uniq";
}

=head2 pop_term

Takes a string of whitespace-delimited terms, and removes
 the last element. Returns the new string and the
 removed term.

=cut

sub pop_term {
  my $str = shift;
  my $term;
  my @line = split (/\s+/, $str);
  $term = pop (@line);
  return ("@line", $term);
}

=head2 pop_target

Takes a string of whitespace-delimited targets, and removes
 the last element. Returns the new string and the
 removed target.

=cut

sub pop_target {
  my $str = shift;
  my $term;
  my @line = split (/\s+/, $str);
  $term = pop (@line);
  return ("@line", $term);
}

=head2 Prepare corpus directories

=cut

sub prepare_directories {
  my $self = shift;
  my $corpus_name = shift;

  my $download_dir = $self->{download_base} . "/" . $corpus_name;
  my $corpus_dir = $self->{corpus_data} . "/" . $corpus_name;
  my $corpora_dir = $self->{corpora_base} . "/" . $corpus_name;

  unless (-d $corpus_dir) {
    mkdir ($self->{base_dir}, 0775) ||
	croak "Could not create directory $self->{base_dir} in LinkPolicyBase.pm\n";
    mkdir ($self->{corpus_data}, 0775) ||
        croak "Could not create directory  $self->{download_base} in LinkPolicyBase.pm\n";
    mkdir ($corpus_dir, 0775) ||
      croak "Could not create directory $corpus_dir in LinkPolicyBase.pm\n";
  }
  unless (-d $download_dir) {
    mkdir ($self->{download_base}, 0775) ||
      croak "Could not create directory  $self->{download_base} in LinkPolicyBase.pm\n";
    mkdir ($download_dir, 0775) ||
      croak "Could not create directory $download_dir in LinkPolicyBase.pm\n";
  }
  unless (-d $corpora_dir) {
    mkdir ($self->{corpora_base}, 0775) ||
      croak "Could not create directory  $self->{download_base} in LinkPolicyBase.pm\n";
    mkdir ($corpora_dir, 0775) ||
      croak "Could not create directory $corpora_dir in LinkPolicyBase.pm\n";
  }
}


1;
