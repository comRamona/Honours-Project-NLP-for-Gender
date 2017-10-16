package Clair::Config;
use strict;
use Exporter;
use DB_File;

our (@EXPORT, @ISA);
@ISA = qw(Exporter);
@EXPORT = qw($CLAIRLIB_HOME $MEAD_HOME $CIDR_HOME $PRMAIN $DBM_HOME $JMX_HOME $JMX_MODEL_PATH $GOOGLE_DEFAULT_KEY $ALE_PORT $ALE_DB_USER $ALE_DB_PASS $EMAIL $DEFAULT_UNKNOWN_IDF $CHARNIAK_PATH $CHARNIAK_DATA_PATH $CHUNKLINK_PATH $GENPROB $SENTENCE_SEGMENTER_TYPE $WEKA_JAR_PATH);

our ($CLAIRLIB_HOME, $MEAD_HOME, $CIDR_HOME, $PRMAIN, $DBM_HOME, $JMX_HOME, $JMX_MODEL_PATH, $GOOGLE_DEFAULT_KEY, $ALE_PORT, $ALE_DB_USER, $ALE_DB_PASS, $EMAIL, $DEFAULT_UNKNOWN_IDF, $CHARNIAK_PATH, $CHARNIAK_DATA_PATH, $CHUNKLINK_PATH, $GENPROB, $NUTCH_HOME, $SENTENCE_SEGMENTER_TYPE, $WEKA_JAR_PATH);

#################################
# For Clairlib-core users:
# 1. Edit the value assigned to $CLAIRLIB_HOME and give it the value of the path to your installation.
# 2. Edit the value assigned to $MEAD_HOME and give it the value that points to your installation of MEAD.
# 3. Edit the value assigned to $WEKA_JAR_PATH and give it the value that points to the file weka.jar
# 4. Edit the value assigned to $EMAIL and give it an appropriate value.

$CLAIRLIB_HOME = "/data2/users/amjbara/clairlib-amjad/trunk";
#$MEAD_HOME     = "/data0/projects/mead312/mead-belobog";
#$CIDR_HOME     = "$MEAD_HOME/bin/addons/cidr";
#$PRMAIN        = "$MEAD_HOME/bin/feature-scripts/lexrank/prmain";
$DBM_HOME      = "$CLAIRLIB_HOME/etc";
#$GENPROB       = "$MEAD_HOME/bin/feature-scripts/tf2gen";
#$WEKA_JAR_PATH = "/home/jmd2118/lib/weka-3-4-10/weka.jar";

# Put your e-mail here (for use by Robot2--passed to LWP::RobotUA)
$EMAIL = 'mjschal@umich.edu';

$SENTENCE_SEGMENTER_TYPE = "Text";

#################################
# Only users who have installed Clairlib-ext may need to change the following
# commented-out assignments.
#
# For Clairlib-ext users:

# If you wish to use MxTerminator, uncomment the following three lines. Point
# the $JMX_HOME variable at your installation of MxTerminator. Point
# the $JMX_MODEL_PATH variable at the location of the segmenting model you
# want to use.
$JMX_HOME  = "/data2/tools/jmx_new";
$SENTENCE_SEGMENTER_TYPE = "MxTerminator";
$JMX_MODEL_PATH = "/data2/tools/jmx_new/eos.project";

# If you have MySQL installed and wish to use ALE, point the following
# definition at your MySQL socket.  Also uncomment the subsequent two
# definitions and provide the root password to your MySQL installation.

#$ALE_PORT  = "/tmp/mysql.sock";
#$ALE_DB_USER = "";
#$ALE_DB_PASS = "";

# If you happen to have a Google API key, some Clairlib
# components can utilize it.
# Please see the clarlib webpage for help obtaining a Google key
#$GOOGLE_DEFAULT_KEY = "";

# If you have a Charniak parser installed, Parse.pm can use it.
# Give the paths to it and its data collections here:
# (Note that CHARNIAK_DATA should end with a slash and that the other
# paths include the executable)
#$CHARNIAK_PATH = "/data0/tools/charniak/PARSE/parseIt";
#$CHARNIAK_DATA_PATH = "/data0/tools/charniak/DATA/EN/";

# If you have a Chunklink parser, point to it here:
#$CHUNKLINK_PATH = "/data2/tools/chunklink/chunklink.pl";

#################################
# Any assignments past this point should not be edited
# by end-users who aren't sure what they are for.

# Return this value if the word is not in the dbm:
$DEFAULT_UNKNOWN_IDF = 0.1;


=head1 NAME

Clair::Config - A module containing important clairlib variables

head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

    use Clair::Config;
    print "Path to mead: $MEAD_HOME\n";
    print "Path to cidr: $CIDR_HOME\n";
    print "Path to prmain: $PRMAIN\n";
    print "Path to enidf files: $DBM_HOME\n";

=cut

=head1 DESCRIPTION

This module is a collection of important variables for the CLAIR library,
including the path to MEAD, CIDR, and prmain.

=cut

=head1 EXPORTABLE VARIABLES

$MEAD_HOME - path to MEAD
$CIDR_HOME - path to CIDR
$PRMAIN    - path to prmain
$DBM_HOME  - path to idf files

=cut

1;
