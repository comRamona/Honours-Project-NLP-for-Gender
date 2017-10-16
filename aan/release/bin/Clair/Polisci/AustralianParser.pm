package Clair::Polisci::AustralianParser;

use strict;

use HTML::TokeParser;
use XML::Writer;

sub new {
    my $class = shift;
    my %parameters = @_;

    my ($out, $file);

    if (exists $parameters{file}) {
        $file = $parameters{file};
    }

    if (exists $parameters{out}) {
        $out = $parameters{out};
    } else {
        $out = \*STDOUT;
    }

    my $self = bless {
        out => $out,
        file => $file
    }, $class;

    return $self;
}

sub get_speeches {
    
    my $self = shift;
    my $filename = $self->{file};
    my $stream = HTML::TokeParser->new($filename);

    my @speeches;

    my $token;

    my $keepcount = 0;
    my $divcount = 1;
    my $slurp_body = 0;
    my $quote_level = 0;
    my $found_quote = 0;

    my $motion_level = 0;
    my $found_motion = 0;

    my ($speech_body, $speaker_id, $speech_type) = ("", "", "");

    # Jump to speech
    while (my $token = $stream->get_token and $divcount > 0) {
        
        if ($token->[0] eq "S" and exists $token->[2]{"class"}) {

            if ($token->[1] eq "div") { 
                
                if ($token->[2]{"class"} =~ /^(sub|motionno)?speech\d?$/) {
                
                    $slurp_body = 1;

                    $keepcount = 1;

                    push_onto_speeches(\@speeches, $speech_type,
                        $speaker_id, $speech_body);

                    $speech_body = "";
                    $speaker_id = "";

                } elsif ($token->[2]{"class"} eq "speechType") {
                    $speech_type = $stream->get_text("/div");

                } elsif ($token->[2]{"class"} eq "quote") {
                    $speech_body .= "<quote>";
                    $quote_level = 0;
                    $found_quote = 1;

                } elsif ($token->[2]{"class"} eq "motion") {
                    $speech_body .= "<motion>";
                    $motion_level = 0;
                    $found_motion = 1;
                }

                if ($keepcount) {
                    $divcount++;
                }

                if ($found_quote) {
                    $quote_level++;
                }

                if ($found_motion) {
                    $motion_level++;
                }


            } elsif ($token->[1] eq "span") {

                if ($token->[2]{"class"} eq "talkername") {
                    my $tag = $stream->get_tag("a");
                    if (exists $tag->[1]{"href"}) {
                        $tag->[1]{"href"} =~ /ID=(\d+)/;
                        $speaker_id = $1;
                    } else {
                        $speaker_id = $stream->get_text("/a");
                        $speaker_id =~ s/^The //g;
                    }

                } 
            } 

        } elsif ($token->[0] eq "E") {

            if ($token->[1] eq "div" and $keepcount) {

                if ($found_quote) {
                    $quote_level--;
                }

                if ($found_motion) {
                    $motion_level--;
                }

                if ($found_quote and $quote_level == 0) {
                    $speech_body .= "</quote>";
                    $found_quote = 0;
                }

                if ($found_motion and $motion_level == 0) {
                    $speech_body .= "</motion>";
                    $found_motion = 0;
                }

                if ($divcount == 1) {
                    push_onto_speeches(\@speeches, $speech_type, 
                        $speaker_id, $speech_body);
                }
                $divcount--;

            } 

        } elsif ($token->[0] eq "T") {
            
            if ($slurp_body) {
                $speech_body .= $token->[1];
            }
        }

    }
    $self->{speeches} = \@speeches;
    return \@speeches;
}

sub push_onto_speeches {
    my $speeches = shift;
    my ($type, $speaker, $body) = @_;
    if ($body ne "") {
        $body =~ s/^.*?\p{Pd}//g unless (!$speaker);
        push @$speeches, {type => $type, speaker => $speaker, body => $body};
    }
}

sub get_header {

    my $self = shift;
    my $filename = $self->{file};
    my $stream = HTML::TokeParser->new($filename);
    my ($key, $val);
    my %header;

    while (my $token = $stream->get_tag("span")) {
        if ($token->[1]{id} && $token->[1]{id} =~ /Label(\d)$/) {
            if ($1 eq "2") {
                $token = double_pop_token($stream);
                $key = $token->[1];
            } elsif ($1 eq "3") {
                $token = $stream->get_token;
                $val = $token->[1];
                if ($key) {
                    $header{$key} = $val;
                }
            }

        } elsif ($token->[1]{id} && $token->[1]{id} eq "txtTitle") {
            $token = double_pop_token($stream);
            $header{"Title"} = $token->[1];
        }
    } 


    # Get the time by simply searching line by line
    open(FILE, "< $filename");
    while (<FILE>) {
        if ($_ =~ /(\d?\d\.\d\d [ap]\.m\.)/) {
            $header{"Time"} = $1;
            last;
        }
    }
    close(FILE);

    clean_header(\%header);
    $self->{header} = \%header;
    return \%header;
}

sub double_pop_token {
    my $stream = shift;
    $stream->get_token;
    return $stream->get_token;
}

