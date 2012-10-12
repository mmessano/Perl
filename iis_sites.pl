#!c:/perl/bin -w
#
# iis_sites.pl
#

use strict;
use diagnostics;
use warnings;
use Switch;
use Win32::ODBC;
use Win32::OLE::Const 'Microsoft ActiveX Data Objects 2.5';

my ( @server, $infile, $dexlog, $machine, @machines, $line, $server, $DSN, $SQL_ins, $SQL_ins_website, $ErrNum, $ErrText, $ErrConn );
my ( $ip, $port, $host, $sip, $sport, $shost, $state );
my ( $conn2 );

$DSN = new Win32::ODBC("status") or die "Error: " . Win32::ODBC::Error();

$dexlog = Win32::OLE->new('Dexma.Dexlog') or warn "Cannot create DexLog object $!\n";
$dexlog->SetProperty('ModuleName','domain_scanner');

# Trailing space is necessary!
#  @server_id, @website_id, @comment, @status, @ip_address, @port, @host_header, @secure_ip_address, @secure_port, @secure_host_header
$SQL_ins_website = "exec sp_ins_website ";


switch ($ARGV[0]) {
	case "PROD"		{ $infile = "\\\\mensa\\Dexma\\Data\\PROD_IISSites.txt"; }
	case "DEMO"		{ $infile = "\\\\mensa\\Dexma\\Data\\DEMO_IISSites.txt"; }
	case "IMP" 		{ $infile = "\\\\mensa\\Dexma\\Data\\IMP_IISSites.txt"; }
	case "QA" 		{ $infile = "\\\\mensa\\Dexma\\Data\\QA_IISSites.txt"; }
	case "DEVT" 		{ $infile = "\\\\mensa\\Dexma\\Data\\DEVT_IISSites.txt"; }
	case "Ops-Inf"		{ $infile = "\\\\mensa\\Dexma\\Data\\Ops-Inf_IISSites.txt"; }
	case "PrePROD"		{ $infile = "\\\\mensa\\Dexma\\Data\\PreProd_IISSites.txt"; }
	case "DEAD"		{ $infile = "\\\\mensa\\Dexma\\Data\\Dead.txt"; }
}

open(DAT, $infile) || die("Could not open $infile for reading!");
@server = <DAT>;
close DAT;

# suppress errors on connection failure
Win32::OLE->Option(Warn => 0);

foreach $server (@server) {
	chomp($server);
        &enum_sites($server);
}


