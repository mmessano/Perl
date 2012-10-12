#!c:/perl/bin -w
#
# dcom_list.pl
#

use strict;
use diagnostics;
use warnings;
use Win32::ODBC;
use Win32::OLE('in');
use Win32::OLE::Const 'Microsoft ActiveX Data Objects 2.5';
use IO::File;
use Switch;
use constant wbemFlagReturnImmediately => 0x10;
use constant wbemFlagForwardOnly => 0x20;

my ( $DSN, $objItem, $ErrNum, $ErrText, $ErrConn, $SQL, $OUTPUT, $failure_file, $args, $infile, @computers );

# Set the DSN name
$DSN = new Win32::ODBC("status") or die "Error: " . Win32::ODBC::Error();

$SQL= "exec sp_ins_dcom_assoc ";

$args = @ARGV;
if ( $args < 1 ) {
	$infile = "\\\\mensa\\Dexma\\Data\\ALL_Active.txt";
	open(DAT, $infile) || warn ("Could not open $infile for reading!");
	@computers = <DAT>;
}
else {
	@computers = $ARGV[0];
}


my $dexlog = Win32::OLE->new('Dexma.Dexlog') or warn "Cannot create DexLog object $!\n";
$dexlog->SetProperty('ModuleName','dcom_list');

# Truncate table
$dexlog->Msg("Truncating table t_dcom_assoc\n");
$DSN->Sql("truncate table t_dcom_assoc");

foreach my $computer (@computers) {
   chomp $computer;
   $dexlog->Msg("*** BEGIN $computer. ***\n");

   if (my $objWMIService = Win32::OLE->GetObject("winmgmts:\\\\$computer\\root\\CIMV2")) {

   my $dcomItems = $objWMIService->ExecQuery("SELECT * FROM Win32_DCOMApplicationSetting", "WQL", wbemFlagReturnImmediately | wbemFlagForwardOnly) or warn "WMI connection failed.\n";

	foreach $objItem (in $dcomItems) {

		if ( defined $objItem->{Caption} ) {
			#print "$objItem->{Caption}\n";
		if  ( $objItem->{Caption} =~ /Dex.*/ or $objItem->{Caption} =~ /CDO.*/ or $objItem->{Caption} =~ /Mapping.*/ or $objItem->{Caption} =~ /HNCService/ ) {
			if ($DSN->Sql($SQL . "'" . $objItem->{AppID}
							   . "'" . "," . "'" . $objItem->{Caption}
							   . "'" . "," . "'" . $objItem->{Description}
							   . "'" . "," . "'" . $computer
							   . "'" . "," . "'" . $objItem->{RemoteServerName}
							    . "'"))
							   {
									($ErrNum, $ErrText, $ErrConn) = $DSN->Error();
									$dexlog->Msg("SQL insert failed!\n");
									$dexlog->Msg("Name: $objItem->{Caption}\n");
									$dexlog->Msg("ErrorNum: $ErrNum\n");
									$dexlog->Msg("Text: $ErrText\n");
									$dexlog->Msg("SQL error: $ErrConn\n");
								}
#								print "\n";
			  	   				}
			  	   				}
			  	   				}
}
	else
	{
	$dexlog->Msg("WMI connection failed for $computer.\n");
	}
    $dexlog->Msg("*** END $computer. ***\n");
}
#}
