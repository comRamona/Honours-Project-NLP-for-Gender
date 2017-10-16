package Clair::Interface::Weka;

use strict;
use warnings;

require Exporter;
use Clair::Config;
use Hash::Flatten qw(flatten);  # Used for writing complex feature data structures as flat attribute lists

our @ISA    = qw(Exporter);
our @EXPORT = qw(write_ARFF train_classifier test_classifier);

my $BUFFER_LEN = 1048576;       # Size of feature vector buffer


=pod

=head1 NAME

Clair::Interface::Weka

=head1 SYNOPSIS

Provides an interface between Clair::Cluster and the Java machine learning toolkit Weka.
The interface provides functionality for the automatic writing of document feature
vectors to ARFF file as well as easy, low-overhead use of classifiers for training and
testing. It is envisioned that in the future this package should provide a truly
seamless interface between Clairlib and Weka for carrying out machine learning tasks
the tools for which are implemented by the latter.

=head1 METHODS

=head2 write_ARFF

Clair::Interface::Weka->write_ARFF($c, $outfile, $header);

(public) Writes feature vectors for all the documents in the
specified cluster to a Weka ARFF (attribute-relation file
format) file.

B<c>
A reference to a Clair::Cluster object.

B<outfile>
A path to where the ARFF file is to be written.

B<header>
A string of header text to be prepended (using comments)
to the ARFF file.

=cut


=head2 train_classifier

Clair::Interface::Weka->train_classifier(mem => $mem,
classifier => $classifier, trainfile => $trainfile,
modelfile => $modelfile, testfile => $testfile, logfile => $logfile);

(public) Trains a Weka classifier of the specified class, given
a training file and (optionally) a test file in ARFF format.
Various parameters can be supplied to customize the details
of the training and the output thereby generated.

B<mem (optional)>
A numeric argument specifying the heap size to be allocated
by the Java VM. The actual argument passed to the VM is "-xM$memM".

B<classifier>
The full package name of the Weka classifier to be used, e.g.
"weka.classifiers.rules.ZeroR".

B<trainfile>
A path to an ARFF file containing the training data.

B<modelfile>
A path to where the classifier model is to be written.

B<testfile (optional)>
A path to an existing ARFF file to be used for cross-validation
(testing) of the trained classifier. If none is specified, then
tenfold cross-validation on the training data is used as the method
of validation.

B<logfile (optional)>
A path to where a log of the classifier's output is to be written.

=cut


=head2 test_classifier

Clair::Interface::Weka->test_classifier(mem => $mem,
classifier => $classifier, modelfile => $modelfile,
testfile => $testfile, predfile => $predfile, logfile => $logfile);

(public) Evaluates a Weka classifier of the specified class given
a (previously trained) model and a test file in ARFF format.
Various parameters can be supplied to customize the details of the
evaluation and the output thereby generated.

B<mem (optional)>
A numeric argument specifying the heap size to be allocated
by the Java VM. The actual argument passed to the VM is "-xM$memM".

B<classifier>
The full package name of the Weka classifier to be used, e.g.
"weka.classifiers.rules.ZeroR".

B<modelfile>
A path to a file containing a previously trained model of the
specified class of classifier.

B<testfile>
A path to an existing ARFF file to be used for evaluation of the
trained classifier.

B<predfile>
A path to where the classifier's predictions for each feature vector
in the test data are to be written.

B<logfile (optional)>
A path to where a log of the classifier's output is to be written.

=cut



# --------------------------------------------------------------
#  sub write_ARFF (public) :
#        Writes feature vectors for all the documents in the
#        specified cluster to a Weka ARFF (attribute-relation
#        file format) file.
#
#  Parameters:
#    $c       : a reference to the cluster
#    $outfile : a path to the file where the features are
#                 to be written
#    $header  : any header text to be prepended to the file
# --------------------------------------------------------------
sub write_ARFF {
    my $c       = shift;
    my $outfile = shift;
    my $header  = shift;

    open(local *FH, '>', $outfile)
      or die "write_ARFF() - unable to open $outfile for output";

	# Take relation name from cluster id, or '?' if not defined
    my $cid = $c->get_id() || "?";
    my $docsref = $c->documents();
    my %classes = $c->classes();

    #Write ARFF header
    my $header_text = $header . "\n" . '@RELATION' . " $cid\n\n";
    my $feature_text = "";

    my $attrs_declared = 0;
    foreach my $docid (sort keys %$docsref) {
        my %features = $docsref->{$docid}->get_document_features();

        my @vect = ();
		# Sort document features by feature name (to maintain same ordering each execution)
        foreach my $feature (sort keys %features) {
            my $value = $features{$feature};
			if (!ref($value)) {
				# If feature value is a scalar, can simply write it
                push @vect, $value;
                $header_text .= '@ATTRIBUTE' . " $feature NUMERIC\n" if (not $attrs_declared);
            } elsif (ref($value) eq "ARRAY") {
				# If feature value is an array, must name and treat elements as individual features
                push @vect, @$value;
                for (my $i = 1; !$attrs_declared && $i <= scalar @$value; $i++) {
                    $header_text .= '@ATTRIBUTE' . " $feature$i NUMERIC\n";
                }
            } elsif (ref($value) eq "HASH") {
				# If feature value is a hash, must flatten the hash and name and treat elements as individual features
                my $flat_hash = flatten($value);
                foreach my $key (sort keys %$flat_hash) {
                    push @vect, $flat_hash->{$key};
                    $header_text .= '@ATTRIBUTE' . " $key NUMERIC\n" if (not $attrs_declared);
                }
            } else {
				# Otherwise, not clear how to write the feature as part of an ARFF feature vector
                warn "write_ARFF() - cluster $cid: feature $feature is neither value, nor arrayref, nor hashref";
            }
        }
		# Append class label to feature vector
        $feature_text .= (join(",", (@vect, $c->get_class($docid))) . "\n");
		# Write feature vectors in buffered fashion, because feature files can be gigantic
        if (length $feature_text > $BUFFER_LEN) {
            print FH $feature_text;
            $feature_text = "";
        }

		# Prepend the ARFF header during the first buffered write of feature vectors
        if (not $attrs_declared) {
            $header_text .= '@ATTRIBUTE class {' . join(", ", sort keys %classes) . "}\n\n" . '@DATA' . "\n";
            print FH $header_text;
            $attrs_declared = 1;
        }
    }
	# Flush the buffer to write the last feature vectors
    if (length $feature_text > 0) {
        print FH $feature_text;
        $feature_text = "";
    }

    close(*FH);
}


