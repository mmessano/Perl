#!c:/perl/bin -w
#
# sql_protocols.pl
#

use strict;
use diagnostics;
use warnings;
use Win32::ODBC;
use Win32::OLE('in');
use Win32::Registry;
use Switch;
use IO::File;
use File::stat qw(:FIELDS);
use constant wbemFlagReturnImmediately => 0x10;
use constant wbemFlagForwardOnly => 0x20;

my ( $dexlog, $argcount, $DSN, $SQL_sel_servers, @dbservers );

$dexlog = Win32::OLE->new('Dexma.Dexlog') or warn "Cannot create DexLog object $!\n";
$dexlog->SetProperty('ModuleName','enum_SQLDrivers');

$DSN = new Win32::ODBC("Status") or die "Error: " . Win32::ODBC::Error();

# select servers to scan
$argcount = @ARGV;

if ( $argcount > 0 ) {
	$SQL_sel_servers = "SELECT distinct Server from SQLServerDetails where server = '" . $ARGV[0] . "' AND ProductVersion LIKE '9%' order by Server";
}
else {
	$SQL_sel_servers = "SELECT distinct Server from SQLServerDetails WHERE ProductVersion LIKE '9%' order by Server";
}

$DSN->Sql($SQL_sel_servers);

while ( $DSN->FetchRow() ) {
	push @dbservers, $DSN->Data;
}

# my @computers = ("psqlpa13");
foreach my $computer ( @dbservers ) {
   print "\n";
   print "==========================================\n";
   print "Computer: $computer\n";
   print "==========================================\n";

   my $objWMIService = Win32::OLE->GetObject("winmgmts:\\\\$computer\\root\\Microsoft\\SqlServer\\ComputerManagement") or warn "WMI connection failed.\n";
   my $colItems = $objWMIService->ExecQuery("SELECT * FROM ClientNetworkProtocol", "WQL",
                  wbemFlagReturnImmediately | wbemFlagForwardOnly);

   foreach my $objItem (in $colItems) {
      print "ProtocolDisplayName: $objItem->{ProtocolDisplayName}\n";
      print "ProtocolDLL: $objItem->{ProtocolDLL}\n";
      print "ProtocolName: $objItem->{ProtocolName}\n";
      print "ProtocolOrder: $objItem->{ProtocolOrder}\n";
      print "SupportAlias: $objItem->{SupportAlias}\n";
      print "\n";
   }
}