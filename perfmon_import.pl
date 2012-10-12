#!c:/perl/bin -w
#
# perfmon_import.pl
#

use strict;
use diagnostics;
use warnings;
use Date::EzDate;
use Win32::ODBC;
use Win32::OLE('in');

my ( $server, @server, $infile, $dexlog, $mydate, $mydate_format, $mydate_range_format, $mydate_range, $DSN, $dir );

$infile = "\\\\mensa\\dexma\\Data\\PROD_perfmon_serverlist.txt";

open(DAT, $infile) || die("Could not open $infile for reading!");
@server = <DAT>;
close DAT;

# suppress errors on connection failure(console only, error will be logged)
Win32::OLE->Option(Warn => 0);
$mydate = Date::EzDate->new('yesterday');
$mydate_format = "$mydate->{'%Y%m%d'}";
$mydate_range_format = "$mydate->{'%m/%d/%Y'}";
$mydate_range = " -b " . $mydate_range_format . " 11:00:00AM -e " . $mydate_range_format . " 3:00:00PM";

$DSN = new Win32::ODBC("PerfmonData") or die "Error: " . Win32::ODBC::Error();

foreach $server ( @server ) {
	chomp $server;
    $dexlog = Win32::OLE->new('Dexma.Dexlog') or warn "Cannot create DexLog object $!\n";
	$dexlog->SetProperty('ModuleName','Perfmon_Import');
	#$dexlog->Msg("Found server: " . $server . "...\n");
		$dir = "\\\\$server\\Dexma\\Support\\PerformanceMonitoring\\logs";
		opendir DIR, $dir or warn "\n$server - Can't open directory $dir: $!\n";
		chdir "$dir";
			while ( my $file= readdir DIR ) {
				if ( $file=~/.*$mydate_format.*/ ) {
					print $server . ":\t" . $file . "\n";
					$dexlog->Msg("relog.exe " . '"' . $file . '"' . " -f SQL -o SQL:PerfmonData!" . $server . "-" . $mydate_format . $mydate_range);
					system("relog.exe " . '"' . $file . '"' . " -f SQL -o SQL:PerfmonData!" . $server . "-" . $mydate_format . $mydate_range);
				}
			}
	$DSN->Sql("exec sp_perfmon_transform ")
}