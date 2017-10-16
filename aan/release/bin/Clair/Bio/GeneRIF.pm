package Clair::Bio::GeneRIF;
use Fcntl;
use MLDBM qw( DB_File );
use strict;

sub new {
    my $class = shift;
    my %params = @_;

    die "'path' is a required parameter" unless defined $params{path};

    my $dbm = $params{path} . ".dbm";
    $params{dbm} = $dbm;

    my $self = bless \%params, $class;

    # See if the dbm already exists
    if ($params{reload} or !$self->_dbm_exists()) {
        $self->_convert_to_dbm();
    } else {
        $self->_open_records();
    }

    return $self;
}

sub get_records_from_id {
    my $self = shift;
    my $id = shift;
    my $listref = $self->{records}->{$id} || [];
    return @{ $listref };
}

sub get_total_records {
    my $self = shift;
    my %records = %{$self->{records}};
    unless (defined $self->{total}) {
        $self->{total} = 0;
        while (my ($key, $listref) = each %records) {
            $self->{total} += @$listref;
        }
    } 
    return $self->{total};
}

sub get_all_records {
    my $self = shift;
    return $self->{records};
}

sub get_fields {
    my $self = shift;
    return @{$self->{fields}};
}


# Private methods

sub _open_records {
    my $self = shift;
    my %records = ();
    tie (%records, "MLDBM", $self->{dbm}, O_RDONLY, 0444)
        or die "Couldn't open $self->{dbm}: $!";

    $self->{records} = \%records;
    $self->_read_fields();
}

sub _dbm_exists {
    my $self = shift;
    return glob("$self->{dbm}*");
}

sub _read_fields {
    my $self = shift;

    open FILE, "< $self->{path}" or die "Couldn't open $self->{path}: $!";
    my @field_names;
    my $line = <FILE>;
    chomp $line;
    if ($line =~ /^#/) {
        $line =~ s/^#\s*//g;
        @field_names = split /\t/, $line;
    } else {
        die "Unexpected format: first line must begin with # followed by "
            . "field names";
    }
    close FILE;

    $self->{fields} = \@field_names;
    return @field_names;
}

sub _convert_to_dbm {

    my $self = shift;
    my $key_index = 1;

    my %records = ();

    if (-e $self->{dbm}) {
        unlink($self->{dbm}) or die "Couldn't remove $self->{dbm}: $!";
    }

    tie (%records, "MLDBM", $self->{dbm}, O_CREAT|O_RDWR, 0666)
        or die "Couldn't open DBM: $!";

    my @field_names = $self->_read_fields();

    open FILE, "< $self->{path}" or die "Couldn't open $self->{path}: $!";
    # Get rid of first line
    <FILE>; 
    while (<FILE>) {
        chomp;
        my @tokens = split /\t/, $_;
        die "Bad number of fields" unless @tokens == @field_names;
        my $key = $tokens[$key_index];

        # Get rid of the -'s
        foreach my $i (0 .. $#tokens) {
            $tokens[$i] = "" if $tokens[$i] eq "-";
        }

        my @list;
        if (exists $records{$key}) {
            @list = @{ $records{$key} };
        } else {
            @list = ();
        }

        push @list, \@tokens;
        $records{$key} = \@list;

    }

    tie (%records, "MLDBM", $self->{dbm}, O_RDONLY, 0444);

    $self->{records} = \%records;

    close FILE;
}

=head1 NAME

Clair::Bio::GeneRIF - Perl module for parsing GeneRIF files

=head1 SYNOPSIS

    use Clair::Bio::GeneRIF;
    my $generif = Clair::Bio::GeneRIF->new(
        path => "interactions.txt",
        reload => 1
    );
    my @records = $generif->get_records_from_id(60);
    my @fields = $generif->get_fields();
    foreach my $i (0 .. $#records) {
        print "Record $i {\n";
        my @record = @{ $records[$i] };
        foreach my $j (0 .. $#record) {
            print "\t$fields[$j] => $record[$j]\n";
        }
        print "}\n";
    }

=head1 DESCRIPTION

This module is used to parse GeneRIFs files. A GeneRIF file has the following
format: the first line is meta-data that labels each tab-delimited field,
and the rest of the lines are those fields.

The parsed file is saved into a DBM file after being parsed. The module will
look for a DBM file before attempting to parse the text file, unless the 
'reload' parameter is passed with a true value to the constructor.

Access to the data is done by passing a gene_id value to the 
get_records_from_id method, which returns a list of all the GeneRIFs with 
the given gene_id. Additionaly, you may access all GeneRIF entries at once
using the get_all_records method. This will most likely be a large hash,
backed by a DBM, so it would be best to use the each() function to iterate
over its keys and values.

This module uses DB_File to store nested data structures.

=head1 METHODS

=head2 new
    
    my $generif = Clair::Bio::GeneRIF->new(
        path => "/path/to/generif/file.txt,
        reload => 1
    );

Constructs a new GeneRIF object. The 'path' parameter must point to a GeneRIF
text file. The 'reload' parameter is optional and will force the DBM to be
recreated (this defaults to false).


=head2 get_records_from_id

    my @records = $generif->get_records_from_id($gene_id);

Returns a list of records with the given gene_id. Each record is an array
where the values are in the same order as the fields at the top of the file.
Returns () if there are no records. 


=head2 get_total_records

    my $total = $generif->get_total_records();

Returns the total number of records. 


=head2 get_all_records

    my @all_records = $generif->get_all_records();

Returns all records from the GeneRIF file as a hashref mapping gene_ids to
lists of records.

=head2 get_fields

    my @field_names = $generif->get_fields();

Returns a list of the field names. These are the keys in each record.

=head1 AUTHOR

Tony Fader, afader@umich.edu

=cut

1;
