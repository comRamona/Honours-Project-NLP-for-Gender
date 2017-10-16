package Clair::GenericDoc;

=head1 NAME

 B<package> Clair::GenericDoc
 A class to standardize and create generic representation of documents.

=head1 AUTHOR

 JB Kim
 jbremnant@gmail.com
 20070407

=head1 SYNOPSIS

 This module is designed to take in any text-oriented document and parse
 it based on its MIME type. The parsing is made modular by the use of 
 sub-modules which will be dynamically loaded at runtime. 

 Furthermore, the document is converted into perl hash representation
 and can be dumped to disk in XML format.

 Once you instantiate the object, all you have to do is to invoke one
 subroutine to take parsing to effect:
  
  use Clair::GenericDoc;

  my $gdoc = new Clair::GenericDoc(content => "/path/to/your/file", stem => 1);
  my $hash = $gdoc->extract();

 This module is an alternate interface to Clair::Document. Whereas 
 Clair::Document focuses on extracting information out of documents, this
 interface focuses on parsing and its modularity.


=head1 DESCRIPTION

 The module will try to do the "smart thing" and determine the file type 
 for you. You can force feed the parsing sub-module:

  my $gdoc = new Clair::GenericDoc(
   content => "/path/to/your/file",
   stem => 1,
   use_parser_module => shakespear.pm,
  );

 Assuming that "shakespear.pm" exists under B<./GenericDoc> sub-directory.

 There are other features of this module which will be covered in the 
 method specifications.

=cut


# use FindBin;
# use lib "$FindBin::Bin/../lib/perl5/site_perl/5.8.5";
# use lib "$FindBin::Bin/lib/perl5/site_perl/5.8.5";

use strict;
use vars qw/$DEBUG/;

use Clair::Config;
use Clair::Debug;
use Clair::StringManip;
use Data::Dumper;
use File::Basename;
use File::Path;
use File::Type;
use XML::Simple;


=head2 new

 The constructor. Most of the internal flags are overriden.
 The significant ones are:
  
=over 4

=item cast - a boolean flag that will "cast" the object to Clair::Document object.

=item content - either path to a file, or the actual string.

=item module_root - specify the directory for the submodules.

=item xml_outputdir - specify the directory to dump the hash into xml file.

=item use_parser_module - hardcode the parser module, which bypasses auto file type detection.

=item stem - do stemming.

=item strip - strip meta characters.

=back  

=cut

sub new 
{
	my ($proto, %args) = @_;
	my $class = ref $proto || $proto;	

	my $self = bless {}, $class;
	$DEBUG = $args{DEBUG} || $ENV{MYDEBUG};
	
	# $self->{module_root} = (-d "$FindBin::Bin/../lib/Clair/GenericDoc") ? "$FindBin::Bin/../lib/Clair/GenericDoc" : "$FindBin::Bin/lib/Clair/GenericDoc";
	$self->{module_root} = "$Clair::Config::CLAIRLIB_HOME/lib/Clair/GenericDoc";
	$self->{xml_outputdir} = "$FindBin::Bin/.xmloutput";
	
	$self->{use_parser_module} = "";

	$self->{strip} = 1;
	$self->{lowercase} = 1;
	$self->{tokenize} = 1;
	$self->{stem} = 1;

	# use system's file command: defaults to false
	$self->{use_system_file_cmd} = 0;	

	$self->{cast} = 0;

	# overrides
	while ( my($k, $v) = each %args ) 
	{
		$self->{$k} = $v if(defined $v);
	}	

	unless(-d $self->{module_root})
	{
		$self->errmsg("the submodule directory for document parsing need to be properly specified",1);
	}

	# content is arbitrated between file and string, but the name of file is saved
	$self->{content_source} = "";
	unless($self->{content})
	{
		$self->errmsg("the 'content' constructor argument is required (either file or string)", 1);
	}

	# load up Clair::Document dynamically and just return that obj - this is one way street.
	if($self->{cast})
	{
		$self->debugmsg("instantiating Clair::Document object and returning that object", 1);
		return $self->newcast();
	}
	
	return $self;
}


=head2 newcast

 This function understands how to create Clair::Document from arguments passed in
 via this constructor.

=cut


sub newcast
{
	my ($self) = @_;

	eval { require "$Clair::Config::CLAIRLIB_HOME/lib/Clair/Document.pm"; };
	$self->errmsg("cannot load Clair::Document $@", 1) if($@);

	my $content_class = (-f $self->{content}) ? "file" : "string";
	my $document_type = $self->document_type($self->{content});

	# very loose and potentially buggy logic here - Clair::Document has hardcoded types it supports
	my $type = "text";
	$type = "html" if($document_type =~ /html/i);
	$type = "xml" if($document_type =~ /xml/i);

	my $clair_document_object = Clair::Document->new(
		$content_class => $self->{content},
		type => $type,
	);

	return $clair_document_object;
}


