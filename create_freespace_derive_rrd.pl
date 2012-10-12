#!c:/perl/bin -w
#
# create_freespace_derive_rrd.pl
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
	$infile = "\\\\mensa\\Dexma\\Data\\Diskspace_Monitoring.txt";
	open(DAT, $infile) || die("Could not open $infile for reading!");
	@server = <DAT>;
}
else {
	@server = @ARGV;	
}

$rrdtool_create = "C:\\Dexma\\support\\Monitoring\\rrdtool.exe create ";
$dir = "C:\\Dexma\\support\\Monitoring\\Diskspace_Derive\\";


# memory uasge rrd format
#RRA:AVERAGE:0.5:1:96   1 sample every 15 minutes, 96 records stored(24 hour history)
#RRA:AVERAGE:0.5:8:336   8 samples(2-hour average), 336 records stored(28 day history)
#RRA:AVERAGE:0.5:48:274  48 samples(12-hour average), 274 records stored(1.5 year history)
#RRA:AVERAGE:0.5:96:548 96 samples(24-hour average), 548 records stored(1.5 year history)

# run every 12 hours
$step = " --step 900 ";
$rra_list = " DS:C:DERIVE:1800:0:U
			DS:E:DERIVE:1800:0:U
			DS:F:DERIVE:1800:0:U
			DS:G:DERIVE:1800:0:U
			RRA:AVERAGE:0.5:1:96
			RRA:AVERAGE:0.5:8:336
			RRA:AVERAGE:0.5:48:274
			RRA:AVERAGE:0.5:96:548
			";

foreach $server ( @server ) {
chomp $server;
print "Server: " . $server . "\n";
$name = $server  . "_derive_diskspace.rrd ";
# write data to the rrd
system "$rrdtool_create" . "$dir" . "$name" . "$step" . "$rra_list";
}