#!c:/perl/bin -w
#
# cpu_load_percentage.pl
#

use strict;
use diagnostics;
use warnings;
use Switch;
use Win32::ODBC;
use Win32::OLE('in');
use constant wbemFlagReturnImmediately => 0x10;
use constant wbemFlagForwardOnly => 0x20;


my ( $server, @server, $rrdupdate, $dir, $name, $values, $infile, $status, $dexlog, @over, @over2, $ulimit, $sleep_time, $proc_num );
my ( $DSN, $ErrConn, $ErrNum, $ErrText, $SQL_ins );

$ulimit = 90;
$sleep_time = 10; # in seconds

$rrdupdate = "E:\\Dexma\\support\\Monitoring\\rrdtool.exe update ";
$dir = "E:\\Dexma\\support\\Monitoring\\cpu\\";

# Trailing space is necessary!
# 	@server_name varchar(50), @cpu_num varchar(50), @load_percentage int
$SQL_ins = "exec sp_ins_mon_cpu ";
$DSN = new Win32::ODBC("status") or die "Error: " . Win32::ODBC::Error();

switch ($ARGV[0]) {
	case "PROD-4"		{ $infile = "\\\\mensa\\Dexma\\Data\\PROD_Monitoring_cpu_Quad.txt"; }
	case "PROD-2"		{ $infile = "\\\\mensa\\Dexma\\Data\\PROD_Monitoring_cpu_Dual.txt"; }
	case "PROD-1"		{ $infile = "\\\\mensa\\Dexma\\Data\\PROD_Monitoring_cpu_Single.txt"; }
	case "DEMO"		{ $infile = "\\\\mensa\\Dexma\\Data\\DEMO_Monitoring_cpu.txt"; }
	case "IMP" 		{ $infile = "\\\\mensa\\Dexma\\Data\\IMP_Monitoring_cpu.txt"; }
	case "QA" 		{ $infile = "\\\\mensa\\Dexma\\Data\\QA_Monitoring_cpu.txt"; }
	case "DEVT" 		{ $infile = "\\\\mensa\\Dexma\\Data\\DEVT_Monitoring_cpu.txt"; }
	case "FHHLC_Prod"	{ $infile = "\\\\mensa\\Dexma\\Data\\FHHLC_PROD_Monitoring_cpu.txt"; }
	case "Ops-Inf"		{ $infile = "\\\\mensa\\Dexma\\Data\\Ops-Inf_Monitoring_cpu.txt"; }
	case "PrePROD"		{ $infile = "\\\\mensa\\Dexma\\Data\\PreProd_monitoring_cpu.txt"; }
	case "DEAD"		{ $infile = "\\\\mensa\\Dexma\\Data\\Dead.txt"; }
}

open(DAT, $infile) || die("Could not open $infile for reading!");
@server = <DAT>;
close DAT;


# suppress errors on connection failure(console only, error will be logged)
Win32::OLE->Option(Warn => 0);

foreach $server ( @server ) {
	chomp $server;
    $dexlog = Win32::OLE->new('Dexma.Dexlog') or warn "Cannot create DexLog object $!\n";
	$dexlog->SetProperty('ModuleName','cpu_load_percentage');

	if (my $objWMIService = Win32::OLE->GetObject("winmgmts:\\\\$server\\root\\CIMV2")) {
		my $Processors = $objWMIService->InstancesOf("Win32_Processor");
	    $proc_num = 0;

		foreach my $lp_cpu (in $Processors) {
			$values = $values . ":$lp_cpu->{LoadPercentage}";
			if ($lp_cpu->{LoadPercentage} > $ulimit )  {
				$dexlog->Msg("$lp_cpu->{LoadPercentage}% utilization exceeds limit of $ulimit% for $server $lp_cpu->{DeviceID}. \n");
				$dexlog->Msg("Logging error to Status DB. \n");
				print "\t$lp_cpu->{LoadPercentage}% utilization exceeds limit of $ulimit% for $server $lp_cpu->{DeviceID}. \n";
				push @over, $server;
				
				if ($DSN->Sql($SQL_ins . "'" . $server . "'" . "," . "'" . $lp_cpu->{DeviceID} . "'" . "," . "'" . $lp_cpu->{LoadPercentage} . "'"))
					{
						($ErrNum, $ErrText, $ErrConn) = $DSN->Error();
						print  "Machine: $server\n";
						$dexlog->Msg("Machine: $server\n");
						print  "SQL error: $ErrConn\n";
						$dexlog->Msg("SQL error: $ErrConn\n");
						print  "ErrorNum: $ErrNum\n";
						$dexlog->Msg("ErrorNum: $ErrNum\n");
						print  "Text: $ErrText\n\n";
						$dexlog->Msg("Text: $ErrText\n\n");
					}
			}
	        $proc_num++;
		}
		$name = $server ."_" . $proc_num  . "_cpu.rrd ";
		$dexlog->Msg("Updating the rrd file for " . $server . "...\n");
		$dexlog->Msg("$rrdupdate" . "$dir" . "$name" . " N$values" . "\n\n");
		#print "$dir" . "$name" . " N$values" . "\n";
		system "$rrdupdate" . "$dir" . "$name" . "N$values";
		$values = "";
	}
	
	# log failures
	else 
	{
		 $dexlog->Msg("**** WMI connection failed for $server. ****\n");
		 #print "WMI connection failed for $server.\n";
	}
}
my $size = @over;

