#!c:/perl/bin -w
#
# create_freespace_rrd.pl
#

use strict;
use diagnostics;
use warnings;
use Win32::OLE('in');

use constant wbemFlagReturnImmediately => 0x10;
use constant wbemFlagForwardOnly => 0x20;

my ( @server, $rrdtool_create, $dir, $ds, $ds_list, $infile, $name, $rra_list, $server, $step );

my $argcount = @ARGV;


if ( $argcount < 1 ) {
	$infile = "\\\\mensa\\Dexma\\Support\\Monitoring\\Diskspace\\serverlist.txt";
	open(DAT, $infile) || die("Could not open $infile for reading!");
	@server = <DAT>;
}
else {
	@server = @ARGV;	
}

$rrdtool_create = "C:\\Dexma\\support\\Monitoring\\rrdtool.exe create ";
$dir = "C:\\Dexma\\support\\Monitoring\\Diskspace\\";


# diskspace rrd format
# 1st average happens every time with 56 samples for 28 day history
# 2nd average happens every 2 samples(24 hours) for 56 day history
# 3rd average happens every 14 samples(7 days) for 6 month history
# 4th average happens every 56 samples(1 month) for 1.5 year history

# run every 12 hours
$step = " --step 43200 ";
$rra_list = " DS:C:GAUGE:43200:0:100
			DS:E:GAUGE:43200:0:100
			DS:F:GAUGE:43200:0:100
			DS:G:GAUGE:43200:0:100
			RRA:AVERAGE:0.5:1:56
			RRA:AVERAGE:0.5:2:56
			RRA:AVERAGE:0.5:14:26
			RRA:AVERAGE:0.5:56:18
			RRA:MAX:0.5:1:56
			RRA:MAX:0.5:8:56
			RRA:MAX:0.5:24:26
			RRA:MAX:0.5:56:18";

foreach $server ( @server ) {
chomp $server;
print "Server: " . $server . "\n";
$name = $server  . "_diskspace.rrd ";
# write data to the rrd
system "$rrdtool_create" . "$dir" . "$name" . "$step" . "$rra_list";
}