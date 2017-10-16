#-----------------------------------------------------------------------

=head1 NAME

WWW::Robot - configurable web traversal engine (for web robots & agents)

=head1 SYNOPSIS

   use WWW::Robot;

   $robot = new WWW::Robot('NAME'     => 'MyRobot',
                           'VERSION'  => '1.000',
                           'EMAIL'    => 'fred@foobar.com');

   # ... configure the robot's operation ...

   $robot->run('http://www.foobar.com/');

=cut

#-----------------------------------------------------------------------

package WWW::Robot;
require 5.002;
use strict;

use HTTP::Request;
use HTTP::Status;
use HTML::Parse;
use URI::URL;
use URI::Escape;
use LWP::RobotUA;
use IO::File;
use SDBM_File;
use Time::Local;
use English;
use Clair::Config;

#-----------------------------------------------------------------------
#        Public Global Variables
#-----------------------------------------------------------------------
use vars qw($VERSION);
$VERSION   = '0.011';

#-----------------------------------------------------------------------

=head1 DESCRIPTION

This module implements a configurable web traversal engine,
for a I<robot> or other web agent.
Given an initial web page (I<URL>),
the Robot will get the contents of that page,
and extract all links on the page, adding them to a list of URLs to visit.

Features of the Robot module include:

=over

=item *

Follows the I<Robot Exclusion Protocol>.

=item *

Supports the META element proposed extensions to the Protocol.

=item *

Implements many of the I<Guidelines for Robot Writers>.

=item *

Configurable.

=item *

Builds on standard Perl 5 modules for WWW, HTTP, HTML, etc.

=back


A particular application (robot instance) has to configure
the engine using I<hooks>, which are perl functions invoked by the Robot
engine at specific points in the control loop.

The robot engine obeys the Robot Exclusion protocol,
as well as a proposed addition.
See L<SEE ALSO> for references to
documents describing the Robot Exclusion protocol and web robots.

=head1 QUESTIONS

This section contains a number of questions. I'm interested in hearing
what people think, and what you've done faced with similar questions.

=over

=item *

What style of API is preferable for setting attributes? Maybe
something like the following:

    $robot->verbose(1);
    $traversal = $robot->traversal();

I.e. a method for setting and getting each attribute,
depending on whether you passed an argument?

=item *

Should the robot module support a standard logging mechanism?
For example, an LOGFILE attribute, which is set to either a filename,
or a filehandle reference.
This would need a useful file format.

=item *

Should the AGENT be an attribute, so you can set this to whatever
UserAgent object you want to use?
Then if the attribute is not set by the first time the C<run()>
method is invoked, we'd fall back on the default.

=item *

Should TMPDIR and WORKFILE be attributes? I don't see any big reason
why they should, but someone else's application might benefit?

=item *

Should the module also support an ERRLOG attribute, with all warnings
and error messages sent there?

=item *

At the moment the robot will print warnings and error messages to stderr,
as well as returning error status. Should this behaviour be configurable?
I.e. the ability to turn off warnings.

=back

The basic architecture of the Robot is as follows:

    Hook: restore-state
    Get Next URL
        Hook: invoke-on-all-url
        Hook: follow-url-test
        Hook: invoke-on-follow-url
        Get contents of URL
        Hook: invoke-on-contents
        Skip if not HTML
        Foreach link on page:
            Hook: invoke-on-link
            Add link to robot's queue
    Continue? Hook: continue-test
    Hook: save-state
    Hook: generate-report

Each of the hook procedures and functions is described below.
A robot must provide a C<follow-url-test> hook,
and at least one of the following:

=over

=item *

C<invoke-on-all-url>

=item *

C<invoke-on-followed-url>

=item *

C<invoke-on-contents>

=item *

C<invoke-on-link>

=back

=cut

#=======================================================================

#-----------------------------------------------------------------------
#                        Global constants
#-----------------------------------------------------------------------
my %ATTRIBUTES =
(
 'NAME',                     'Name of the Robot',
 'VERSION',                  'Version of the Robot, N.NNN',
 'EMAIL',                    'Contact email address for Robot owner',
 'REQUEST_DELAY',           'Delay between requests to the same server',
 'TRAVERSAL',                'traversal order - depth or breadth',
 'VERBOSE',                  'boolean flag for verbose reporting',
 'IGNORE_TEXT',             'should we ignore text content of HTML?',
 'SITEROOTROOT',            'the string to check if the site is inside the desired web domain',
 'CACHEFILE',               'file which contains the cached results from previous run'
);

my %ATTRIBUTE_DEFAULT =
(
 'REQUEST_DELAY',           1,
 'TRAVERSAL',                'depth',
 'VERBOSE',                 0,
 'IGNORE_TEXT',             1
);


my %SUPPORTED_HOOKS =
(
 'restore-state',           'opportunity for client to restore state',
 'invoke-on-all-url',       'invoked on all URLs, even those not visited',
 'follow-url-test',         'return true if robot should visit the URL',
 'invoke-on-followed-url',  'invoked on only those URLs which are visited',
 'invoke-on-get-error',     'invoked when an HTTP request results in error',
 'invoke-on-contents',      'invoked on the contents of each visited URL',
 'invoke-on-link',          'invoked on all links seen on a page',
 'continue-test',           'return true if robot should continue iterating',
 'save-state',              'opportunity for client to save state after a run',
 'generate-report',         'report for the run just finished',
 'modified-since',          'returns a modified-since time for URL passed',
 'invoke-after-get',        'invoked right after every GET request',
);

#-----------------------------------------------------------------------
# A list of directories to try, in order, as the place where we will
# create temporary files. Last entry is '.' so we create in the current
# directory. What will this do on non-Unix boxen?
#-----------------------------------------------------------------------

my @TMPDIR_OPTIONS = ("$ENV{PERLTREE_HOME}/tmp");

#-----------------------------------------------------------------------
# The list of HTML elements we want to extract links from
# We list them explicitly, so the HTML::Parser won't include BASE
# elements.
#-----------------------------------------------------------------------
my @LINK_ELEMENTS       = qw(a img body form input link frame applet area);

#-----------------------------------------------------------------------
#        Private Global Variables
#-----------------------------------------------------------------------


#=======================================================================

=head1 CONSTRUCTOR

   $robot = new WWW::Robot( <attribute-value-pairs> );

