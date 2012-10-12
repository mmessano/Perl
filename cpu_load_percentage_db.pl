#!c:/perl/bin -w
#
# cpu_load_percentage.pl
#

use strict;
use diagnostics;
use warnings;
use Switch;
use Win32::OLE('in');
use constant wbemFlagReturnImmediately => 0x10;
use constant wbemFlagForwardOnly => 0x20;


my ( $server, @server, $rrdupdate, $dir, $name, $values, $infile, $outfile, $outfile2, $status, $dexlog, @over, $ulimit, $proc_num );

$ulimit = 65;

$rrdupdate = "E:\\Dexma\\support\\Monitoring\\rrdtool.exe update ";
$dir = "E:\\Dexma\\support\\Monitoring\\cpu\\";

# Trailing space is necessary!
# 	@server_name varchar(50), @cpu_num int, @load_percentage int
$SQL_ins = "exec sp_ins_sched_task ";

switch ($ARGV[0]) {
	case "PROD-4"		{ $infile = "\\\\mensa\\Dexma\\Data\\PROD_Monitoring_cpu_Quad.txt"; }
	case "PROD-2"		{ $infile = "\\\\mensa\\Dexma\\Data\\PROD_Monitoring_cpu_Dual.txt"; }
	case "PROD-1"		{ $infile = "\\\\mensa\\Dexma\\Data\\PROD_Monitoring_cpu_Single.txt"; }
	case "DEMO"			{ $infile = "\\\\mensa\\Dexma\\Data\\DEMO_Monitoring_cpu.txt"; }
	case "IMP" 			{ $infile = "\\\\mensa\\Dexma\\Data\\IMP_Monitoring_cpu.txt"; }
	case "QA" 			{ $infile = "\\\\mensa\\Dexma\\Data\\QA_Monitoring_cpu.txt"; }
	case "DEVT" 		{ $infile = "\\\\mensa\\Dexma\\Data\\DEVT_Monitoring_cpu.txt"; }
	case "FHHLC_Prod"	{ $infile = "\\\\mensa\\Dexma\\Data\\FHHLC_PROD_Monitoring_cpu.txt"; }
	case "Ops-Inf"		{ $infile = "\\\\mensa\\Dexma\\Data\\Ops-Inf_Monitoring_cpu.txt"; }
	case "PrePROD"		{ $infile = "\\\\mensa\\Dexma\\Data\\PreProd_monitoring_cpu.txt"; }
	case "DEAD"			{ $infile = "\\\\mensa\\Dexma\\Data\\Dead.txt"; }
}

open(DAT, $infile) || die("Could not open $infile for reading!");
@server = <DAT>;
close DAT;

#$outfile = "C:\\Dexma\\support\\Monitoring\\rrd\\cpu\\cpu_retest_" . $ARGV[0] . ".txt";
#$outfile2 = "E:\\Dexma\\support\\Monitoring\\cpu\\cpu_retest_" . $ARGV[0] . ".txt";
#$outfile = "E:\\Dexma\\support\\Monitoring\\cpu\\cpu_retest.txt";
#unlink $outfile;

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
				print "$lp_cpu->{LoadPercentage}% utilization exceeds limit of $ulimit% for $server $lp_cpu->{DeviceID}. \n";
				push @over, $server;
				
				if ($DSN->Sql($SQL_ins . "'" . $server . "'" . "," . "'" . $lp_cpu->{DeviceID} . "'" . "," . "'" . $lp_cpu->{LoadPercentage} . "'"))
					{
						($ErrNum, $ErrText, $ErrConn) = $DSN->Error();
						print  "Machine: $server\n";
						print  "SQL error: $ErrConn\n";
						print  "ErrorNum: $ErrNum\n";
						print  "Text: $ErrText\n\n";
					}

			}
	        $proc_num++;
		}
		$name = $server ."_" . $proc_num  . "_cpu.rrd ";
		#$dexlog->Msg("Updating the rrd file for " . $server . "...\n");
		#$dexlog->Msg("$rrdupdate" . "$dir" . "$name" . " N$values" . "\n\n");
		print "$dir" . "$name" . " N$values" . "\n";
		#system "$rrdupdate" . "$dir" . "$name" . "N$values";
		$values = "";
	}
	# log failures
	else {
		 $dexlog->Msg("WMI connection failed for $server.\n");
		 #print "WMI connection failed for $server.\n";
	}
}

#unlink $outfile;

#my $size = @over;

#if ( $size > 0 ) {
#	# sort array to remove duplicates
#	my %hash = map { $_ => 1 } @over;
#	@over = sort keys %hash;
#   # open output file
#	open(OUTPUT, ">>$outfile") or die "Couldn't open the $outfile file $!;\n aborting";
#	open(OUTPUT2, ">>$outfile2") or die "Couldn't open the $outfile2 file $!;\n aborting";
#	# print sorted array to output file for re-testing
#	foreach (@over) {
#	  #print "$_\n";
#	  print OUTPUT "$_\n";
#	  print OUTPUT2 "$_\n";
#	}
#	close OUTPUT;
#}
