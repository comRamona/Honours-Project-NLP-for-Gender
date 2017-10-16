package Clair::Polisci::US::Connection;
use strict;
use DBI;
use Clair::Polisci::Record;
use Clair::Polisci::Graf;
use Clair::Polisci::Speaker;

sub new {

    my $self = shift;
    my %args = @_;

    die "'user' a required parameter" unless defined $args{user};
    die "'password' a required parameter" unless defined $args{password};
    die "'host' a required parameter" unless defined $args{host};
    die "'database' a required parameter" unless defined $args{database};

    my %chamber_map = ( "House" => 1, "Senate" => 2 );

    my $dsn = "DBI:mysql:database=$args{database};host=$args{host}";
    my $dbh = DBI->connect($dsn, $args{user}, $args{password});

    $self = { 
        dbh => $dbh, 
        source => $args{database}, 
        chamber_map => \%chamber_map 
    };
    return bless($self);

}

sub get_speech {

    my $self = shift;
    my $speech_id = shift;
    my $dbh = $self->{dbh};

    if 
    ($speech_id =~ /\d\d\d\.([^\.]+)\.(\d\d\d\d)(\d\d)(\d\d)\.(\d\d\d)-(.*)$/) 
    {
        my ($chamber, $year, $month, $day, $index, $speaker) =
            ($1, $2, $3, $4, $5, $6);
        my $chamber_id = 1;
        if ($chamber eq "sen") {
            $chamber_id = 2;
        } 
        my $date = "$year-$month-$day";

        my $i = $index - 1;
        if ($i < 0) {
            warn "Invalid index: $speech_id";
            return undef;
        }

        my $sql = "SELECT record_id FROM records "
                . "WHERE chamber_id=$chamber_id AND record_date='$date' "
                . "ORDER BY record_id ASC LIMIT $i,1";
        my $statement_rec = $dbh->prepare($sql);
        $statement_rec->execute();
        my $record_id = $statement_rec->fetchrow_array();

        $sql = "SELECT graf_content FROM grafs,speakers WHERE "
             . "grafs.record_id=$record_id AND "
             . "speakers.speaker_id=grafs.speaker_id AND "
             . "speakers.speaker_xml_code='$speaker' ORDER BY graf_index";
        my $statement_graf = $dbh->prepare($sql);
        $statement_graf->execute();

        my $speech = "";
        while (my $content = $statement_graf->fetchrow_array()) {
            $speech .= "$content ";
        }

        return $speech;


    } else {
        warn "Invalid speech id format: $speech_id";
        return undef;
    }

}

sub get_records {

    # Possible parameters: min_date, max_date, list of speaker_ids,
    # body_regex, title_regex, chamber. For now, min_date and max_date are 
    # required.

    my $self = shift;
    my $dbh = $self->{dbh};
    my %params = @_;

    my $min_date = $params{min_date} || die "min_date required";
    my $max_date = $params{max_date} || die "max_date required";

    # First find a bunch of matching record_ids and then load them
    my %record_ids;

    my $sel_rec = "SELECT record_id FROM records WHERE "
        . "unix_timestamp(record_date) >= unix_timestamp('$min_date') "
        . "AND "
        . "unix_timestamp(record_date) <= unix_timestamp('$max_date') ";

    if (defined $params{title_regex}) {
        $params{title_regex} =~ s/'/''/g;
        $sel_rec .= "AND record_title REGEXP '$params{title_regex}' ";
    }

    if (defined $params{chamber}) {
        my $chamber_id = $self->{chamber_map}->{$params{chamber}} || 1;
        $sel_rec .= "AND chamber_id = $chamber_id ";
    }

    if (defined $params{record_id}) {
        $sel_rec .= "AND record_id = $params{record_id} ";
    }

    my $statement_rec = $dbh->prepare($sel_rec);
    $statement_rec->execute();
    while (my $id = $statement_rec->fetchrow_array()) {
        $record_ids{$id} = 1;
    }

    if (keys %record_ids && ( $params{body_regex} || $params{speakers} )) {
        my $ids_str = _to_sql_list(keys %record_ids);
        my $sel_graf = "SELECT DISTINCT record_id FROM grafs WHERE "
            . "record_id IN ($ids_str) ";
        if ($params{body_regex}) {
            $params{body_regex} =~ s/'/''/;
            $sel_graf .= "AND graf_content REGEXP '$params{body_regex}' ";
        }
        if ($params{speakers}) {
            $ids_str = _to_sql_list(@{$params{speakers}});
            $sel_graf = "AND speaker_id IN ($ids_str) ";
        }

        my $statement_graf = $dbh->prepare($sel_graf);
        $statement_graf->execute();
        %record_ids = ();
        while (my $id = $statement_graf->fetchrow_array()) {
            $record_ids{$id} = 1;
        }
    }

    my %speakers;
    my @records;

    foreach my $record_id (keys %record_ids) {
        my $sel = "SELECT * FROM records WHERE record_id=$record_id";
        my $sth = $dbh->prepare($sel);
        $sth->execute();
        my $rrow = $sth->fetchrow_hashref();
        my $record = Clair::Polisci::Record->new(
            source => $self->{source},
            %$rrow
        );

        $sel = "SELECT * FROM grafs WHERE record_id=$record_id ORDER BY "
             . "graf_index ASC";
        $sth = $dbh->prepare($sel);
        $sth->execute();
        
        while (my $grow = $sth->fetchrow_hashref()) {

            # Get the speaker from the cache or load a new one
            my $speaker_id = $grow->{speaker_id};
            my $speaker;
            if (exists $speakers{$speaker_id}) {
                $speaker = $speakers{$speaker_id};
            } else {
                $sel = "SELECT * FROM speakers WHERE speaker_id=$speaker_id";
                my $sth_speaker = $dbh->prepare($sel);
                $sth_speaker->execute();
                my $srow = $sth_speaker->fetchrow_hashref();
                $speaker = Clair::Polisci::Speaker->new(
                    source => $self->{source},
                    id => $srow->{speaker_id},
                    %$srow
                );
                $speakers{$speaker_id} = $speaker;
            }

            my $graf = Clair::Polisci::Graf->new(
                source => $self->{source},
                index => $grow->{graf_index},
                content => $grow->{graf_content},
                speaker => $speaker,
                %$grow
            );

            $record->add_graf($graf);

        }

        push @records, $record;

    }

    return @records;

}