Create a new robot engine instance.
If the constructor fails for any reason, a warning message will be printed,
and C<undef> will be returned.

Having created a new robot, it should be configured using the methods
described below.
Certain attributes of the Robot can be set during creation;
they can be (re)set after creation, using the C<setAttribute()> method.

The attributes of the Robot are described below,
in the I<Robot Attributes> section.

=cut

#=======================================================================
sub new
{
    my $class    = shift;
    my %options  = @ARG;

    my $object;


    #-------------------------------------------------------------------
    # The two argument version of bless() enables correct subclassing.
    # See the "perlbot" and "perlmod" documentation in perl distribution.
    #-------------------------------------------------------------------
    $object = bless {}, $class;

    print "Robot2 - starting\n";

    return $object->initialise(\%options);
}

#-----------------------------------------------------------------------

=head1 METHODS

=cut

#-----------------------------------------------------------------------

#=======================================================================

=head2 run

    $robot->run( LIST );

Invokes the robot, initially traversing the root URLs provided in LIST,
and any which have been provided with the C<addUrl()> method before
invoking C<run()>.
If you have not correctly configured the robot, the method will
return C<undef>.

The initial set of URLs can either be passed as arguments to the
B<run()> method, or with the B<addUrl()> method before you
invoke B<run()>.
Each URL can be specified either as a string,
or as a URI::URL object.

Before invoking this method, you should have provided at least some of
the hook functions.
See the example given in the EXAMPLES section below.

By default the B<run()> method will iterate until there are no more
URLs in the queue.
You can override this behavior by providing a C<continue-test> hook
function, which checks for the termination conditions.
This particular hook function, and use of hook functions in general,
are described below.

=cut

#=======================================================================

my %urls_list;
my %seen_url;

## This function reads the cached output of a previous run
## added by Gunes Erkan
sub retrieve_cached_urls {
  my $self = shift;

  my $filename = shift;

  my $processed;

  open (INPUT, "<$filename");

  while (<INPUT>) {
        chomp;

        if (/^http/) {
                print "$_\n";
                delete $urls_list{$_};
        }

        elsif (/^adding: (.*)\s*$/) {
                $self->addUrl($1);
        }

        elsif (/^processing: (.*)\s*$/) {
                if ($processed) {
                    delete $urls_list{$processed};
                }
                $processed = $1;
        }
  }

  close INPUT;
}


sub run
{
    my $self      = shift;
    my @url_list  = @ARG;                        # optional list of URLs

    my $url;
    my $filename;
    my $response;
    my @page_urls;
    my $link_url;
    my $structure;
    my $noindex;
    my $nofollow;

    # Added 01/14/2007 jgerrish
    # Commented out by premgane, Jun 8 2009
    #dbmopen %urls_list, "urls_list", 0666 or die "Couldn't open urls_list dbm";
    #dbmopen %seen_url, "seen_url", 0666 or die "Couldn't open seen_url dbm";

    $self->pre_run_check() || return undef;

    if ($self->{'CACHEFILE'}) {
        $self->retrieve_cached_urls ($self->{'CACHEFILE'});
    }
    else {
        $self->addUrl(@url_list);
    }

    $self->invoke_hook_procedures('restore-state');
    my $count=0;
    #-------------------------------------------------------------------
    # MAIN LOOP of the robot. Of course this is all obvious, so we won't
    # go into it. Comment above describes the basic architecture.
    #-------------------------------------------------------------------

    while (my $nextUrl = $self->next_url())
    {
         $url = $nextUrl;
         print "processing: $url\n";

      local $@;
      eval{

         $self->verbose($url, "\n");

            $self->invoke_hook_procedures('invoke-on-all-url', $url);
      };
      if($@)
      {
        print "Exception caught in block A with url $url\n$@";
        next;
      }
        if (not($self->invoke_hook_functions('follow-url-test', $url))) {
                print "test failed: $url\n";
                next;
        }

      eval{
         $self->invoke_hook_procedures('invoke-on-followed-url', $url);
      };
      if($@)
      {
        print "Exception caught in block B with url $url.\n$@";
        next;
      }
      my $message;
      eval{
          ($response, $structure, $filename, $message) = $self->get_url($url);
      };
      if($@)
      {
        print "Exception caught in block C with url $url.\n$@";
        next;
      }

      if ($message) { print "$message: $url\n";  next;}

        #---------------------------------------------------------------
        # This hook function is for people who want to see the result
        # of every GET, so they can deal with odd cases, or whatever
        #---------------------------------------------------------------

      eval{

       $self->invoke_hook_procedures('invoke-after-get', $url, $response);
      };
      if($@)
      {
        print "Exception caught in block D with url $url.\n$@";
        next;
      }

      eval{
       if ($response->is_error)
        {
            $self->invoke_hook_procedures('invoke-on-get-error',
                                           $url, $response);
            next;
        }
      };
      if($@)
      {
        print "Exception caught in block D.5 with url $url.\n$@";
        next;
      }

        if ($response->code == RC_NOT_MODIFIED) {
                print "response code RC_NOT_MODIFIED: $url\n";
                next;
        }

        #---------------------------------------------------------------
        # The response says we should use something else as the BASE
        # from which to resolve any relative URLs. This might be from
        # a BASE element in the HEAD, or just "foo" which should be "foo/"
        #---------------------------------------------------------------

      eval{
         if ($response->base ne $url)
         {
             $url = new URI::URL($response->base);
         }
      };
      if($@)
      {
        print "Exception caught in block E with url $url.\n$@";
        next;
      }

        #---------------------------------------------------------------
        # Check page for page specific robot exclusion commands
        #---------------------------------------------------------------

      eval{
         if ($response->content_type eq 'text/html')
         {
            ($noindex, $nofollow) = $self->check_protocol($structure, $url);
            if ($nofollow == 0)
            {
                @page_urls = $self->extract_links($url, $response, $structure,
                                                   $filename);
            }
         }
      };
      if($@)
      {
        print "Exception caught in block F with url $url.\n$@";
        next;
      }
      eval{
        if ($noindex == 0)
        {
            # we invoke with oldurl, so robot app sees it
            $self->invoke_hook_procedures('invoke-on-contents', $url,
                                           $response, $structure, $filename);
        }
      };
      if($@)
      {
        print "Exception caught in block G with url $url.\n$@";
        next;
      }

      eval{
         $structure->delete() if defined $structure;
      };
      if($@)
      {
        print "Exception caught in block H with url $url.\n$@";
        next;
      }

      if (not $response->content_type eq 'text/html') {
                print "content not html: $url\n";        next;
      }

      eval{
        foreach $link_url (@page_urls)
        {
            $self->invoke_hook_procedures('invoke-on-link', $url, $link_url);
            $self->addUrl($link_url);
        }
      };
      if($@)
      {
        print "Exception caught in block I with url $url.\n$@";
        next;
      }
    }
    continue
    {
        #------------------------------------------------------------------
        # If there is no continue-test hook, then we will continue until
        # there are no more URLs.
        #------------------------------------------------------------------
        last if (exists $self->{'HOOKS'}->{'continue-test'}
                 && not $self->invoke_hook_functions('continue-test'));

    }

    $self->invoke_hook_procedures('save-state');
    $self->invoke_hook_procedures('generate-report');

    # Close the dbm files
    # Commented out by premgane, Jun 8 2009
    #dbmclose %seen_url;
    #dbmclose %urls_list;

    return 1;
}

