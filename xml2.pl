#!/usr/bin/perl -w

# File: xml2.pl
#
# Purpose: to have a small program that shows how to read in,
# display (to STDOUT) and write out an XML object
# using Perl's XML::Simple module (without using its
# defaults)
#
# (Instead of using Data::Dumper to print out the
# XML object, a home-made function called
# printOutReferencesRecursively() is used instead.
# This makes it a little easier to find the correct
# "path" to wanted information.)
#
# This script is not efficient. It's meant to be
# a tool to make it easier to understand how to
# read, manipulate, and write out XML files.

use strict;
use XML::Simple;

my $inFile = "C:\\Documents and Settings\\mmessano\\Desktop\\InProgress\\DexProcessController\\DexProcessControllerConfig.xml";
my $outFile = "C:\\Documents and Settings\\mmessano\Desktop\\InProgress\\DexProcessController\\DexProcessControllerConfig_out.xml";


sub printOutReferenceRecursively {
	my ($object, $string) = @_;

	my $ref = ref $object;

	if (not $ref) {
	   print "$string = $object\n";
	   }
	elsif ($ref eq "ARRAY") {
		my $i = 0; # counter
		foreach (@$object) {
			printOutReferenceRecursively($_, "$string\[$i]");
			$i++;
			}
		}
		elsif ($ref eq "HASH") {
			foreach (sort keys %$object) {
				printOutReferenceRecursively($object->{$_}, "$string\{$_}");
				}
			}
			else {
				print "$string = ???\n";
				}
			}


# The main code starts here:

my $xmlText;

# Extract the XML file's text (and put it in $xmlText):
{
local $/ = undef; # enable "slurp" mode
print STDERR "Reading file \"$inFile\"... ";
# Open the input file:
open(IN, "< $inFile") or die "Cannot read file \"$inFile\": $!\n";
# Read the data into $xmlText:
$xmlText = <IN>;
# Close the input file:
close(IN);
print STDERR "done.\n";
}

# Read the object from the text (the first
# parameter can also be the filename):
my $object = XMLin($xmlText, forcearray => 1,
keeproot => 1,
keyattr => []);

# use Data::Dumper;
# $Data::Dumper::Indent = 1; # use 1 for neater indenting
# print Dumper $object; # print out the XML object

# Print out the object here:
printOutReferenceRecursively($object, "\$object->");

# Convert $object to XML text using XMLout():
my $string = XMLout($object, keeproot => 1,
keyattr => []);

print STDERR "Writing to file \"$outFile\"... ";
# Open the output file:
open(OUT, "> $outFile") or die "Cannot write to file \"$outFile\": $!\n";
# Write the string to the output file:
print OUT $string;
# Close the output file:
close(OUT);
print STDERR "done.\n";

__END__

