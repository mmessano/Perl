#!c:/perl/bin -w
#
# create_memory_rrd.pl
#

use strict;
use diagnostics;
use warnings;
use Win32::OLE('in');

use constant wbemFlagReturnImmediately => 0x10;
use constant wbemFlagForwardOnly => 0x20;

my ( @server, $rrdtool_create, $dir, $ds, $ds_list, $infile, $name, $rra_list, $server, $step, $TotalPhysMemMB, $TotalPhysMem, $VirMem, $MemSum );

my $argcount = @ARGV;


if ( $argcount < 1 ) {
	$infile = "\\\\mensa\\Dexma\\Support\\Monitoring\\Memory\\serverlist.txt";
	open(DAT, $infile) || die("Could not open $infile for reading!");
	@server = <DAT>;
}
else {
	@server = @ARGV;	
}

$rrdtool_create = "C:\\Dexma\\support\\Monitoring\\rrdtool.exe create ";
$dir = "C:\\Dexma\\support\\Monitoring\\memory\\";


# memory uasge rrd format
#RRA:AVERAGE:0.5:1:112   1 sample every 15 minutes, 112 records stored(28 hour history)
#RRA:AVERAGE:0.5:8:336   8 samples(2-hour average), 336 records stored(28 day history)
#RRA:AVERAGE:0.5:48:274  48 samples(12-hour average), 274 records stored(1.5 year history)
#RRA:AVERAGE:0.5:96:548 96 samples(24-hour average), 548 records stored(1.5 year history)

# run every 15 minutes
$step = " --step 900 ";
$rra_list = " DS:Physical:GAUGE:1800:0:U
			DS:Virtual:GAUGE:1800:0:U
			RRA:AVERAGE:0.5:1:112
			RRA:AVERAGE:0.5:8:336
			RRA:AVERAGE:0.5:48:274
			RRA:AVERAGE:0.5:96:548";



foreach $server ( @server ) {
chomp $server;
print "Server: " . $server . "\n";
$name = $server  . "_mem.rrd ";
# write data to the rrd
system "$rrdtool_create" . "$dir" . "$name" . "$step" . "$rra_list";
}