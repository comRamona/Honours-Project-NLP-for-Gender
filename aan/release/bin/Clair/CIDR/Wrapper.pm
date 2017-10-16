package Clair::CIDR::Wrapper;

use strict;
use Clair::Cluster;
use File::Copy;
use Clair::Config;
use DB_File;

sub new {

    my $class = shift;
    my %parameters = @_;

    # Set the default params
    defined $parameters{sim_threshold}  or $parameters{sim_threshold} = 0.1;
    defined $parameters{word_decay}     or $parameters{word_decay} = 0.01;
    defined $parameters{keep_threshold} or $parameters{keep_threshold} = 3;
    defined $parameters{centroid_size}  or $parameters{centroid_size} = 10;
    defined $parameters{cidr_home}      or $parameters{cidr_home} = $CIDR_HOME;

    my $raw_cluster = Clair::Cluster->new();
    $parameters{raw_cluster} = $raw_cluster;

    my $self = bless \%parameters, $class;
    return $self;

}

sub add_cluster {
    
    my $self = shift;
    my $cluster = shift;
    my $raw_cluster = $self->{raw_cluster};

    my %dochash = %{ $cluster->documents() };
    foreach my $doc_id (keys %dochash) {
        
        my $new_id = _fix_id($doc_id);
        my $doc = $dochash{$doc_id};
        $doc->set_id(id => $new_id);
        $raw_cluster->insert($new_id, $dochash{$doc_id}); 

    }

}

sub add_document {

    my $self = shift;
    my $id = shift;
    my $doc = shift;

    my $new_id = _fix_id($id);
    $doc->set_id(id => $new_id);

    $self->{raw_cluster}->insert($new_id, $doc);

}

sub add_file {

    my $self = shift;
    my $file = shift;

    my $type = "text";
    if ($file =~ /\.html$/) {
        $type = "html";
    }

    my $id = $file;
    if ($id =~ /\/?([^\/]+)$/) {
        $id = $1;
    }

    my $doc = Clair::Document->new( file => $file, type => $type, id => $id);

    $self->{raw_cluster}->insert($id, $doc);
}

sub add_directory {
    
    my $self = shift;
    my $dir = shift;
    opendir DIR, $dir;
    my @files = readdir(DIR);
    closedir DIR;
    for (@files) {
        next unless (-f "$dir/$_");
        $self->add_file("$dir/$_");
    }

}

sub run_cidr {

    my $self = shift;
    my $cidr_home = $self->{cidr_home};
    my $cidr_script = "$cidr_home/cidr.pl";
    my $temp_dir = $self->{dest} || "temp.cidr";

    unless (-d $temp_dir) {
        mkdir($temp_dir) or die "Could not create temporary dir: $!";
    }

    # Save the files to disk
    my @file_list;
    my %dochash = %{ $self->{raw_cluster}->documents() };
    foreach my $id (keys %dochash) {
        my $doc = $dochash{$id};
        $doc->strip_html();
        $id =~ /([^\/]+)$/;
        my $filename = $1;
        my $outfile = "$temp_dir/$filename";
        open DOC, "> $outfile" or die "Could not open file: $outfile";
        print DOC $doc->get_text();
        close DOC;

        push @file_list, $filename;
    }

    # Make the list of files
    my $allfile = "$temp_dir/ALL";
    open ALL, "> $allfile" or die "Could not open file: $!";
    for (@file_list) {
        print ALL "$_\n";
    }
    close ALL;

    # Copy the idf data to the directory, ignoring enidf.txt
    my @idf_files = grep(!/enidf.txt$/, glob("$DBM_HOME/enidf*"));
    for (@idf_files) {
        if ($_ =~ /([^\/]+)$/) {
            my $file = $1;

            # cidr.pl needs nidf, mead has enidf
            my $noefile = $file;
            $noefile =~ s/^e//g;

            #system("ln -s $DBM_HOME/$file $temp_dir/$noefile");
            system("cp $DBM_HOME/$file $temp_dir/$noefile");
        } else {
            warn "Unexpected enidf file: $_";
        }
    }

    my $cidr_command = "$cidr_script 0 $self->{sim_threshold} "
                     . "$self->{word_decay} "
                     . "$self->{keep_threshold} "
                     . "$self->{centroid_size}";

    # Run CIDR
    chdir($temp_dir);
    system("cat ALL | $cidr_command > /dev/null");

    my @dirnames;
    opendir DIR, ".";
    for (readdir DIR) {
        if (-d $_ and $_ ne "." and $_ ne "..") {
            push @dirnames, $_;
        }
    }
    closedir DIR;

    my @clusters;
    my %idf;
    dbmopen %idf, "$DBM_HOME/enidf", 0666 
        or die "Couldn't open $DBM_HOME/enidf: $!";

    my $raw_cluster = $self->{raw_cluster};
    foreach my $dirname (@dirnames) {
        chdir($dirname);
        my %centroid;
        dbmopen %centroid, "centroid", 0666;
        delete $centroid{numberofarticles};
        my $centroid_copy = _copy_centroid(\%centroid, \%idf);
        dbmclose %centroid;

        unlink <centroid*>;
        my $cluster = Clair::Cluster->new();

        #$cluster->load_documents("*");

        foreach my $filename (`ls *`) {
            chomp $filename;
            if ($raw_cluster->has_document($filename)) {
                $cluster->insert($filename, $raw_cluster->get($filename));
            } else {
                my $docs = $raw_cluster->documents();
                my $ids = join ", ", keys %$docs;
                warn "Couldn't find $filename in cluster (in clust: $ids)";
            }
        }

        push @clusters, { cluster => $cluster, centroid => $centroid_copy };
        chdir("..");
    }

    chdir("..");

    return @clusters;

}

sub _copy_centroid {
    my $hashref = shift;
    my $idf = shift;
    my $newref = {};
    for (keys %$hashref) {
#        if ($idf->{$_}) {
            $newref->{$_} = $$hashref{$_};# * $idf->{$_};
#        } elsif ($idf->{lc($_)}) {
#            $newref->{$_} = $$hashref{$_} * $idf->{lc($_)};
#        } else {
#            warn "not in idf: $_";
#        }
    }
    return $newref;
}

sub _fix_id {
    my $id = shift;
    if ($id =~ /([^\/]+)$/) {
        return $1;
    } else {
        return $id;
    }
}

=head1 NAME

Clair::CIDR::Wrapper - A wrapper script for the original cidr script

head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Clair::CIDR::Wrapper;
    use Clair::Cluster;
    use Clair::Document;
    my $cluster = ...;
    my $document = ...;
    my $c = Clair::CIDR::Wrapper->new(
        cidr_home => "/path/to/cidr"
    );
    $c->add_directory("some/path/to/files");
    $c->add_cluster($cluster);
    $c->add_document($document);
    my @results = $c->run_cidr();
    for (@results) {
        my %centroid = $_->{centroid};
        my $new_cluster = $_->{cluster};
        ...
    }
    
=head1 METHODS

=over

=item new

    $c = Clair::CIDR::Wrapper->new(
        cidr_home => ... ,
        dest => ... ,
        sim_threshold => ... ,
        word_decay => ... ,
        keep_threshold => ... ,
        centroid_size => ... ,
    );

Creates a new Wrapper object. 'cidr_home' should point to the directory 
containing cidr.pl. If 'dest' is specified, the temporary CIDR files will
be written to the given directory and not deleted. 

=item add_file, add_directory, add_cluster, add_document

Various ways to add to the files to be clustered. add_cluster takes a 
Clair::Cluster object and add_document takes a Clair::Document object.
add_file and add_directory take appropriate paths.

=cut

1;