#=======================================================================
# pre_run_check() - check that all required configuration has been done
#
# This private method is called just before we enter the main control
# loop in the run() method, to make sure that everything is set up right.
#=======================================================================
sub pre_run_check
{
    my $self = shift;


    #-------------------------------------------------------------------
    # Check that mandatory attributes have been set
    #-------------------------------------------------------------------
    if (!exists $self->{'NAME'}
        || !exists $self->{'VERSION'}
        || !exists $self->{'EMAIL'})
    {
        $self->warn("You haven't set all of the required robot attributes.",
                    "They are: NAME, VERSION and EMAIL attributes");
        return undef;
    }

    #-------------------------------------------------------------------
    # The robot application must provide a follow-url-test hook
    #-------------------------------------------------------------------
    if (!exists $self->{'HOOKS'}->{'follow-url-test'})
    {
        $self->warn("You must provide a `follow-url-test' hook.");
        return undef;
    }

    #-------------------------------------------------------------------
    # You must provide at least one of the following hook functions
    #-------------------------------------------------------------------
    if (not (   exists $self->{'HOOKS'}->{'invoke-on-all-url'}
             || exists $self->{'HOOKS'}->{'invoke-on-followed-url'}
             || exists $self->{'HOOKS'}->{'invoke-on-contents'}
             || exists $self->{'HOOKS'}->{'invoke-on-link'}))
    {
        $self->warn("You must provide at least one invoke-on-* hook.",
                    "Please see the documentation.\n");
        return undef;
    }

    return 1;
}

#=======================================================================
# extract_links() - extract links from a file
#        $url      - a URI::URL object for the URL we're extracting links from
#        $response - a HTTP::Response object for the response of the GET
#        $filename - the path to the local file which is a copy of contents
#   RETURNS     a LIST of the extracted links
#
# This function calls &check_image_map while traversing the parsed HTML to
# check avoid links to server side image maps that are covered by
# client side image maps.
#
#=======================================================================
sub extract_links
{
    my $self        = shift;
    my $url         = shift;
    my $response    = shift;
    my $structure   = shift;
    my $filename    = shift;

    my $link;
    my @link;
    my $element;                                # of type HTTP::Element
    my $link_url;
    my $tuple;
    my %seenLinkTo;
    my $ismap;
    my $usemap;

    foreach $tuple (@{ $structure->extract_links(@LINK_ELEMENTS) })
    {
        ($link, $element) = @$tuple;

        #---------------------------------------------------------------
        # If the element is an Anchor (<A HREF="...">...</A>), then we
        # check to see if the content is an image, with ISMAP or USEMAP,
        # i.e. an image-map. If so, then we ignore the Anchor element.
        #---------------------------------------------------------------
        if ($element->tag() eq 'a')
        {
            $usemap = $ismap = undef;
            $element->traverse(sub
                               {
                                   my $node        = shift;
                                   my $start_flag  = shift;
                                   my $depth       = shift;


                                   return 1 unless $start_flag;
                                   if ($node->tag() eq 'img')
                                   {
                                       $ismap  = $node->attr('ismap');
                                       $usemap = $node->attr('usemap');
                                       return 0;
                                   }

                                   return 1;
                               }, 1);
            next if defined $ismap && defined $usemap;
        }

        #---------------------------------------------------------------
        # ignore any links to within the same page
        #---------------------------------------------------------------
        next if $link =~ m!^#!;

        #---------------------------------------------------------------
        # strip off any markers to within a page
        #---------------------------------------------------------------
        $link =~ s!#.*$!!;

        #---------------------------------------------------------------
        # should we strip off anything after "?" - i.e. args?
        #---------------------------------------------------------------
        # $link =~ s!\?.*$!!;

        #---------------------------------------------------------------
        # check that we haven't already traversed this page
        # if we haven't, then mark it as seen, and continue
        #---------------------------------------------------------------
        next if exists $seenLinkTo{$link};
        $seenLinkTo{$link} = 1;

        $link_url = eval { new URI::URL($link, $url) };

        if ($EVAL_ERROR)
        {
            $self->warn("unable to create URL object for link.",
                        "LINK:  $link",
                        "Error: $EVAL_ERROR\n");
            next;
        }

        push(@link, $link_url->abs());
    }

    return @link;
}