sub clean_header {
    my $header = shift;

    my %month_map = ( "January" => "01",
                      "February" => "02",
                      "March" => "03",
                      "April" => "04",
                      "May" => "05",
                      "June" => "06",
                      "July" => "07",
                      "August" => "08",
                      "September" => "09",
                      "October" => "10",
                      "November" => "11",
                      "December" => "12" );

    if (exists $header->{"Date"}) {
        $header->{"Date"} =~ /(\d\d?) (\w+), (\d\d\d\d)/;
        my ($d, $m, $y) = ($1, $2, $3);
        if ($d !~ /\d\d/) {
            $d = "0$1";
        }
        $header->{"Date"} = $y . $month_map{$m} . $d;
    } else {
        $header->{"Date"} = "";
    }

    if (exists $header->{"Time"}) {
        $header->{"Time"} =~ /(\d\d?)\.(\d\d) ([pa])\.m\./;
        if ($1 and $2 and $3) {
            my ($h, $m, $x) = ($1, $2, $3);
            if ($x eq "p") {
                $h = $h + 12;
            }
            if ($h !~ /\d\d/) {
                $h = "0$h";
            }
            $header->{"Time"} = "$h$m";
        } 
    } else {
        $header->{"Time"} = "";
    }
    if (!exists $header->{"Type"}) {
        $header->{"Type"} = "";
    }
}

sub write_xml {

    my $self = shift;
    my ($header, $speeches);

    if (exists $self->{header}) {
        $header = $self->{header};
    } else {
        $header = $self->get_header();
    }

    if (exists $self->{speeches}) {
        $speeches = $self->{speeches};
    } else {
        $speeches = $self->get_speeches();
    }

    my $writer = new XML::Writer(OUTPUT => $self->{out}, NEWLINES => 1);
    $writer->xmlDecl("UTF-8");
    $writer->doctype("record", undef, "record_aus.dtd");
    $writer->startTag("record");

    $writer->startTag("header");

    $writer->startTag("date");
    $writer->characters($header->{"Date"});
    $writer->endTag("date");

    $writer->startTag("source");
    $writer->characters($header->{"Source"});
    $writer->endTag("source");

    $writer->startTag("type");
    $writer->characters($header->{"Type"});
    $writer->endTag("type");

    $writer->startTag("title");
    $writer->characters($header->{"Title"});
    $writer->endTag("title");

    unless (!exists $header->{"Main Committee"}) {
        $writer->startTag("main-committee");
        $writer->characters($header->{"Main Committee"});
        $writer->endTag("main-committee");
    }

    unless (!exists $header->{"Proof"}) {
        $writer->startTag("proof");
        $writer->characters($header->{"Proof"});
        $writer->endTag("proof");
    }

    unless (!exists $header->{"Stage"}) {
        $writer->startTag("stage");
        $writer->characters($header->{"Stage"});
        $writer->endTag("stage");
    }

    unless (!exists $header->{"Context"}) {
        $writer->startTag("context");
        $writer->characters($header->{"Context"});
        $writer->endTag("context");
    }

    unless (!exists $header->{"Time"}) {
        $writer->startTag("time");
        $writer->characters($header->{"Time"});
        $writer->endTag("time");
    }

    $writer->endTag("header");

    $writer->startTag("body");
    foreach my $speech (@$speeches) {
        if (!$speech->{"speaker"} or $speech->{"speaker"} eq "") {
            $writer->startTag("nonspeech");
            convert_tags($writer, $speech->{"body"});
            #$writer->characters($speech->{"body"});
            $writer->endTag("nonspeech");
        } else {
            $writer->startTag("speech", type => $speech->{"type"},
                                        speaker => $speech->{"speaker"});
            #$writer->characters($speech->{"body"});
            convert_tags($writer, $speech->{"body"});
            $writer->endTag("speech");
        }
    }
    $writer->endTag("body");

    $writer->endTag("record");
    $writer->end();
}

sub convert_tags {
    my $writer = shift;
    my $body = shift;

    while ($body =~ /^(.*?)(<\/?[^>]+>)(.*)$/) {
        my $left = $1;
        my $right = $3;
        my $tag = $2;

        $writer->characters($left);
        if ($tag) {
            if ($tag =~ /<(\w+)>/) {
                $writer->startTag($1);
            } elsif ($tag =~ /<\/(\w+)>/) {
                $writer->endTag($1);
            }
        } 

        $body = $right;
    }
    $writer->characters($body);
}

sub set_out {
    my $self = shift;
    $self->{out} = shift;
}

1;

=head1 NAME

Clair::Polisci::AustralianParser - A class for parsing Australian hansard html.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS
    
    use Clair::Polisci::AustralianParser;
    my $p = Clair::Polisci::AustralianParser->new(file => "myfile.html");
    my $header = $p->get_header();
    my $speeches = $p->get_speeches();
    $p->write_xml();

=head1 FUNCTIONS

=head2 new

    my $out = \*OUT;
    my $file = "somefile.html";
    $p = Clair::Polisci::AustralianParser->new(file => $file, out => $out);

Creates a new object from the given file. "out" is an optional reference
to a filehandle where the XML will be printed. If "out" is not specified, 
$p->write_xml() will print to STDOUT.

=head2 set_out
    my $out = \*OUT;
    $p->set_out($out);

Sets the output filehandle.

=head2 get_header

Returns a hashref containing header key/value pairs.

    my $header = $p->get_header();
    foreach my $key (keys(%$header)) {
        print "$key => $header->{$key}\n";
    }

    # Prints Title => Some Title, etc

=head2 get_speeches

Returns an arrayref containing hashrefs to speech info.

    my $speeches = $p->get_speeches();
    foreach my $speech (@$speeches) {
        print "[\n";
        print "\t$speech->{type}\n";
        print "\t$speech->{speaker}\n";
        print "\t$speech->{body}\n";
        print "]\n";
    }

=head2 write_xml

Converts the data from $header and $speeches into XML and prints it to "out".
