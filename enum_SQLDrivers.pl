#!c:/perl/bin -w
#
# enum_SQLDrivers.pl
#

use strict;
use diagnostics;
use warnings;
use Win32::ODBC;
use DBI;
use Win32::OLE::Const 'Microsoft ActiveX Data Objects 2.5';


my ( @drivers, $SQL_sel_servers, $dbh, $connection, $DSN, $DSN2, $dexlog, $name, $properties );

#$dsn = "Status";
#$connection = "DRIVER={SQL Server};ServerPort=OSQLUTIL12;TargetDSN=Status;LogonUser=user;LogonAuth=password;";
$DSN = new Win32::ODBC("Status") or die "Error: " . Win32::ODBC::Error();
#$dbh->connect("dbi:ODBC:$connection", "mmessano", "0Kumquat1") or die $DBI::errstr;


$dexlog = Win32::OLE->new('Dexma.Dexlog') or warn "Cannot create DexLog object $!\n";
$dexlog->SetProperty('ModuleName','enum_SQLDrivers');


# select servers to scan
my $argcount = @ARGV;

if ( $argcount > 0 ) {
	$SQL_sel_servers = "SELECT distinct Server from SQLServerDetails where server = '" . $ARGV[0] . "' order by Server";
}
else {
	$SQL_sel_servers = "SELECT distinct Server from SQLServerDetails order by Server";
}

#print $SQL_sel_servers;

$DSN->Sql($SQL_sel_servers);

while( $DSN->FetchRow() ) {
	my $server = $DSN->Data();
	print "Connecting to: " . $server . "\n";
	my $connection = "DRIVER={SQL Server};Server=" . $server . ";TargetDSN=master;LogonUser=user;LogonAuth=password;";
	$dbh = DBI->connect("dbi:ODBC:$connection") or die $DBI::errstr;
	#@drivers = DBI->available_drivers;
	#########################################
	#print $dsn;
	$DSN2 = new Win32::ODBC($connection) or die "Error: " . Win32::ODBC::Error();
	#push @drivers, $DSN2->Drivers();
	#print $DSN2->DataSources() . "\n";
	push @drivers, $DSN2->DataSources();
}

foreach my $driver ( @drivers ) {
	print $driver . "\n";
	if ( $driver =~ /(.*\n)(.*)/m ) {
		print $1 . "\n";
		print "\t" . $2 . "\n";
	}
}