#=======================================================================
# check_protocol() - check the page for per-page robot exclusion commands
#        $structure - an HTML::Element object for the page to check
#
# This function looks for page specific robot exclusion commands.
# At the moment the only one we look for is the META element with
# a NAME attribute of ROBOTS:
#
#        <META NAME="ROBOTS" CONTENT="NOINDEX">
#                This means that the Robot should not look at the contents
#                of this page. Ok to follow links though.
#
#        <META NAME="ROBOTS" CONTENT="NOFOLLOW">
#                This means that the Robot should ignore any links on this
#                page. Ok to look at the contents though.
#
#        CONTENT="NONE" is NOINDEX and NOFOLLOW together. You can also
#       specify this with CONTENT="nofollow,noindex"
#=======================================================================
sub check_protocol
{
    my $self       = shift;
    my $structure  = shift;
    my $url        = shift;

    my $noindex    = 0;
    my $nofollow   = 0;


    #-------------------------------------------------------------------
    # recursively traverse the page elements, looking for META with
    # NAME=ROBOTS, then look for directives in the CONTENTS.
    #-------------------------------------------------------------------
    $structure->traverse(sub
                         {
                             my $node        = shift;
                             my $start_flag  = shift;
                             my $depth       = shift;

                             my $directive;
                             my $name;
                             my $content;

                             return 1 unless $start_flag;
                             return 1 if $node->tag() ne 'meta';
                             $name = $node->attr('name');
                             return 1 unless defined $name;
                             return 1 unless lc($name) eq 'robots';
                             $content = lc($node->attr('content'));
                             foreach $directive (split(/,/, $content))
                             {
                                 $nofollow = 1 if ($directive eq 'nofollow'
                                                   || $directive eq 'none');
                                 $noindex  = 1 if ($directive eq 'noindex'
                                                   || $directive eq 'none');
                             }

                             return 0;
                         },
                         1);

    $self->verbose("  ROBOT EXCLUSION -- IGNORING LINKS\n")   if $nofollow;
    $self->verbose("  ROBOT EXCLUSION -- IGNORING CONTENT\n") if $noindex;

    return ($noindex, $nofollow);
}


#=======================================================================
# get_url() - retrieve the document referenced by a url
#        $url        - the URL to retrieve (a URI::URL object, or text URL)
#        RETURNS          the path to the local temp file which contains URL
#
# This function takes a URL and retrieves the file referenced.
# We return the path to the local temporary file which contains a
# copy of the file referenced.
# The caller is expected to unlink the file once it is no longer needed.
#=======================================================================
sub get_url
{
    my $self       = shift;
    my $url        = shift;

    my $request = HTTP::Request->new('GET',$url);
    if (not defined $request) { print "REQUEST NOT DEFINED\n"; }

    my $filename   = $self->{'WORKFILE'};
    my $response;
    my $fh;
    my $structure;


    #---------------------------------------------------------------------
    # Is there a modified-since hook?
    #---------------------------------------------------------------------
    if (exists $self->{'HOOKS'}->{'modified-since'})
    {
        my $time = $self->invoke_hook_functions('modified-since', $url);


        if (defined $time && $time > 0)
        {
            $request->if_modified_since(int($time));
        }
    }

    #---------------------------------------------------------------------
    # make the request
    #---------------------------------------------------------------------
    $response = $self->{'AGENT'}->request($request);

    if (not defined $response) { print "RESPONSE NOT DEFINED\n"; }

    $request = undef;

    #-------------------------------------------------------------------
    # If the request failed, or we get a 304 (not modified), then we
    # can stop at this point.
    #-------------------------------------------------------------------

    if ($response->is_error )
    {
        return ($response, undef, undef, "RESPONSE Error: ". $response->code ." " . $response->message);
    }
    elsif ($response->code == RC_NOT_MODIFIED)
    {
        return ($response, undef, undef, "RC_NOT_MODIFIED");
    }


    #---------------------------------------------------------------------
    # create a local copy of the URL's contents
    #---------------------------------------------------------------------
##open (TEMPFILE,">$filename");

##    unless (defined $fh)
#    $fh = new IO::File(">$filename");
#    if (!defined $fh)
#    {
#        $self->warn("failed to open work file for local copy of URL",
#                    "URL:   $url",
#                    "Error: $OS_ERROR");
#        return ($response, undef, undef, "FILE ERROR $OS_ERROR");
#    }

#temporarily:
#   else {
#        $self->warn("failed to open work file for local copy of URL",
#                    "URL:   $url",
#                    "Error: $OS_ERROR");
#        return ($response, undef, undef);
#    }

#    print $fh $response->content;
#    $fh->close;

##my $real_response = uri_escape($response->content);
##print TEMPFILE $real_response;
##close TEMPFILE;

    #---------------------------------------------------------------------
    # Parse the HTML into a structure which we can traverse, etc.
    #---------------------------------------------------------------------
    if ($response->content_type eq 'text/html')
    {
        $structure = parse_html($response->content);
    }

    return ($response, $structure, $filename);
}

#=======================================================================
# initialise() - initialise global variables, contents, tables, etc
#        $self   - the robot object being initialised
#        @options - a LIST of (attribute, value) pairs, used to specify
#                   initial values for robot attributes.
#        RETURNS    undef if we failed for some reason, non-zero for success.
#
# Initialise the robot, setting various attributes, and creating the
# User Agent which is used to make requests.
#=======================================================================
sub initialise
{
    my $self     = shift;
    my $options  = shift;

    my $attribute;


    $self->create_agent() || return undef;

    #---------------------------------------------------------------------
    # set attributes which are passed as arguments
    #---------------------------------------------------------------------
    foreach $attribute (keys %$options)
    {
        $self->setAttribute($attribute, $options->{$attribute});
    }

    #---------------------------------------------------------------------
    # set those attributes which have a default value,
    # and which weren't set on creation.
    #---------------------------------------------------------------------
    foreach $attribute (keys %ATTRIBUTE_DEFAULT)
    {
        if (!exists $self->{$attribute})
        {
            $self->{$attribute} = $ATTRIBUTE_DEFAULT{$attribute};
        }
    }

    #---------------------------------------------------------------------
    # TMPDIR is the directory to create any temporary files in.
    # WORKFILE is where we put our local copy of URLs.
    #---------------------------------------------------------------------
    if (!exists $self->{'TMPDIR'})
    {
        $self->{'TMPDIR'} = &pick_tmpdir($self, @TMPDIR_OPTIONS);
    }
    $self->{'WORKFILE'} = $self->{'TMPDIR'}.'/'.$self->{'NAME'}.$$;

    return $self;
}

#=======================================================================
# create_agent() - create the User-Agent which will perform requests
#
# $self->{'AGENT'} holds the UserAgent object we use to perform
# HTTP requests. The RobotUA class gives us a UserAgent which follows
# the robot exclusion protocol.
#=======================================================================
sub create_agent
{
    my $self = shift;

    foreach my $i (@INC) {
        print STDERR "$i\n";
    }
    print STDERR "**\n";

    eval { $self->{'AGENT'} = new LWP::RobotUA('Poacher', $EMAIL) };
    if (!$self->{'AGENT'})
    {
        $self->warn("failed to create User Agent object.",
                    "Error: $EVAL_ERROR\n");
        return undef;
    }

    return 1;
}

