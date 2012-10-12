#!c:/perl/bin -w
#
# create_curr_connections_rrd.pl
#

use strict;
use diagnostics;
use warnings;
use Win32::OLE('in');

use constant wbemFlagReturnImmediately => 0x10;
use constant wbemFlagForwardOnly => 0x20;

#data		currentconn=http_currentconnections GAUGE:600:0:U



my ( @server, $rrdtool_create, $dir, $ds, $ds_list, $infile, $name, $rra_list, $server, $step, $TotalPhysMemMB, $TotalPhysMem, $VirMem, $MemSum );

my $argcount = @ARGV;


if ( $argcount < 1 ) {
	$infile = "\\\\mensa\\Dexma\\Data\\perfmon_WEB_serverlist.txt";
	open(DAT, $infile) || die("Could not open $infile for reading!");
	@server = <DAT>;
}
else {
	@server = @ARGV;	
}

$rrdtool_create = "C:\\Dexma\\support\\Monitoring\\rrdtool.exe create ";
$dir = "C:\\Dexma\\support\\Monitoring\\Connections\\";

#current connections rrd format
#day2-5-avg	AVERAGE:0.1:1:600
#week-5-avg	AVERAGE:0.1:6:336
#month-5-avg	AVERAGE:0.1:24:372
#3month-5-avg	AVERAGE:0.1:72:368
#year-5-avg	AVERAGE:0.1:288:365
#year3-5-avg	AVERAGE:0.1:288:1096
#year10-5-avg	AVERAGE:0.1:288:3652



# memory uasge rrd format
#RRA:AVERAGE:0.5:1:112   1 sample every 15 minutes, 112 records stored(28 hour history)
#RRA:AVERAGE:0.5:8:336   8 samples(2-hour average), 336 records stored(28 day history)
#RRA:AVERAGE:0.5:48:274  48 samples(12-hour average), 274 records stored(1.5 year history)
#RRA:AVERAGE:0.5:96:548 96 samples(24-hour average), 548 records stored(1.5 year history)

# run every 5 minutes
$step = " --step 300 ";
$rra_list = " DS:HTTPCurrConnections:GAUGE:600:0:U
			RRA:AVERAGE:0.1:1:600
			RRA:AVERAGE:0.1:6:336
			RRA:AVERAGE:0.1:24:372
			RRA:AVERAGE:0.1:72:368
			RRA:AVERAGE:0.1:288:365";



foreach $server ( @server ) {
chomp $server;
print "Server: " . $server . "\n";
$name = $server  . "_conn.rrd ";
# write data to the rrd
system "$rrdtool_create" . "$dir" . "$name" . "$step" . "$rra_list";
}