#!c:/perl/bin -w
#
# create_cpu_rrd.pl
#

use strict;
use diagnostics;
use warnings;
use Win32::OLE('in');


my ( $rrdtool_create, $dir, $ds, $ds_list, $name, $loadpercentage, $rra_list, $server, $Processors, $step, $infile, @server, $proc_num );

my $argcount = @ARGV;


if ( $argcount < 1 ) {
	$infile = "\\\\mensa\\Dexma\\Support\\Monitoring\\cpu\\serverlist.txt";
	open(DAT, $infile) || die("Could not open $infile for reading!");
	@server = <DAT>;
}
else {
	@server = @ARGV;
}


#$server = $ARGV[0];
$rrdtool_create = "C:\\Dexma\\support\\Monitoring\\rrdtool.exe create ";
$dir = "C:\\Dexma\\support\\Monitoring\\cpu\\";
$step = " --step 300 ";
$rra_list = " RRA:AVERAGE:0.5:1:600
		RRA:AVERAGE:0.5:6:700
		RRA:AVERAGE:0.5:24:775
		RRA:AVERAGE:0.5:288:797
		RRA:MAX:0.5:1:600
		RRA:MAX:0.5:6:700
		RRA:MAX:0.5:24:775
		RRA:MAX:0.5:288:797";


foreach $server ( @server ) {
	chomp $server;
	print "Server: " . $server . "\n";
	my $objWMIService = Win32::OLE->GetObject("winmgmts:\\\\$server\\root\\CIMV2") or die "WMI connection failed.\n";
	$Processors = $objWMIService->InstancesOf("Win32_Processor");
	$proc_num = 0;
	# build the Data Source list
	foreach my $cpu ( in $Processors ) {
			$ds =  " DS:LOADPERCENT_" . $cpu->{DeviceID}  . ":GAUGE:600:-1:100";
			$ds_list = $ds_list . $ds;
			$proc_num++;
			#$name = $server  . "_cpu.rrd ";
			}
	print "Processors: $proc_num\n";
	$name = $server ."_" . $proc_num  . "_cpu.rrd ";
	# write data to the rrd
	print "$rrdtool_create" . "$dir" . "$name" . "$step" . "$ds_list" . "$rra_list\n\n";
	system "$rrdtool_create" . "$dir" . "$name" . "$step" . "$ds_list" . "$rra_list";
	# reset variables
	$ds = "";
	$ds_list = "";
}

# load percentage rrd format, extended
#RRA:AVERAGE:0.5:1:600	1 sample every 5 minutes, 600 records stored(50 hours-2 days + 2 hours)
#RRA:AVERAGE:0.5:6:700	6 samples(30 minute average), 700 records stored(350 hours-14 days + 14 hours)
#RRA:AVERAGE:0.5:24:775	24 samples(2 hour average), 775 records stored(-64 days + 14 hours)
#RRA:AVERAGE:0.5:288:797	288 samples(24 hour average), 797 records stored(797 days)
$loadpercentage = "--step 300 DS:LOADPERCENT:GAUGE:600:-1:100
				 RRA:AVERAGE:0.5:1:600
				 RRA:AVERAGE:0.5:6:700
				 RRA:AVERAGE:0.5:24:775
				 RRA:AVERAGE:0.5:288:797
				 RRA:MAX:0.5:1:600
				 RRA:MAX:0.5:6:700
				 RRA:MAX:0.5:24:775
				 RRA:MAX:0.5:288:797";