=head2 makestr

 If the supplied "content" is a file, it slurps in the content and converts it
 into a string. 

 TODO: make this portion more modular to operate on urls and other content types
       such as gzip-ed/tar-ed files.

=cut

sub makestr
{
	# used to register the document
	my ($self, $content) = @_;

	if(-f $content) 
	{
		$self->{content_source} = $content; # save the filename
		$self->debugmsg("converting $content to string", 2);
		open F, "< $content" or $self->errmsg("can't open: $!", 1);
		my @lines = <F>;
		close F;
		my $content_str = join "", @lines;
		return $content_str;
	}
	elsif(! ref $content && $content =~ /^http:/i)
	{
		# do url extraction here..
	}

	return $content;	
}


=head2 document_type

 Determines the mime content type from a file or a string, and
 returns the content type token. 

=cut

sub document_type 
{
	my ($self, $content) = @_;
	
	$self->debugmsg("determining the type of document", 3);

	my $type = "";
	if($self->{use_system_file_cmd} && -f $content)
	{
		my $str = `file -i $content`;
		chomp $str;
		my @a = split /\s+/, $str;
		$type = $a[1];
	}
	else
	{
		my $ft = File::Type->new();

		# $type = (-f $content) ?
			# $ft->checktype_filename($content) :
			# $ft->checktype_contents($content);
		$type = $ft->mime_type($content);
	}

	$self->debugmsg("document type is '$type'",2);

	return $type;
}


=head2 load_parser

 After the content/document type is determined, this subroutine tries
 to use the appropriate sub-module. Obviously, if the sub-module to handle
 the content is not available, this subroutine will exit gracefully after
 printing the reason via B<$self->errmsg()>.

=cut

sub load_parser
{
	my ($self, $content) = @_;

	# dtermine the content type first in order to load the appropriate module
	my $type = $self->document_type($content);

	# convert to string
	$self->{content} = $self->makestr($content || $self->{content});

	my ($modulename, $modpath) = $self->_determine_module($type);	

	if(exists $self->{loaded_modules}->{$modulename})
	{
		$self->debugmsg("module '$modpath' already loaded",2);
		return $self->{loaded_modules}->{$modulename}
	}
	# runtime loading hotness!
	$self->debugmsg("loading module '$modpath'",2);
		
	if(-f $modpath)
	{
		eval { require $modpath; };
	}
	else
	{
		eval { require $modulename; };
	}
	
	if($@)
	{
		$self->errmsg("couldn't load module $modpath: $@", 1);
	}
	$self->{loaded_modules}->{$modulename} = $modulename;
	return $self->{loaded_modules}->{$modulename};
}


=head2 _determine_module

 This subroutine takes the mime type string and tries to match up an
 appropriate sub-module in the $self->{module_root} directory. It does
 so by listing the available modules under that dir and then match 
 the substring of the $type parameter passed in against the name of 
 the sub-module. 

 When creating a parser sub-module, one should be conscious of the 
 name he/she picks for that module. In case $self->{use_parser_module}
 exists, it blindedly returns that module to be later loaded.

=cut

