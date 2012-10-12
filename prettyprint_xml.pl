#!/bin/perl -w

#########################################################################
#                                                                       #
#  This example prints a document using various pretty print options    #
#                                                                       #
#########################################################################
use strict;
use XML::Twig;

#my $string=
#'<doc><elt><subelt>text<inline>text</inline>text</subelt><subelt>text<inline><subinline/></inline></subelt></elt><elt att="val"><subelt>text<subinline/></subelt><subelt></subelt></elt></doc>';

my $infile = $ARGV[0];
open(DAT, $infile) || die("Could not open $infile for reading!");
my $string = <DAT>;


my $t= new XML::Twig;
$t->parse( $string);

#print "normal:\n";
#$t->set_pretty_print( 'none');     # this is the default
#$t->print;
#print "\n\n";

#print "nice:\n";
#$t->set_pretty_print( 'nice');     # \n before tags not part of mixed content
#$t->print;
#print "\n\n";

print "indented:\n";               # nice + tags are indented
$t->set_pretty_print( 'indented');
$t->print;
print "\n\n";
                                   # alternate way to set the style
#my $t2= new XML::Twig( PrettyPrint => 'nsgmls');
#$t->parse( $string);
#print "nice:\n";
#$t->print;
#print "\n\n";

