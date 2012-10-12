#!c:/perl/bin -w
#
# perfmon_import_range.pl
#

use strict;
use diagnostics;
use warnings;
use Date::EzDate;
use Win32::ODBC;
use Win32::OLE('in');

my ( $server, @server, $infile, $dexlog, $DSN, $dir );
my ( $days, $startdate, $startdate_format, $begintime, $endtime, $relog_range_opts );

# suppress errors on connection failure(console only, error will be logged)
Win32::OLE->Option(Warn => 0);

########################  Defaults  ########################
$infile = "\\\\mensa\\dexma\\Data\\PROD_perfmon_serverlist.txt";
# set previous number of days to import
$days = 1;
# create start date
$startdate = Date::EzDate->new() - $days;
$begintime = '11:00:00AM';
$endtime = '3:00:00PM';
# set DSN
$DSN = new Win32::ODBC("PerfmonData") or die "Error: " . Win32::ODBC::Error();
########################  Defaults  ########################


open(DAT, $infile) || die("Could not open $infile for reading!");
@server = <DAT>;
close DAT;

$dexlog = Win32::OLE->new('Dexma.Dexlog') or warn "Cannot create DexLog object $!\n";
$dexlog->SetProperty('ModuleName','perf_import_range');

for ( my $i = $days; $i >= 1; $i-- ) {
	$relog_range_opts = " -b " . $startdate->{'%m/%d/%Y'} . " " . $begintime . " -e " . $startdate->{'%m/%d/%Y'} . " " . $endtime;
	foreach $server ( @server ) {
		chomp $server;
		$dir = "\\\\$server\\Dexma\\Support\\PerformanceMonitoring\\logs";
		# cleanly skip over missing servers/files etc(no warnings to console)
		unless (opendir DIR, $dir) {
			$dexlog->Msg("*** $server - Can't open directory $dir: $! ***");
			next;
		}
		chdir "$dir";
		while ( my $file = readdir DIR ) {
			if ( $file=~/.*$startdate->{'%Y%m%d'}.*/ ) {
				print "Importing " . $server . " " . $file . "\tStartDate is: " . $startdate->{'%Y%m%d'} . "\n";
				#print "\tRelog option: " . $relog_range_opts . "\n";
				$dexlog->Msg("relog.exe " . '"' . $file . '"' . " -f SQL -o SQL:PerfmonData!" . $server . "-" . $startdate->{'%Y%m%d'} . $relog_range_opts);
				system("relog.exe " . '"' . $file . '"' . " -f SQL -o SQL:PerfmonData!" . $server . "-" . $startdate->{'%Y%m%d'}  . $relog_range_opts);
			}
		}
		#print "Moving data to permanent tables.\n";
		$dexlog->Msg("Moving data to permanent tables.");
		$DSN->Sql("exec PerfmonTransform ");
		#print "Data moved.\n";
		#print "Starting average aggregation...\n";
		$dexlog->Msg("Populating Daily Averages.");
		$DSN->Sql("exec upd_PerfmonAverages ");
		#print "Averages computed.\n";
	}
	$startdate++;
}
