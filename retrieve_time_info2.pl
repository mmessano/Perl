
use strict;
use diagnostics;
use warnings;
use Win32::OLE('in');
use IO::File;
use File::stat qw(:FIELDS);


my ( $name, $machine, @machines, $count );


my $infile = "\\\\oapputil10\\Dexma\\Data\\mjm_temp.txt";

open(DAT, $infile);
@machines = <DAT>;
close DAT;

#my $outfile = "c:\\dexma\\time_out.txt";
#open(OUT, ">>$outfile");

$count = 0;

foreach $machine (in @machines) {
	chomp $machine;
	print $machine . "\n";
	if ($count == '0') {
	   system("net time \\\\" . $machine . " > c:\\dexma\\time_out2.txt");
	}
	else {
		 system("net time \\\\" . $machine . " >> c:\\dexma\\time_out2.txt");
	}
	$count++;
}