# begin sub definitions
# enumerate web and ftp sites
sub enum_sites {
	my ( $webserver ) = @_;
	my @services = ('W3SVC', 'MSFTPSVC');
	foreach my $service ( @services ) {
		if ( my $conn = Win32::OLE->GetObject("IIS://$webserver/$service") ) {
			print "Enumerating IIS Sites on $webserver...\n";
			$dexlog->Msg("Enumerating IIS Sites on $webserver...\n");
			$dexlog->Msg("Cleaning t_websites for $webserver.\n");
			$DSN->Sql("DELETE FROM t_websites where server_id = (SELECT server_id FROM t_server WHERE server_name = '$webserver')");
			foreach my $site ( in $conn ) {
				if ( $site->Class eq "IIsWebServer" ) {
					#print "Starting W3SVC enumeration on $webserver.\n";
					( $ip, $port, $host ) = split(":", $site->ServerBindings->[0]);
						if ( defined $site->SecureBindings ) {
							( $sip, $sport, $shost ) = split(":", $site->SecureBindings->[0]);
						}
						else {
							# set to null as the stored proc expects them as parameters
							( $sip, $sport, $shost ) = ( "0", "0", "Undefined" );
						}
					#re-connect using the Name property to access per-site info
					if ( $conn2 = Win32::OLE->GetObject("IIS://$webserver/$service/" . $site->Name . "/root" ) ) {
						print "Connected to : " . $conn2->AppRoot . "\n";
						print "Path: " . $conn2->Path . "\n";
						print "App Friendly Name: " . $conn2->AppFriendlyName . "\n";
						print "User Name: " . $conn2->AnonymousUserName . "\n\n";
	 				}
					# determine state of the service
					&state2desc($site->ServerState);
					# update the db
					if ($DSN->Sql($SQL_ins_website . "'" . $webserver . "'" . "," . "'" . $site->Name . "'" . "," . "'" . $site->ServerComment . "'"  . "," . "'" . $conn2->AnonymousUserName . "'"  . "," . "'" . $state . "'"  . "," . "'" . $ip . "'"  . "," . "'" . $port . "'"  . "," . "'" . $host . "'"  . "," . "'" . $sip . "'"  . "," . "'" . $sport . "'"  . "," . "'" . $shost . "'" . "," . "'" . $conn->LogExtFileBytesRecv . "'" . "," . "'" . $conn->LogExtFileBytesSent . "'" . "," . "'" . $conn->LogExtFileClientIp . "'" . "," . "'" . $conn->LogExtFileComputerName . "'" . "," . "'" . $conn->LogExtFileCookie . "'" . "," . "'" . $conn->LogExtFileDate . "'" . "," . "'" . $conn->LogExtFileHost . "'" . "," . "'" . $conn->LogExtFileHttpStatus . "'" . "," . "'" . $conn->LogExtFileMethod . "'" . "," . "'" . $conn->LogExtFileProtocolVersion . "'" . "," . "'" . $conn->LogExtFileReferer . "'" . "," . "'" . $conn->LogExtFileServerIp . "'" . "," . "'" . $conn->LogExtFileServerPort . "'" . "," . "'" . $conn->LogExtFileSiteName . "'" . "," . "'" . $conn->LogExtFileTime . "'" . "," . "'" . $conn->LogExtFileTimeTaken . "'" . "," . "'" . $conn->LogExtFileUriQuery . "'" . "," . "'" . $conn->LogExtFileUriStem . "'" . "," . "'" . $conn->LogExtFileUserAgent . "'" . "," . "'" . $conn->LogExtFileUserName . "'" . "," . "'" . $conn->LogExtFileWin32Status . "'"))
						{
						($ErrNum, $ErrText, $ErrConn) = $DSN->Error();
						#print  "Machine: $webserver\n";
						#print  "SQL error: $ErrConn\n";
						#print  "ErrorNum: $ErrNum\n";
						#print  "Text: $ErrText\n\n";
						}
				}
				elsif ( $site->Class eq "IIsFtpServer" ) {
					#print "Starting FTP enumeration on $webserver.\n";
					( $ip, $port, $host ) = split(":", $site->ServerBindings->[0]);
					# determine state of the service
					# note that placing this sub within the @row block does not work
					&state2desc($site->ServerState);

					# set to null as the stored proc expects them as parameters
					( $sip, $sport, $shost ) = ( "0", "0", "Undefined" );
					# update the db
					if ($DSN->Sql($SQL_ins_website . "'" . $webserver . "'" . "," . "'" . $site->Name . "'" . "," . "'" . $site->ServerComment . "'"  . "," . "'" . $conn2->AnonymousUserName . "'"  . "," . "'" . $state . "'"  . "," . "'" . $ip . "'"  . "," . "'" . $port . "'"  . "," . "'" . $host . "'"  . "," . "'" . $sip . "'"  . "," . "'" . $sport . "'"  . "," . "'" . $shost . "'" . "," . "'" . $conn->LogExtFileBytesRecv . "'" . "," . "'" . $conn->LogExtFileBytesSent . "'" . "," . "'" . $conn->LogExtFileClientIp . "'" . "," . "'" . $conn->LogExtFileComputerName . "'" . "," . "'" . $conn->LogExtFileCookie . "'" . "," . "'" . $conn->LogExtFileDate . "'" . "," . "'" . $conn->LogExtFileHost . "'" . "," . "'" . $conn->LogExtFileHttpStatus . "'" . "," . "'" . $conn->LogExtFileMethod . "'" . "," . "'" . $conn->LogExtFileProtocolVersion . "'" . "," . "'" . $conn->LogExtFileReferer . "'" . "," . "'" . $conn->LogExtFileServerIp . "'" . "," . "'" . $conn->LogExtFileServerPort . "'" . "," . "'" . $conn->LogExtFileSiteName . "'" . "," . "'" . $conn->LogExtFileTime . "'" . "," . "'" . $conn->LogExtFileTimeTaken . "'" . "," . "'" . $conn->LogExtFileUriQuery . "'" . "," . "'" . $conn->LogExtFileUriStem . "'" . "," . "'" . $conn->LogExtFileUserAgent . "'" . "," . "'" . $conn->LogExtFileUserName . "'" . "," . "'" . $conn->LogExtFileWin32Status . "'"))
                        		{
						($ErrNum, $ErrText, $ErrConn) = $DSN->Error();
						print  "Machine: $webserver\n";
						print  "SQL error: $ErrConn\n";
						print  "ErrorNum: $ErrNum\n";
						print  "Text: $ErrText\n\n";
	                  		}
				}
			}
			$dexlog->Msg("Completed enumerating IIS Sites on $webserver...\n");
		}
		else
		{
			warn "\tCannot create connection object to $webserver for $service: $!\n";
			$dexlog->Msg("*** Cannot create connection object to $webserver for $service: $! ***\n");
		}
	}
}

# translate numeric state to text for services
sub state2desc {
    my $item = shift;
    #print "Inside state loop: $item\n";
	switch ($item) {
		case '1' { $state = "Starting"; }
		case '2' { $state = "Started"; }
		case '3' { $state = "Stopping"; }
		case '4' { $state = "Stopped"; }
		case '5' { $state = "Pausing"; }
		case '6' { $state = "Paused"; }
		case '7' { $state = "Continuing"; }
		case ""  { $state = "Unknown state"; }
		return $state;
	}
}
