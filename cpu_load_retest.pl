#!c:/perl/bin -w
#
# cpu_load_retest.pl
#

use strict;
use diagnostics;
use warnings;
use Win32::OLE('in');
use constant wbemFlagReturnImmediately => 0x10;
use constant wbemFlagForwardOnly => 0x20;

my ( @server, $server, $argcount, $dexlog, $infile, $sleep_time, $ulimit, @over, $objWMIService, $alertout );

$argcount = @ARGV;
$ulimit = 95;
$sleep_time = 2; # in seconds
$alertout ="e:\\dexma\\support\\monitoring\\cpu\\cpu_usage_alert.txt";
$infile = "e:\\Dexma\\support\\Monitoring\\cpu\\cpu_retest.txt";

if ( ( $argcount < 1 ) && ( -e $infile ) )
	{
		open(DAT, $infile) || warn("Could not open $infile for reading!");
		@server = <DAT>;
		print "File found.\n";
	}
else
	{
		print "No retestable servers found!\n";
		exit;
	}



$dexlog = Win32::OLE->new('Dexma.Dexlog') or warn "Cannot create DexLog object $!\n";
$dexlog->SetProperty('ModuleName','cpu_load_retest');


my $array_size = @server;

if ( $array_size > 0 ) {
	foreach $server ( @server ) {
		chomp $server;
	    $dexlog->Msg("Begin re-scan of " . $server . "...\n");
		$objWMIService = Win32::OLE->GetObject("winmgmts:\\\\$server\\root\\CIMV2") or die "WMI connection failed.\n";
		my $Processors = $objWMIService->InstancesOf("Win32_Processor");
		foreach my $lp_cpu ( in $Processors ) {
			if ($lp_cpu->{LoadPercentage} > $ulimit )  {
				print "First time $server $lp_cpu->{DeviceID}: $lp_cpu->{LoadPercentage} \n";
				push @over, $server;
			}
		}
	}
	sleep $sleep_time;
	my $size = @over;
	if ( $size > 0 ) {
		my %hash = map { $_ => 1 } @over;
		@over = sort keys %hash;
		foreach my $server2 ( @over ) {
			my $objWMIService2 = Win32::OLE->GetObject("winmgmts:\\\\$server2\\root\\CIMV2") or die "WMI connection failed.\n";
			my $Processors2 = $objWMIService2->InstancesOf("Win32_Processor");
			   foreach my $lp_cpu2 ( in $Processors2 ) {
               		if ( $lp_cpu2->{LoadPercentage} > $ulimit )  {
						$dexlog->Msg("CPU Utilization test failed for " . $server2 . ".  Email has been sent to Product Operations. \n");
						print "Second time $server2 $lp_cpu2->{DeviceID}: $lp_cpu2->{LoadPercentage}\n";
						open(OUTPUT, ">$alertout") or die "Couldn't open the $alertout file $!;\n aborting";
						print OUTPUT "$server2 has failed the CPU utilization test 3 times.  Please investigate CPU usage on $server2.\nUtilization is $lp_cpu2->{LoadPercentage}% for $lp_cpu2->{DeviceID} which is higher than $ulimit%.";
						close OUTPUT;
				   }
				}
				system ('e:\dexma\thirdparty\blat.exe ' . $alertout . ' -to productoperations@primealliancesolutions.com -s "' . $server2 . ' High CPU Utilization!"' or die "$!\n");
			}
	}
}