sub _determine_module
{
	my ($self, $type) = @_;

	my $modulename;
	my $modpath;
	if($self->{use_parser_module})
	{
		$modpath = "$self->{module_root}/$self->{use_parser_module}.pm";
		$modulename = $self->{use_parser_module};

		$self->errmsg("parser module: $modpath does't exist", 1) unless(-f $modpath);
	}
	else
	{
		opendir D, $self->{module_root};
		my @files = grep { ! /^\./ && -f "$self->{module_root}/$_" } readdir D;
		closedir D;
		chomp @files;
		my @names = map { s/\.pm//; $_; } @files;

		my @type_tok = split '/', $type;
		my $type_name = pop @type_tok;
		# my $type_name = $type;
		$type_name =~ s/-/_/g;
		$type_name =~ s/;//g;
		
		my $target_name = "";
		for my $n (@names)
		{
			$self->debugmsg("matching: $type_name ~ /$n/", 2);
			if($type_name =~ /$n/i)
			{
				$target_name = $n;
				last;
			}
		}
		$self->errmsg("can't find appropriate module for type: $type", 1) unless($target_name);

		$modpath = "$self->{module_root}/$target_name.pm";
		$modulename = $target_name;
	}
	return ($modulename, $modpath);
}


=head2 extract
 
 This is the wrapper for other crucial routines that determine the content type and 
 runtime loading of the necessary parser sub-module. Once the runtime loading of the
 sub-module is successful, it runs the functions called B<extract()> within it - overloading
 of the subroutine name. The parsing logic is entirely upon the B<extract()> subroutine
 within the loaded sub-module.

 The content returned should be a reference to an array containing hash items. Thus, each
 document/content provided in GenericDoc can manifest into multiple, subdivided documents.

 The returned content, then, will be stripped of metacharacters and stemmed, based on the
 constructor flags.

 Finally, the required hash keys within the returned data structure is:

=over 4

=item $hash->{parsed_content}

=item $hash->{title}

=item $hash->{path}

=back

 More on the convention used for sub-modules later.

=cut

sub extract
{
	my ($self, $content, $args) = @_;

	$content = $self->{content} unless($content);
	# after load_parser is ran, the $content should be registered in $self->{content}
	my $modulename = $self->load_parser($content);

	# returns arrays of hashs containing sections of docs that are divided up
	my $aref_hash = $modulename->extract($self->{content}, $self->{content_source}, $args, $self);	
	
	# string manipulation routines in this module.
	my $strmanip = new Clair::StringManip(DEBUG => $DEBUG);

	for my $hash (@$aref_hash)
	{
		$self->_validate_extracted_hash_content($hash);
		$hash->{parsed_content} = $strmanip->lowercase($hash->{parsed_content}) if($self->{lowercase});
		$hash->{parsed_content} = $strmanip->strip($hash->{parsed_content}) if($self->{strip});
		$hash->{parsed_content} = $strmanip->tokenize($hash->{parsed_content}) if($self->{tokenize});
		$hash->{parsed_content} = $strmanip->stem($hash->{parsed_content}, $args->{return_array}) if($self->{stem});
		# $hash->{parsed_content} = $strmanip->stem($hash->{parsed_content}) if($self->{stem});
			
	}

	return $aref_hash;
}


=head2 _validate_extracted_hash_content

 NOTE: unimplemented yet. Should take care of validating the data structure returned by
       the sub-module.

=cut

sub _validate_extracted_hash_content
{
	my ($self, $hash) = @_;


	return;
}


=head2 to_xml

 Takes a hash and converts it into xaml string.

=cut

sub to_xml
{
		my ($self, $hash) = @_;
	
    require XML::Simple;
    my $xs = new XML::Simple(XMLDecl => 1);

    # my $ref = $xs->XMLin([<xml file or string>] [, <options>]);
    my $xml = $xs->XMLout($hash);
		$self->debugmsg("XML output:\n\n$xml", 3);
		return $xml;
}

=head2 from_xml

 Takes an xml string or file and converts it back to a perl hash.

=cut

sub from_xml
{
		my ($self, $xml) = @_;
	
    require XML::Simple;
    my $xs = new XML::Simple;

    my $ref = $xs->XMLin($xml);
		$self->debugmsg($ref, 3);
		return $ref;
}


=head2 save_xml

 Simply dumps the xml string into a file. It makes sure that the subdirectory
 specified in $self->{xml_outputdir} is created before the file is written
 to disk.

=cut

sub save_xml
{
		my ($self, $xml, $filename) = @_;

		$self->errmsg("provide the xml str", 1) unless($xml);
		$self->errmsg("provide the filename", 1) unless($filename);

		my $dir = dirname($filename);
		$dir = $self->{xml_outputdir} unless($dir);
		mkpath($dir, 0, 0777) unless(-d $dir);

		# my $xml_file = "$self->{xml_outputdir}/$filename";
		open XF, "> $filename" or $self->errmsg("cannot open file for writing: $!", 1);
		print XF $xml;
		close XF;
	
}


=head2 morph

 Morph the existing object into Clair::Document object. This subroutine serves as
 both convenience and compatibility functions. This function works after you've
 instantiated the Clair::Genericdoc object and all the proper constructor parameters
 have been initialized. The extract() function is invoked to parse the content, and
 then subsequently the Clair::Document will be constructed with necessary fields
 pre-populated.

=cut

sub morph
{
	my ($self, $content) = @_;

	$self->{stem} = 1;
	$self->{lowercase} = 1;
	my $aref = $self->extract($content);		
	
	return undef unless scalar @$aref;

	eval { require "$Clair::Config::CLAIRLIB_HOME/lib/Clair/Document.pm"; };
	$self->errmsg("cannot load Clair::Document $@", 1) if($@);

	if(scalar @$aref == 1)
	{
		my $cd = $self->newcast();
		$cd->{stem} = $aref->[0]->{parsed_content};
		return $cd;
	}
	else # we return arrays of Clair::Document objects
	{
		my @return;
		for my $h (@$aref)
		{
			my $cd = $self->newcast();
			$cd->{stem} = $aref->[0]->{parsed_content};
			push @return, $cd;
		}
		return \@return;
	}
}



=head1 TODOS

=over

=item Make the subroutine B<makestr> more modular

Right now, it only does file to string conversion. It should auto-magically
do url-download to string conversion as well. 

=item Make the mime type determination a bit more robust

Sometimes mime-types don't come back as expected. Search for other ways to
determine the filetypes and the associated submodules more bullet proof.

=back

=cut

1;