# --------------------------------------------------------------
#  sub train_classifier (public) :
#        Trains a Weka classifier of the specified class given
#        a training file and (optionally) a test file in ARFF
#        format. Various parameters can be supplied to customize
#        the details of the training and the output thereby
#        generated.
#  Parameters:
#           mem => : (optional) numeric argument specifying the
#                    heap size to be allocated by the Java VM
#    classifier => : the full package name of the Weka classifier
#                    to be used
#     trainfile => : a path to the ARFF file to be used for training
#     modelfile => : a path to where the classifier model is to be
#                    written
#      testfile => : (optional) a path to an ARFF file to be used
#                    for cross-validation (testing) of the trained
#                    classifier; if none is specified, tenfold
#                    cross-validation on the training set is used
#      $logfile => : (optional) a path to where a log of the
#                    classifier's output is to be written
# --------------------------------------------------------------
sub train_classifier {
    my %params = @_;

    my $mem        = (defined $params{mem} ? "-mx$params{mem}m"  : "");
    my $classifier = $params{classifier};
    my $trainfile  = $params{trainfile};
    my $modelfile  = $params{modelfile};
    my $testfile   = (defined $params{testfile} ? "-T $params{testfile}" : "");
    my $logfile    = (defined $params{logfile}  ? "> $params{logfile}" : "");

    # Execution template:
    # java -mx1024m weka.classifiers.trees.J48 -t train.arff -i -k -d J48.model [-T test.arff] > train-J48.log
    my $argstr  = "$mem $classifier -t $trainfile -i -k -d $modelfile $testfile $logfile";
    my $cpstr   = '-classpath $CLASSPATH:' . "$WEKA_JAR_PATH";
    my $train_exec_str = "java $cpstr $argstr";

    return `$train_exec_str`;
}


# --------------------------------------------------------------
#  sub test_classifier (public) :
#        Evaluates a Weka classifier of the specified class given
#        a (previously trained) model and a test file in ARFF
#        format. Various parameters can be supplied to customize
#        the details of the evaluation and the output thereby
#        generated.
#  Parameters:
#           mem => : (optional) numeric argument specifying the
#                    heap size to be allocated by the Java VM
#    classifier => : the full package name of the Weka classifier
#                    to be used
#     modelfile => : a path to a previously trained Weka classifier
#                    of the specified class
#      testfile => : a path to the ARFF file to be used for
#                    evaluation of the trained classifier
#      predfile => : (optional) a path to a where the classifier's
#                    predicted class for each vector is to be written
#     $logfile  => : (optional) a path to a where a log of the
#                    classifier's output is to be written
# --------------------------------------------------------------
sub test_classifier {
    my %params = @_;

    my $mem        = (defined $params{mem} ? "-mx$params{mem}m"  : "");
    my $classifier = $params{classifier} || "weka.classifiers.rules.ZeroR ";
    my $modelfile  = $params{modelfile};
    my $testfile   = $params{testfile};
    my $predfile   = (defined $params{predfile} ? "> $params{predfile}" : "");
    my $logfile    = (defined $params{logfile} ? "> $params{logfile}" : "");

    # Execution templates (depending on whether $predfile is defined):
    # java -mx1024m weka.classifiers.trees.J48 -l J48.model -T test.arff -i > test-J48.log
    # java -mx1024m weka.classifiers.trees.J48 -l J48.model -T test.arff -i -p 0 > test-J48.pred
    my $argstr1  = "$mem $classifier -l $modelfile -T $testfile -i $logfile";
    my $argstr2  = "$mem $classifier -l $modelfile -T $testfile -i -p 0 $predfile";
    my $cpstr    = '-classpath $CLASSPATH:' . "$WEKA_JAR_PATH";
    my $test_exec_str = "java $cpstr $argstr1";
    my $pred_exec_str = "java $cpstr $argstr2";

    return (`$test_exec_str`, `$pred_exec_str`);
}


1;
