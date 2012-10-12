#!/usr/bin/perl
#
# parsehttp.pl
#

use strict;
use warnings;
use Date::Parse;

my %hits;
while (<>) {
	print "Looping...\n";
	next unless m/(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})/;
	my $time = str2time($1);
	$hits{$time - ($time % 60)}++;
	#print STDERR "$1\n" if ($time % 1440 == 0) 
	print "$1\n"; #if ($time % 1440 == 0)

}

for my $i (sort { $a <=> $b } keys(%hits)) {
	print "rrdtool update webhits.rrd $i:$hits{$i}\n";
}