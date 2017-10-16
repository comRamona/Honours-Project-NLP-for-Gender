#!/usr/bin/perl

use strict;
use warnings;
use Config;


package Clair::IDF;

require Exporter;

our @ISA    = qw(Exporter);
our @EXPORT = qw(open_nidf
             get_nidf $current_dbmname);

use File::Spec;

use Clair::Config;

use vars qw($current_dbmname
                $DEFAULT_DBMNAME
                $DEFAULT_UNKNOWN_IDF
                $IDFDIR
                %nidf);

$DEFAULT_DBMNAME = "enidf";

# if the word is not in the dbm, return this value.
$DEFAULT_UNKNOWN_IDF = 3;

$IDFDIR =  $Clair::Config::DBM_HOME;


sub open_nidf{
    my $dbmname = shift || $DEFAULT_DBMNAME;

    if ($dbmname eq $DEFAULT_DBMNAME) {
      $dbmname = File::Spec->rel2abs($dbmname, $IDFDIR);
    }

    if ($current_dbmname && $current_dbmname eq $dbmname) {
                return 1;
    }
    use DB_File;
    unless (tie(%nidf,"DB_File", $dbmname, O_RDWR|O_CREAT, 0644)) {
        die "Cannot open DBM $dbmname";
    }


    unless (scalar(keys(%nidf))) {
        die "Empty DBM $dbmname";
    }

    $current_dbmname = $dbmname;

    return 1;
}


sub get_nidf {

    my $word = shift;
    unless (defined $current_dbmname) {
        open_nidf($DEFAULT_DBMNAME);
    }
    if($current_dbmname eq "none")
    {
        return 1;
    }

    if (defined $nidf{$word}) {
        return $nidf{$word};
    }

    return $DEFAULT_UNKNOWN_IDF;
}

1;

__END__



=head1 NAME

Clair::IDF - Provides access to an inverse document frequency (IDF) database.


=head1 SYNOPSIS

        use Clair::IDF

    open_nidf($dbmname);
    my $idf = get_nidf("word");
    my $output = ($idf == $Clair::IDF::DEFAULT_UNKNOWN_IDF
                            ? "unknown"
                            : $idf);
    print qq(IDF of "word": $output\n);


=head1 DESCRIPTION

This module provides access to an inverse document frequency (IDF) database via
a tied hash. If C<$dbmname> is not supplied, the database name is assumed to be
C<$Clair::IDF::DEFAULT_DBMNAME>. In any case, calling C<open_nidf()> sets
C<$Clair::IDF::current_dbmname> to the name of the database being opened, which
is assumed to be located in C<$Clair::IDF::$IDFDIR>.

Calling C<get_nidf($word)> returns the IDF of C<$word> in the database opened by
C<open_nidf()>, or C<$Clair::IDF::DEFAULT_UNKNOWN_IDF> if the IDF is not known.


=head1 METHODS

=over

=item open_nidf

Opens an IDF database.

        open_nidf($dbmname);

=item get_nidf

Gets the IDF of a word.

        my $idf = get_nidf("word");

=back


=head1 EXPORTS

        open_nidf()
    get_nidf()


=head1 CONFIGURATION AND ENVIRONMENT

        $current_dbmname       # last dbmname opened by open_nidf()
        $DEFAULT_DBMNAME     = "enidf";
        $DEFAULT_UNKNOWN_IDF = 3;
        $IDFDIR              = $Clair::Config::DBM_HOME;


=head1 DEPENDENCIES

        Exporter
        File::Spec
        MEAD::MEAD


=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Please report problems to Dragomir R. Radev (L<radev@umich.edu>).
Patches are welcome.


=head1 SEE ALSO

        L<Clair::Utils::TF>


=head1 AUTHOR

Dragomir R. Radev (L<radev@umich.edu>)


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007 the Clair group, all rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This module is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.


=cut