#=======================================================================

=head2 setAttribute

  $robot->setAttribute( ... attribute-value-pairs ... );

Change the value of one or more robot attributes.
Attributes are identified using a string, and take scalar values.
For example, to specify the name of your robot,
you set the C<NAME> attribute:

   $robot->setAttribute('NAME' => 'WebStud');

The supported attributes for the Robot module are listed below,
in the I<ROBOT ATTRIBUTES> section.

=cut

#-----------------------------------------------------------------------
# Don't look Ma! It's gross.
# This is left-over-from-the-early-days-code. Due for a rework. Sorry.
#=======================================================================
sub setAttribute
{
    my $self   = shift;
    my @attrs  = @ARG;

    my $attribute;
    my $value;


    while (@attrs > 1)
    {
        $attribute = shift @attrs;
        $value     = shift @attrs;

        if (!exists $ATTRIBUTES{$attribute})
        {
            $self->warn("unknown attribute in setAttribute() - ignoring it.",
                        "Attribute: $attribute");
            next;
        }
        $self->set_attribute($attribute, $value);
    }
    $self->warn("odd number of arguments to setAttribute!") if @attrs > 0;
}

#=======================================================================
# set_attribute() - actually sets attribute, and performs associated actions
#        $attribute - name of attribute to set
#        $new_value - new value for the specified attribute
#
# This private function is invoked from the setAttribute() method,
# and is used to actually set the value of an attribute. We also
# perform any actions which are associated with setting the attribute.
#
# NOTE: This assumes that the AGENT exists. A fair assumption at the
#       moment, though that might change, and then this will have to too!
#=======================================================================
sub set_attribute
{
    my $self       = shift;
    my $attribute  = shift;
    my $new_value  = shift;


    $self->{$attribute} = $new_value;

    if ($attribute eq 'IGNORE_TEXT')
    {
        #---------------------------------------------------------------
        # when building structure of HTML, do we include content?
        #---------------------------------------------------------------
        $HTML::Parse::IGNORE_TEXT = $new_value;
    }
    elsif ($attribute eq 'TRAVERSAL')
    {
        #---------------------------------------------------------------
        # check that TRAVERSAL is set to a legal value
        #---------------------------------------------------------------
        if ($new_value ne 'depth' && $new_value ne 'breadth')
        {
            $self->warn("ignoring unknown traversal method, using `depth'.",
                        "Value: $new_value");;
            $self->{'TRAVERSAL'} = 'depth';
        }
    }
    elsif ($attribute eq 'EMAIL')
    {
        $self->{'AGENT'}->from($new_value);
    }
    elsif (($attribute eq 'NAME' || $attribute eq 'VERSION')
           && defined $self->{'NAME'} && defined $self->{'VERSION'})
    {
        $self->{'AGENT'}->agent($self->{'NAME'}.'/'.$self->{'VERSION'});
    }
    elsif ($attribute eq 'REQUEST_DELAY')
    {
        $self->{'AGENT'}->delay($new_value);
    }
    $self->{'AGENT'}->use_sleep(0);
    $self->{'AGENT'}->timeout(10);
}

#=======================================================================

=head2 getAttribute

  $value = $robot->getAttribute('attribute-name');

Queries a Robot for the value of an attribute.
For example, to query the version number of your robot,
you would get the C<VERSION> attribute:

   $version = $robot->getAttribute('VERSION');

The supported attributes for the Robot module are listed below,
in the I<ROBOT ATTRIBUTES> section.

=cut

#=======================================================================
sub getAttribute
{
    my $self       = shift;
    my $attribute  = shift;


    if (!exists $ATTRIBUTES{$attribute})
    {
        $self->warn("unknown attribute passed to getAttribute()",
                    "Attribute: $attribute",
                    "Returning: undef");
        return undef;
    }

    return $self->{$attribute};
}

#=======================================================================

=head2 addUrl

  $robot->addUrl( $url1, ..., $urlN );

Used to add one or more URLs to the queue for the robot.
Each URL can be passed as a simple string,
or as a URI::URL object.

Returns True (non-zero) if all URLs were successfully added,
False (zero) if at least one of the URLs could not be added.

=cut

