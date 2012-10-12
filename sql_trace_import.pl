#!c:/perl/bin -w
#
# sql_trace_import.pl
#

use strict;
use diagnostics;
use warnings;
use Date::EzDate;
use File::Copy;
use Win32::ODBC;
use Win32::OLE('in');

my ( $DSN, $server, @server, $dexlog, $dir, $file, $destdir, @trcdate, @trcpath );
my ( $days, $startdate, $startdate_format, $begintime, $endtime );

# suppress errors on connection failure(console only, error will be logged)
Win32::OLE->Option(Warn => 0);

########################  Defaults  ########################
# server list
@server = ('PSQLPA10','PSQLPA11','PSQLPA12','PSQLPA13','PSQLPA14');
# set previous number of days to import
$days = 1;
# create date object and set the format
$startdate = Date::EzDate->new() - $days;
# set DSN
$DSN = new Win32::ODBC("SQLTrace") or die "Error: " . Win32::ODBC::Error();
########################  Defaults  ########################


$dexlog = Win32::OLE->new('Dexma.Dexlog') or warn "Cannot create DexLog object $!\n";
$dexlog->SetProperty('ModuleName','SQL_Trace_Import');

for ( my $i = $days; $i >= 1; $i-- ) {	
	print "Using $startdate->{'%m/%d/%Y'} as the current date.\n";
	foreach $server ( @server ) {
		chomp $server;
		$dexlog->Msg("Found server: " . $server . "...\n");
		$destdir = "\\\\mensa\\dexma\\support\\SQLTraceFiles\\$server\\";
		$dir = "\\\\$server\\Dexma\\Support\\Trace";
		# cleanly skip over missing servers/files etc(no warnings to console)
		unless (opendir DIR, $dir) {
			$dexlog->Msg("*** $server - Can't open directory $dir: $! ***");
			next;
		}
		chdir "$dir";
		while ( $file= readdir DIR ) {
			if ( $file=~/DailyTrace.*$startdate->{'%Y%m%d'}.*/ ) {
				print $server . ":\t" . $file . "\n";
				unless ( copy($file,$destdir) ) {
					$dexlog->Msg("*** Creating $destdir... ***");
					mkdir($destdir);
					unless ( copy($file,$destdir) ) {
						$dexlog->Msg("*** Can't copy $file to $destdir: $! ***");
					}
				}
			my $path = $dir . "\\" . $file;
			#print "Path: $path\n\n";
			$DSN->Sql("exec dbm_GetTrace_1sec '$startdate->{'%m/%d/%Y'}', '" . $path . "'");
			$DSN->Sql("exec dbm_GetTopDuration '" . $path . "'");
			}
		}
	}
	$startdate++;
}