sub _to_sql_list {
    return join ",", @_;
}

=head1 NAME

Clair::Polisci::US::Connection - Read records from the US polisci database

=head1 SYNOPSIS

    my $con = Clair::Polisci::US::Connection->new(
        user => "root",
        password => "",
        host => "localhost",
        database => "polisci_us"
    );

    # Will fetch all records from 2004 that mention moral or ethic in their
    # body. 
    my @records = $con->get_records(
        min_date => "2004-01-01",
        max_date => "2004-12-31",
        chamber => "Senate",
        body_regex => "moral|ethic"
    );

    # Each $record is a Clair::Polisci::Record
    foreach my $record (@records) {
        my $cluster = $record->to_graf_cluster( speech_type_id => 1 );
        # ...
    }

=head1 DESCRIPTION

This class is used to read records from the polisci_us database. The data is
loaded into Clair::Polisci::Record, Clair::Polisci::Graf, and Clair::Polisci::Speaker objects.
Currently there are only two methods, new() and get_records().

=head1 METHODS

=head2 new
    
    my $con = Clair::Polisci::US::Connection->new(
        user => "root",
        password => "",
        host => "localhost",
        database => "polisci_us"
    );

Constructs a new Connection object. All of the above fields are required.

=head2 get_records

    my @records = $con->get_records(
        min_date => "2004-01-01",
        max_date => "2004-12-31",
        title_regex => "bush",
        speakers => \@speaker_ids,
        chamber => "House",
        body_regex => "moral|ethic"
    );

Fetches a list of records that match the given qualifications. Currently,
min_date and max_date are required as an attempt to increase the speed of 
the queries. They must be in the above format. title_regex and body_regex
will perform regular expression matches on the title of the record and
the grafs respectively. They are in the MySQL regular expression format, 
see http://dev.mysql.com/doc/refman/5.0/en/regexp.html for more information.
Chamber is the name of the chamber (either "Senate" or "House"). To restrict
the results to records where there are certain speakers, set speakers to
an array reference of speaker id's.

=head2 get_speech

    my $speech = $con->get_speech("105.sen.19970903.023-14508");

A speech in this sense is defined as the concatentation of one speaker's grafs
in a single record. This method will map the given speech identifier 
(which doesn't exist in the database) to a concatenation of grafs. The format
for the speech identifier is: 
    chamberindex.chamber.YYYYMMDD.index-speaker_xml_code
where chamber is either "sen" or "house", index is the position of the record
in the list of records from the given day, and speaker_xml_code is the 
unique ID given to each speaker from the XML documents.
    
=head1 AUTHOR

Tony Fader L<afader@umich.edu>

=cut

1;
