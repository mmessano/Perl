#!c:/perl/bin -w
#
# insert_cpucount.pl
#

use strict;
use diagnostics;
use warnings;
use Win32::NetAdmin;
use Win32::ODBC;
use Win32::OLE('in');

my ( @servers, $server, $Processors, $proc_num, $SQL_ins, $infile, @infiles );
my ( $DSN, $ErrNum, $ErrText, $ErrConn, %SQL_Errors );


$DSN = new Win32::ODBC("status") or die "Error: " . Win32::ODBC::Error();

#$SQL_ins = "exec sp_ins_server_properties ";
@infiles = ("\\\\mensa\\Dexma\\Data\\Ops-Inf_Monitoring_cpu.txt",
			"\\\\mensa\\Dexma\\Data\\PreProd_monitoring_cpu.txt",
			"\\\\mensa\\Dexma\\Data\\DEMO_Monitoring_cpu.txt",
			"\\\\mensa\\Dexma\\Data\\DEVT_Monitoring_cpu.txt",
			"\\\\mensa\\Dexma\\Data\\IMP_Monitoring_cpu.txt",
			"\\\\mensa\\Dexma\\Data\\PROD_Monitoring_cpu.txt",
			"\\\\mensa\\Dexma\\Data\\QA_Monitoring_cpu.txt");

foreach $infile ( @infiles ) {
		print "File: $infile\n";



open(DAT, $infile) || die("Could not open $infile for reading!");
@servers = <DAT>;
close DAT;

foreach $server ( @servers ) {
	chomp $server;
	print "Server: " . $server . "\n";
	my $objWMIService = Win32::OLE->GetObject("winmgmts:\\\\$server\\root\\CIMV2") or die "WMI connection failed.\n";
	$Processors = $objWMIService->InstancesOf("Win32_Processor");
	$proc_num = 0;
   	foreach my $cpu ( in $Processors ) {
		$proc_num++;
		}
	if ($DSN->Sql("exec sp_ins_server_properties $server, $proc_num"))
		{
		($ErrNum, $ErrText, $ErrConn) = $DSN->Error();
		print  "Machine: $server\n";
		print  "SQL error: $ErrConn\n";
		print  "ErrorNum: $ErrNum\n";
		print  "Text: $ErrText\n\n";
		}


	print "Processors: $proc_num\n";

}
}
