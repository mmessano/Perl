use strict;
use diagnostics;
use warnings;
use Win32::OLE('in');

use constant wbemFlagReturnImmediately => 0x10;
use constant wbemFlagForwardOnly => 0x20;

my ( $server, @server, $rrdupdate, $dir, $name, $values, $infile, $status, $dexlog );

$rrdupdate = "E:\\Dexma\\support\\Monitoring\\rrdtool.exe update ";
$dir = "E:\\Dexma\\support\\Monitoring\\Connections\\";

$infile = "\\\\mensa\\Dexma\\Support\\Monitoring\\Connections\\serverlist.txt";

open(DAT, $infile) || die("Could not open $infile for reading!");
@server = <DAT>;
close DAT;


foreach $server ( @server ) {
	chomp $server;
    $dexlog = Win32::OLE->new('Dexma.Dexlog') or warn "Cannot create DexLog object $!\n";
	$dexlog->SetProperty('ModuleName','HTTPCurrentConnections');

	if (my $objWMIService = Win32::OLE->GetObject("winmgmts:\\\\$server\\root\\CIMV2")) {
		my $colItems = $objWMIService->ExecQuery("SELECT * FROM Win32_PerfRawData_W3SVC_WebService", "WQL", wbemFlagReturnImmediately | wbemFlagForwardOnly);
		
		foreach my $objItem (in $colItems) {
			if ( $objItem->{Name}  eq '_Total' )  {
				$values = $objItem->{CurrentConnections};
			}
		}
		$name = $server . "_conn.rrd ";
		$dexlog->Msg("Updating the rrd file for " . $server . "...\n");
		$dexlog->Msg("$rrdupdate" . "$name" . " N$values" . "\n\n");
		print "$dir" . "$name" . " N:$values" . "\n";
		system "$rrdupdate" . "$dir" . "$name" . "N:$values";
	}
	
	# log failures
	else 
	{
		 $dexlog->Msg("WMI connection failed for $server.\n");
		 #print "WMI connection failed for $server.\n";
	}
}