#=======================================================================
sub addUrl
{
    my $self       = shift;
    my @list       = @ARG;

    my $status     = 1;
    my $url;
    my $urlObject;
   # my $ct = 0;
#open(F2, ">>/data0/projects/glat/mdu/url_listing");
    foreach my $newurl (@list)
    {
      $url = $newurl;

      # check if we already visited this URL
        if (exists $seen_url{$url}) {
                next;
         }
	#$ct++;
	#print F2 "$ct \t $url \n";
	#print STDERR "$ct \t $url \n";
      # check if the URL belongs to the domain
        if (!($url =~ /$self->{'SITEROOTROOT'}/)) {
                print "external link, so skipped $url\n";
                next;
        }

    # check if the URL extension is OK
    if ($url =~ /https?:\/\/.*\/[^\/]*\.([^\/\.]+)\/*$/)
    {
        my $extension = $1;
        if
         ($extension =~ /^jpg$/i
       || $extension =~ /^zip$/i
       || $extension =~ /^gz$/i
       || $extension =~ /^gif$/i
       || $extension =~ /^pdf$/i
       || $extension =~ /^ps$/i
       || $extension =~ /^ppt$/i
       || $extension =~ /^png$/i
       || $extension =~ /^doc$/i
       || $extension =~ /^pps$/i
       || $extension =~ /^tar$/i
       || $extension =~ /^tgz$/i
       || $extension =~ /^mov$/i
       || $extension =~ /^avi$/i
       || $extension =~ /^mpg$/i
       || $extension =~ /^mp3$/i
       || $extension =~ /^mpeg$/i
       || $extension =~ /^wmv$/i
       || $extension =~ /^xls$/i) {
                print "extension is $extension, so skipped $url\n";
                next;
        }
    }

        # check if the URL is cgi-scripted or anything like that
        # does not work perfectly. add the unwanted urls into the
        # forbidden_urls file if something goes wrong
        my $base;

        if ($url =~ /^(.*?\?).+=/) {
                $base = $1;
        }

        if($base) {
          print "cgi: $url\n";
        }

        # check if we visited 100 different copies of the scripted page before
        if ($base && (exists $seen_url{$base}) && $seen_url{$base} >= 100) {
                print "cgi limit reached for $base\n";
                next;
        }

        #---------------------------------------------------------------
        # Mark the URL as having been seen by the robot, then add it
        # to the list of URLs for the robot to visit. Doing it this way
        # means we won't get duplicate URLs on the list.
        #---------------------------------------------------------------
        print "adding: $url\n";
        # increment the count of the "base" of the scripted page
        if ($base) {
                $seen_url{$base}++;
        }
        $seen_url{$url} = 1;
        $urls_list{$url} = 1
                if defined $url;
    }
#close(F2);
    return $status;
}

#========================================================================
# next_url() - get the next URL which should be traversed
#        RETURNS the next URL to visit, or undef if there are no
#                URLs on the list.
#
# This function is used to get the next URL which the robot should visit.
# Depending on the traversal order, we get the next URL from the front
# or back of the list of unvisited URLs.
#========================================================================

sub next_url
{
    my $self    = shift;


    #-------------------------------------------------------------------
    # We return 'undef' to signify no URLs on the list
    #-------------------------------------------------------------------

    my $urlObject;

    return 0 unless (keys %urls_list);

   my ($url, $value) = each %urls_list;
   delete $urls_list{$url} ;

   $urlObject = eval { new URI::URL($url) };
        if ($EVAL_ERROR)
        {
           $self->warn("addUrl() unable to create URI::URL object",
                       "URL:   $url",
                       "Error: $EVAL_ERROR");
           next;
        }

   unless (defined $urlObject)
   {
     return undef;
   }

   # for now we're using a hash, so the search will be neither depth-first
   # nor breadth-first.  just whatever hash element comes up.
   # hash keys are simple URL strings. But we return a URL object here

    return $urlObject;
}

#========================================================================
# invoke_hook_procedures() - invoke a specific set of hook procedures
#        $self      - the object for the robot we're invoking hooks on
#        $hook_name - a string identifying the hook functions to invoke
#        @argv      - zero or more arguments which are passed to hook function
#
# This is used to invoke hooks which do not return any value.
#========================================================================
sub invoke_hook_procedures
{
    my $self       = shift;
    my $hook_name  = shift;
    my @argv       = @ARG;

    my $hookfn;


    return unless exists $self->{'HOOKS'}->{$hook_name};

    foreach $hookfn (@{ $self->{'HOOKS'}->{$hook_name} })
    {
        &$hookfn($self, $hook_name, @argv);
    }

    return;
}

#========================================================================
# invoke_hook_functions() - invoke a specific set of hook functions
#        $self     - the object for the robot we're invoking hooks on
#        $hook_name - a string identifying the hook functions to invoke
#        @argv      - zero or more arguments which are passed to hook function
#
# This is used to invoke hooks which return a success/failure value.
# If there is more than one function for the hook, we OR the results
# together, so that if one passes, the hook is deemed to have passed.
#========================================================================
sub invoke_hook_functions
{
    my $self       = shift;
    my $hook_name  = shift;
    my @argv       = @ARG;

    my $result     = 0;
    my $hookfn;


    return $result unless exists $self->{'HOOKS'}->{$hook_name};

    foreach $hookfn (@{ $self->{'HOOKS'}->{$hook_name} })
    {
        $result |= &$hookfn($self, $hook_name, @argv);
    }

    return $result;
}

#=======================================================================

=head2 addHook

  $robot->addHook($hook_name, \&hook_function);

  sub hook_function { ... }

Register a I<hook> function which should be invoked by the robot at
a specific point in the control flow. There are a number of
I<hook points> in the robot, which are identified by a string.
For a list of hook points, see the B<SUPPORTED HOOKS> section below.

If you provide more than one function for a particular hook,
then the hook functions will be invoked in the order they were added.
I.e. the first hook function called will be the first hook function
you added.

=cut

#=======================================================================
sub addHook
{
    my $self       = shift;
    my $hook_name  = shift;
    my $hook_fn    = shift;


    if (!exists $SUPPORTED_HOOKS{$hook_name})
    {
        $self->warn("unknown hook name passed to addHook(). Ignoring it!",
                    "Hook Name: $hook_name");
        return undef;
    }

    if (ref($hook_fn) ne 'CODE')
    {
        $self->warn("not function reference passed to addHook(). Ignoring.",
                    "Hook Name: $hook_name");
        return undef;
    }

    if (exists $self->{'HOOKS'}->{$hook_name})
    {
        push(@{ $self->{'HOOKS'}->{$hook_name} }, $hook_fn);
    }
    else
    {
        $self->{'HOOKS'}->{$hook_name} = [$hook_fn];
    }

    return 1;
}

#=======================================================================

=head2 proxy, no_proxy, env_proxy

These are convenience functions are setting proxy information on the
User agent being used to make the requests.

    $robot->proxy( protocol, proxy );

Used to specify a proxy for the given scheme.
The protocol argument can be a reference to a list of protocols.

    $robot->no_proxy(domain1, ... domainN);

Specifies that proxies should not be used for the specified
domains or hosts.

    $robot->env_proxy();

Load proxy settings from I<protocol>B<_proxy> environment variables:
C<ftp_proxy>, C<http_proxy>, C<no_proxy>, etc.

=cut

#=======================================================================
# proxy(), no_proxy(), env_proxy() - proxy setting routines
#
# These routines mirror those provide by the UserAgent. We just
# pass arguments to the equivalent methods on the Agent.
#=======================================================================
sub proxy
{
    my $self  = shift;
    my @argv  = @ARG;


    return $self->{'AGENT'}->proxy(@argv);
}

sub no_proxy
{
    my $self  = shift;
    my @argv  = @ARG;


    return $self->{'AGENT'}->no_proxy(@argv);
}

sub env_proxy
{
    my $self  = shift;


    return $self->{'AGENT'}->env_proxy();
}

sub DESTROY
{
    my $self = shift;


    unlink $self->{'WORKFILE'} if defined $self->{'WORKFILE'};
}

#========================================================================
# pick_tmpdir() - pick a temporary working directory
#        @options - a list of possible directories
#
# This function takes a list of directories and tries them in order
# until it finds one which exists, and which we have write permission to.
# If we find one, then the path is returned, as a directory in which
# we can create temporary working files. If all else fails, we default
# to '.', the current directory.
#
# If the TMPDIR environment variable is set, then we try that directory
# first.
#========================================================================
sub pick_tmpdir
{
    my $self     = shift;
    my @options  = @ARG;

    my $tmpdir;
    my $ROBOT    = $self->{'NAME'};


    unshift(@options, $ENV{'TMPDIR'}) if exists $ENV{'TMPDIR'};
    foreach $tmpdir (@options)
    {
        return $tmpdir if (-d $tmpdir && -w $tmpdir);
    }

    $self->warn("unable to find a temporary directory.",
                "I tried: ".join(' ', @options));
    return undef;
}

#========================================================================
# verbose() - display a reporting message if we're in verbose mode
#        $self  - the robot object
#        @lines - a LIST of one or more strings, which are print'ed to
#                 standard error output (STDERR) if VERBOSE attribute has
#                 been set on the robot.
#========================================================================
sub verbose
{
    my $self   = shift;
    my @lines  = @ARG;


    print STDERR @lines if $self->{'VERBOSE'};
}

#========================================================================
# warn() - our own warning routine, generate standard format warnings
#========================================================================
sub warn
{
    my $self  = shift;
    my @lines = shift;

    my $me    = ref $self;
    my $line;


    print STDERR "$me: ", shift @lines, "\n";
    foreach $line (@lines)
    {
        print STDERR ' ' x (length($me) +2), $line, "\n";
    }
}

#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
#
#                END OF CODE - POD DOCUMENTATION FOLLOWS
#
#-----------------------------------------------------------------------
#-----------------------------------------------------------------------

=head1 ROBOT ATTRIBUTES

This section lists the attributes used to configure a Robot object.
Attributes are set using the C<setAttribute()> method,
and queried using the C<getAttribute()> method.

Some of the attributes B<must> be set before you start the Robot
(with the C<run()> method).
These are marked as B<mandatory> in the list below.

=over

=item NAME

The name of the Robot.
This should be a sequence of alphanumeric characters,
and is used to identify your Robot.
This is used to set the C<User-Agent> field of HTTP requests,
and so will appear in server logs.

B<mandatory>

=item VERSION

The version number of your Robot.
This should be a floating point number,
in the format B<N.NNN>.

B<mandatory>

=item EMAIL

A valid email address which can be used to contact the Robot's owner,
for example by someone who wishes to complain about the behavior of
your robot.

B<mandatory>

=item VERBOSE

A boolean flag which specifies whether the Robot should display verbose
status information as it runs.

Default: 0 (false)

=item TRAVERSAL

Specifies what traversal style should be adopted by the Robot.
Valid values are I<depth> and I<breadth>.

Default: depth

=item REQUEST_DELAY

Specifies whether the delay (in minutes) between successive GETs
from the same server.

Default: 1

=item IGNORE_TEXT

Specifies whether the HTML structure passed to the I<invoke-on-contents>
hook function should include the textual content of the page,
or just the HTML elements.

Default: 1 (true)

=back

=head1 SUPPORTED HOOKS

This section lists the hooks which are supported by the WWW::Robot module.
The first two arguments passed to a hook function are always the Robot
object followed by the name of the hook being invoked. I.e. the start of
a hook function should look something like:

    sub my_hook_function
    {
        my $robot = shift;
        my $hook  = shift;
        # ... other, hook-specific, arguments

Wherever a hook function is passed a C<$url> argument,
this will be a URI::URL object, with the URL fully specified.
I.e. even if the URL was seen in a relative link,
it will be passed as an absolute URL.


=head2 restore-state

   sub hook { my($robot, $hook_name) = @_; }

This hook is invoked just before entering the main iterative loop
of the robot.
The intention is that the hook will be used to restore state,
if such an operation is required.

This can be helpful if the robot is running in an incremental mode,
where state is saved between each run of the robot.



=head2 invoke-on-all-url

   sub hook { my($robot, $hook_name, $url) = @_; }

This hook is invoked on all URLs seen by the robot,
regardless of whether the URL is actually traversed.
In addition to the standard C<$robot> and C<$hook> arguments,
the third argument is C<$url>, which is the URL being travered by
the robot.

For a given URL, the hook function will be invoked at most once,
regardless of how many times the URL is seen by the Robot.
If you are interested in seeing the URL every time,
you can use the B<invoke-on-link> hook.



=head2 follow-url-test

   sub hook { my($robot, $hook_name, $url) = @_; return $boolean; }

This hook is invoked to determine whether the robot should traverse
the given URL.
If the hook function returns 0 (zero),
then the robot will do nothing further with the URL.
If the hook function returns non-zero,
then the robot will get the contents of the URL,
invoke further hooks,
and extract links if the contents are HTML.



=head2 invoke-on-followed-url

   sub hook { my($robot, $hook_name, $url) = @_; }

This hook is invoked on URLs which are about to be traversed by the robot;
i.e. URLs which have passed the follow-url-test hook.



=head2 invoke-on-get-error

   sub hook { my($robot, $hook_name, $url, $response) = @_; }

This hook is invoked if the Robot ever fails to get the contents
of a URL.
The C<$response> argument is an object of type HTTP::Response.



=head2 invoke-on-contents

   sub hook { my($robot, $hook, $url, $response, $structure, $filename) = @_; }

This hook function is invoked for all URLs for which the contents
are successfully retrieved.

The C<$url> argument is a URI::URL object for the URL currently being
processed by the Robot engine.

The C<$response> argument is an HTTP::Response object,
the result of the GET request on the URL.

The C<$structure> argument is an
HTML::Element object which is the root of a tree structure constructed
from the contents of the URL.
You can set the C<IGNORE_TEXT> attribute to specify whether the structure
passed includes the textual content of the page,
or just the HTML elements.

The C<$filename> argument is
the path to a local temporary file which contains
a local copy of the URL contents.
You cannot assume that the file will exist after control has returned
from your hook function.



=head2 invoke-on-link

   sub hook { my($robot, $hook_name, $from_url, $to_url) = @_; }

This hook function is invoked for all links seen as the robot traverses.
When the robot is parsing a page (B<$from_url>) for links,
for every link seen the I<invoke-on-link> hook is invoked with the URL
of the source page, and the destination URL.
The destination URL is in canonical form.


=head2 continue-test

   sub hook { my($robot) = @_; }

This hook is invoked at the end of the robot's main iterative loop.
If the hook function returns non-zero, then the robot will continue
execution with the next URL.
If the hook function returns zero,
then the Robot will terminate the main loop, and close down
after invoking the following two hooks.

If no C<continue-test> hook function is provided,
then the robot will always loop.

=head2 save-state

   sub hook { my($robot) = @_; }

This hook is used to save any state information required by the robot
application.

=head2 generate-report

   sub hook { my($robot) = @_; }

This hook is used to generate a report for the run of the robot,
if such is desired.


=head2 modified-since

If you provide this hook function, it will be invoked for each URL
before the robot actually requests it.
The function can return a time to use with the If-Modified-Since
HTTP header.
This can be used by a robot to only process those pages which have
changed since the last visit.

Your hook function should be declared as follows:

    sub modifed_since_hook
    {
        my $robot = shift;        # instance of Robot module
        my $hook  = shift;        # name of hook invoked
        my $url   = shift;        # URI::URL for the url in question

        # ... calculate time ...
        return $time;
    }

If your function returns anything other than C<undef>,
then a B<If-Modified-Since:> field will be added to the request header.


=head2 invoke-after-get

This hook function is invoked immediately after the robot makes
each GET request.
This means your hook function will see every type of response,
not just successful GETs.
The hook function is passed two arguments: the C<$url> we tried to GET,
and the C<$response> which resulted.

If you provided a L<modified-since> hook, then provide an invoke-after-get
function, and look for error code 304 (or RC_NOT_MODIFIED if you are
using HTTP::Status, which you should be :-):

    sub after_get_hook
    {
        my($robot, $hook, $url, $response) = @_;

        if ($response->code == RC_NOT_MODIFIED) {
                # ...
        }
    }


=head1 EXAMPLES

This section illustrates use of the Robot module,
with code snippets from several sample Robot applications.
The code here is not intended to show the right way to code a web robot,
but just illustrates the API for using the Robot.

=head2 Validating Robot

This is a simple robot which you could use to validate your web site.
The robot uses B<weblint> to check the contents of URLs of type
B<text/html>

   #!/usr/bin/perl
   require 5.002;
   use WWW::Robot;

   $rootDocument = $ARGV[0];

   $robot = new WWW::Robot('NAME'     =>  'Validator',
                           'VERSION'  =>  1.000,
                           'EMAIL'    =>  'fred@foobar.com');

   $robot->addHook('follow-url-test', \&follow_test);
   $robot->addHook('invoke-on-contents', \&validate_contents);

   $robot->run($rootDocument);

   #-------------------------------------------------------
   sub follow_test {
      my($robot, $hook, $url) = @_;
      return 0 unless $url->scheme eq 'http';
      return 0 if $url =~ /\.(gif|jpg|png|xbm|au|wav|mpg)$/;

      #---- we're only interested in pages on our site ----
      return $url =~ /^$rootDocument/;
   }

   #-------------------------------------------------------
   sub validate_contents {
      my($robot, $hook, $url, $response, $filename) = @_;

      return unless $response->content_type eq 'text/html';

      print STDERR "\n$url\n";

      #---- run weblint on local copy of URL contents -----
      system("weblint -s $filename");
   }

If you are behind a firewall, then you will have to add something
like the following, just before calling the C<run()> method:

   $robot->proxy(['ftp', 'http', 'wais', 'gopher'],
                 'http://firewall:8080/');

=head1 MODULE DEPENDENCIES

The Robot.pm module builds on a lot of existing Net, WWW and other
Perl modules.
Some of the modules are part of the core Perl distribution,
and the latest versions of all modules are available from
the Comprehensive Perl Archive Network (CPAN).
The modules used are:

=over

=item HTTP::Request

This module is used to construct HTTP requests, when retrieving the contents
of a URL, or using the HEAD request to see if a URL exists.

=item HTML::Parse

This module builds a tree data structure from the contents of an HTML page.
This is used to extract the URLs from the links on a page.
This is also used to check for page-specific Robot exclusion commands,
using the META element.

=item URI::URL

This module implements a class for URL objects,
providing resolution of relative URLs, and access to the different
components of a URL.

=item LWP::RobotUA

This is a wrapper around the LWP::UserAgent class.
A I<UserAgent> is used to connect to servers over the network,
and make requests.
The RobotUA module provides transparent compliance with the
I<Robot Exclusion Protocol>.

=item HTTP::Status

This has definitions for HTTP response codes,
so you can say RC_NOT_MODIFIED instead of 304.

=back

All of these modules are available as part of the libwww-perl5
distribution, which is also available from CPAN.

=head1 SEE ALSO

=over 4

=item The SAS Group Home Page

http://www.cre.canon.co.uk/sas.html

This is the home page of the Group at Canon Research Centre Europe
who are responsible for Robot.pm.

=item Robot Exclusion Protocol

http://info.webcrawler.com/mak/projects/robots/norobots.html

This is a I<de facto> standard which defines how a `well behaved'
Robot client should interact with web servers and web pages.

=item Guidelines for Robot Writers

http://info.webcrawler.com/mak/projects/robots/guidelines.html

Guidelines and suggestions for those who are (considering)
developing a web robot.

=item Weblint Home Page

http://www.cre.canon.co.uk/~neilb/weblint/

Weblint is a perl script which is used to check HTML for syntax
errors and stylistic problems,
in the same way B<lint> is used to check C.

=item Comprehensive Perl Archive Network (CPAN)

http://www.perl.com/perl/CPAN/

This is a well-organized collection of Perl resources,
such as modules, documents, and scripts.
CPAN is mirrored at FTP sites around the world.

=back

=head1 VERSION

This documentation describes version 0.011 of the Robot module.
The module requires at least version 5.002 of Perl.

=head1 AUTHOR

=over 4

=item Neil Bowers C<E<lt>neilb@cre.canon.co.ukE<gt>>

=back

SAS Group, Canon Research Centre Europe

=head1 COPYRIGHT

Copyright (C) 1997, Canon Research Centre Europe.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=cut


1;