if ( $size > 0 ) {
	# sort array to remove duplicates
	my %hash = map { $_ => 1 } @over;
	@over = sort keys %hash;

	print "Sleeping for $sleep_time seconds.\n";
	sleep $sleep_time;

	print "Begin re-testing servers.\n";
    foreach my $server2 ( @over ) {
		chomp $server2;
	    $dexlog->Msg("Begin re-scan of " . $server2 . "...\n");
		my $objWMIService = Win32::OLE->GetObject("winmgmts:\\\\$server2\\root\\CIMV2") or die "WMI connection failed.\n";
		my $Processors = $objWMIService->InstancesOf("Win32_Processor");
		foreach my $lp_cpu ( in $Processors ) {
			if ($lp_cpu->{LoadPercentage} > $ulimit )  {
				print "First re-test of $server2 $lp_cpu->{DeviceID}: $lp_cpu->{LoadPercentage} \n";
				push @over2, $server2;
				if ($DSN->Sql($SQL_ins . "'" . $server2 . "'" . "," . "'" . $lp_cpu->{DeviceID} . "'" . "," . "'" . $lp_cpu->{LoadPercentage} . "'")) {
						($ErrNum, $ErrText, $ErrConn) = $DSN->Error();
						print  "Machine: $server2\n";
						$dexlog->Msg("Machine: $server2\n");
						print  "SQL error: $ErrConn\n";
						$dexlog->Msg("SQL error: $ErrConn\n");
						print  "ErrorNum: $ErrNum\n";
						$dexlog->Msg("ErrorNum: $ErrNum\n");
						print  "Text: $ErrText\n\n";
						$dexlog->Msg("Text: $ErrText\n\n");
				}
			}
		}
	}
	print "Sleeping for $sleep_time seconds.\n";
	sleep $sleep_time;
	my $size2 = @over2;
	if ( $size2 > 0 ) {
		# sort array to remove duplicates
		my %hash = map { $_ => 1 } @over;
		@over = sort keys %hash;
	    foreach my $server3 ( @over2 ) {
			chomp $server3;
	    	$dexlog->Msg("Begin re-scan of " . $server3 . "...\n");
			my $objWMIService = Win32::OLE->GetObject("winmgmts:\\\\$server3\\root\\CIMV2") or die "WMI connection failed.\n";
			my $Processors = $objWMIService->InstancesOf("Win32_Processor");
			foreach my $lp_cpu ( in $Processors ) {
				if ($lp_cpu->{LoadPercentage} > $ulimit )  {
					print "Second re-test of $server3 $lp_cpu->{DeviceID}: $lp_cpu->{LoadPercentage} \n";
					if ($DSN->Sql($SQL_ins . "'" . $server3 . "'" . "," . "'" . $lp_cpu->{DeviceID} . "'" . "," . "'" . $lp_cpu->{LoadPercentage} . "'"))
						{
							($ErrNum, $ErrText, $ErrConn) = $DSN->Error();
							print  "Machine: $server3\n";
							$dexlog->Msg("Machine: $server3\n");
							print  "SQL error: $ErrConn\n";
							$dexlog->Msg("SQL error: $ErrConn\n");
							print  "ErrorNum: $ErrNum\n";
							$dexlog->Msg("ErrorNum: $ErrNum\n");
							print  "Text: $ErrText\n\n";
							$dexlog->Msg("Text: $ErrText\n\n");
						}
				}
			}
		}
	}
}
