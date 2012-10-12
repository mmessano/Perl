#!/bin/perl -w
#
# xml_reformat.pl


use strict;
use XML::Twig;

my ($file, $path, $twig);

my $dir = "C:\\Documents and Settings\\MMessano\\Desktop\\InProgress\\RFM_retired_listeners";
my $outdir = "C:\\Documents and Settings\\MMessano\\Desktop\\InProgress\\RFM_retired_listeners\formatted";


opendir DIR, $dir or die "Can't open directory $dir: $!\n";
my @files = (readdir DIR);

		foreach $file (@files) {
			unless ($file =~ /^\.+/ or $file =~ /vssver.scc/) {
				chdir $dir;
				$path = "$dir\\$file";
				print "Opening $path for parsing...\n";
				my $twig = new XML::Twig;
				$twig->parse($file);
				close $file;
			$twig->set_pretty_print( 'indented');
			$twig->print;
			}

		}

#my $infile = $ARGV[0];
#open(DAT, $infile) || die("Could not open $infile for reading!");
#my $string = <DAT>;


#my $twig = new XML::Twig;
#$t->parse( $string);


#print "indented:\n";               # nice + tags are indented
#$twig->set_pretty_print( 'indented');
#$twig->print;
#print "\n\n";
