#! /perl/bin/perl.exe
#
# $Id: prettysgml.pl,v 1.7 1999/04/09 12:59:08 tkg Exp $
#
# Perl script to pretty-print an SGML instance.
#
# Requires Earl Hood's perlSGML package to parse the DTD and David
# Megginson's sgmlspm package to do the right thing for the tags
# in the instance.

############################################################
# Requires

# Earl Hood's perlSGML function library
# Change this path if "dtd.pl" is at a different place on your system.
require $ENV{'TAGLIBBASE'} . '\lib\dtd.pl';

############################################################
# Uses (Perl5 improvement on 'require')
use SGMLS;
use SGMLS::Output;

############################################################
# Constants
#
# Usage statement
$cUsage = <<"EndOfUsage";
Usage:
perl $0 [-xml] TagLib.sgm

where:
 -xml          = Enable XML-specific behavior
  TagLib.sgm   = Tag Library SGML file
EndOfUsage

# Our own, non-reference-concrete-syntax, SGML declaration
$cSGMLDeclaration = $ENV{'TAGLIBBASE'} . '/lib/taglib.dec';

############################################################
# Process command line

while (@ARGV) {
    if ($ARGV[0] =~ /^-/) {
	if ($ARGV[0] =~ /^-xml$/) {
	    $gXML = shift;
	} else {
	    print STDERR $cUsage;
	    die "\nUnknown option:$ARGV[0]:\n";
	}
    } else {
	last;
    }
}

if (!@ARGV) {
    die $cUsage;
}

# Set XML-specific behavior, if required
if ($gXML) {
    &DTDset_xml($gXML);
}

############################################################
# Parse the tag library file
#

# Whatever remains, however improbable, must be the instance

$gTagLibFile = shift;

open(TAGLIB, "$gTagLibFile") ||
    die "Couldn't open Tag Library file \"$gTagLibFile\".\n";

# Read catalog files from SGML_CATALOG_FILES environment variable
&DTDread_catalog_files();

# Read the Tag Library DTD
&DTDread_dtd("main'TAGLIB") ||
    die "perlSGML library couldn't read Tag Library DTD.\n";

close(TAGLIB);

# Reopen the tag library to get the document type declaration
open(TAGLIB, "$gTagLibFile") ||
    die "Couldn't open Tag Library file \"$gTagLibFile\".\n";

while(<TAGLIB>) {
    last if /^<[^!]/;

    print $_;
    $gDocumentTypeDeclaration .= $_;
}

close(TAGLIB);

############################################################
# perlSGML processing to define what to do when the sgmlspl part
# works on the tags

# Get our list of elements courtesy of perlSGML
@gElements = &DTDget_elements(0);

foreach $lElement (@gElements) {
    local($lContentModel) = join(":", &DTDget_base_children($lElement, 0));
    local(%lAttributes) = &DTDget_elem_attr($lElement);

    $lElement =~ tr/a-z/A-Z/;

    if ($lContentModel =~ /#PCDATA/i ||
	$lContentModel =~ /^CDATA$/i ||
	$lContentModel =~ /^RCDATA$/i) {
	$gContentType{$lElement} = 'mixed';
    } elsif ($lContentModel =~ /^EMPTY$/i) {
	$gContentType{$lElement} = 'empty';
    } else {
	$gContentType{$lElement} = 'element';
    }

#    print STDERR ":$lElement:$gContentType{$lElement}:$lContentModel:\n";
}

############################################################

sgml('end_subdoc', '');		# Ignore the ends of subdocument entities.

sgml('re', sub {
    output "\n";
});

sgml('pi', sub {
    my $lProcessingInstruction = shift;

    output "<?$lProcessingInstruction>";
});

#sgml('sdata', sub {
#    my $lSDATA = shift;
#
#    output $lSDATA;
#});

sgml('start_element', sub {
    my $lElement = shift;
    my $lParent = $lElement->parent;
    my $lParentName = $lElement->parent->name if $lParent ne '';

    if ($lParent ne '' && $gContentType{$lParentName} eq 'element') {
	output "\n";
    }

    output "<" . $lElement->name;

    foreach $lAttribute ($lElement->attribute_names) {
	local($lAttributeValue) = $lElement->attribute($lAttribute)->value;

	if (!$lElement->attribute($lAttribute)->is_implied) {
	    if ($lElement->attribute($lAttribute)->type eq 'NOTATION') {
		output " $lAttribute=\"" .
		    $lElement->attribute($lAttribute)->value->name . "\"";
	    } elsif ($lElement->attribute($lAttribute)->type eq 'ENTITY') {
		output " $lAttribute=\"" .
		    $lElement->attribute($lAttribute)->value->name . "\"";
	    } else {
		output " $lAttribute=\"$lAttributeValue\"";
	    }
	}
    }

    output ">";
});

sgml('end_element', sub {
    my $lElement = shift;

    if ($gContentType{$lElement->name} eq 'element') {
	output "\n";
    }
    if ($gContentType{$lElement->name} ne 'empty') {
	output "</" . $lElement->name . ">";
    }
});


########################################################################
# SDATA Handler -- Output the entity that we started with
########################################################################

sgml('sdata', sub {
    my $lSDATA = shift;

    $lSDATA =~ s/\[/\&/;
    $lSDATA =~ s/\s*\]/;/;

    output $lSDATA;
});
