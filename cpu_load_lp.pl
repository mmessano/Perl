#!c:/perl/bin -w
#
# cpu_load_lp.pl
#



use strict;
use diagnostics;
use warnings;
use Win32::OLE('in');


use constant wbemFlagReturnImmediately => 0x10;
use constant wbemFlagForwardOnly => 0x20;

my ($server, $rrdupdate, $dir, $name, $values);

$server = $ARGV[0];
$rrdupdate = "C:\\Dexma\\support\\Monitoring\\rrdtool.exe update ";
$dir = "C:\\Dexma\\support\\Monitoring\\rrd\\cpu\\";
$name = $server . "_lp.rrd ";


my $objWMIService = Win32::OLE->GetObject("winmgmts:\\\\$server\\root\\CIMV2") or die "WMI connection failed.\n";
my $Processors = $objWMIService->InstancesOf("Win32_Processor");

foreach my $lp_cpu (in $Processors) {
          $values = $values . ":$lp_cpu->{LoadPercentage}";
		  #system "$rrdupdate" . "$dir" . "$name" . " --template LOADPERCENT_" . $lp_cpu->{DeviceID} . " N:$lp_cpu->{LoadPercentage}";
}
print "$rrdupdate" . "$dir" . "$name" . " N$values" . "\n";
system "$rrdupdate" . "$dir" . "$name" . "N$values";