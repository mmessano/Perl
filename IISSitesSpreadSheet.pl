#!c:/perl/bin -w
#
# domain_scanner.pl
#

use strict;
use diagnostics;
use warnings;
use IO::File;
#use POSIX;
use Spreadsheet::WriteExcel;
use Switch;
use win32::ADO;
use Win32::NetAdmin;
use Win32::ODBC;
use Win32::OLE::Const 'Microsoft ActiveX Data Objects 2.5';

my ( @domains, $domain, $dexlog, $outfile, $OUTPUT, @servers, $machine, @machines, $line, $pdc, $server, $DSN, %SQL_Errors, $SQL_sel_servers, $SQL_ins_website, $failure_file, $FAILURES, $ErrNum, $ErrText, $ErrConn );
my ( $ip, $port, $host, $sip, $sport, $shost );
my ( $newrow, $outsheet, $state, $obook, $outbook, @header );
my ( $conn2, @row );

# spreadsheet to write to
$obook = "C:\\Dexma\\Logs\\net_list_aggregate2.xls";

$outbook =  Spreadsheet::WriteExcel->new("$obook");
$outsheet = $outbook->add_worksheet();

# format definitions
my %header_row = (
					font 		=>	'Arial',
					size 		=>	'14',
					bg_color 	=>	'55',
					bold 		=>	'1',
					align		=>	'center'
				);


my %alert_row = (
					font 	=>	'Arial',
					size 	=>	'12',
					color 	=>	'red',
					bold 	=>	'1',
					align	=>	'center'
				);

my %stopped_row = (
					font	=>	'Arial',
					size	=>	'10',
					color	=>	'grey',
					align	=>	'center'
					);


my %running_row = (
					color	=>	'green',
					align	=>	'center'
					);

# row formats
my $header = $outbook->add_format();
   $header->set_properties(%header_row);
my $running = $outbook->add_format();
   $running->set_properties(%running_row);
my $stopped = $outbook->add_format();
   $stopped->set_properties(%stopped_row);
my $paused  = $outbook->add_format();
   $paused->set_properties(%alert_row);
my $stop_starting = $outbook->add_format();
   $stop_starting->set_properties(%alert_row);

# header row
@header =  (
		[ "Server", "Site ID", "Comment", "Configured User", "Status", "IP", "Port", "Host Header", "Secure IP", "Secure Port", "Secure Host Header", "LogExtFileBytesRecv", "LogExtFileBytesSent", "LogExtFileClientIp", "LogExtFileComputerName", "LogExtFileCookie", "LogExtFileDate", "LogExtFileHost", "LogExtFileHttpStatus", "LogExtFileMethod", "LogExtFileProtocolVersion", "LogExtFileReferer", "LogExtFileServerIp", "LogExtFileServerPort", "LogExtFileSiteName", "LogExtFileTime", "LogExtFileTimeTaken", "LogExtFileUriQuery", "LogExtFileUriStem", "LogExtFileUserAgent", "LogExtFileUserName", "LogExtFileWin32Status" ]
		);


# write the header and freeze the worksheet
$outsheet->write_col(0, 0, \@header, $header);
$outsheet->freeze_panes(1, 0);

# increment for header row
$newrow = 1;


$DSN = new Win32::ODBC("status") or die "Error: " . Win32::ODBC::Error();

$dexlog = Win32::OLE->new('Dexma.Dexlog') or warn "Cannot create DexLog object $!\n";
$dexlog->SetProperty('ModuleName','IISSitesSpreadSheet');


%SQL_Errors = (server=>'', file=>'', name=>'', SQLState=>'', Number=>'', Text=>'');

# Trailing space is necessary!
#$SQL_ins = "exec sp_ins_server ";    #	@server_name varchar(50), @environment_id int, @description varchar, @active int
$SQL_ins_website = "exec sp_ins_website ";    #  @server_id, @website_id, @comment, @status, @ip_address, @port, @host_header, @secure_ip_address, @secure_port, @secure_host_header
$SQL_sel_servers = "select s.server_name \
		 from t_server s	inner join \
		 t_monitoring m ON s.server_id = m.server_id	inner join \
		 t_environment e ON s.environment_id = e.environment_id \
		 where 	s.Active = '1' \
		 and m.iissites = '1' \
		 order by 1";

#print $SQL_sel_servers . "\n";


# suppress errors on connection failure
Win32::OLE->Option(Warn => 0);

# select servers to scan
$DSN->Sql($SQL_sel_servers);

# while( $DSN->FetchRow() ) {
#        @machines  =  $DSN->Data;
# }
# print @machines . "\n";


#foreach $machine (@machines) {
while( $DSN->FetchRow() ) {
	my $machine = $DSN->Data;
	$failure_file = "\\\\mensa\\dexma\\logs\\" .$machine . "_errors.txt";
	print "Begin enumerating $machine...\n";
 	$dexlog->Msg("Begin enumerating $machine...\n");

	#&enum_sites($machine);

	print "Completed enumerating $machine...\n";
        $dexlog->Msg("Completed enumerating $machine...\n");

	if (-e $failure_file){unlink $failure_file;}
       		if ($DSN->Sql("sp_ins_server '$machine', '11', 'Unknown', '1'"))
                        {
			($ErrNum, $ErrText, $ErrConn) = $DSN->Error();
			$FAILURES = IO::File->new($failure_file, ">>") or warn "Cannot open $failure_file! $!\n";
			print $FAILURES "Machine: $machine\n";
			print $FAILURES "SQL error: $ErrConn\n";
			print $FAILURES "ErrorNum: $ErrNum\n";
			print $FAILURES "Text: $ErrText\n\n";
			close $FAILURES;
                  }
		if ($machine =~ /(\w+\d{3,}$)/) {
			#print "$machine is a workstation\n";
		}
}
print "\n";
if ( ! stat($failure_file)){
	#warn "$failure_file: $!\n"
}
        else {
	system ("c:\\dexma\\bin\\blat $failure_file -t mmessano\@primealliancesolutions.com -subject \"SQL inserts for $machine have failed.\" " or die "$!\n");
}

# begin sub definitions

# enumerate web and ftp sites
sub enum_sites {
	my @services = ('W3SVC', 'MSFTPSVC');
	my ( $webserver ) = @_;
	foreach my $service ( @services ) {
		if ( my $conn = Win32::OLE->GetObject("IIS://$webserver/$service") ) {
			foreach my $site ( in $conn ) {
				if ( $site->Class eq "IIsWebServer" ) {
					print "Starting W3SVC enumeration on $webserver.\n";
					    ( $ip, $port, $host ) = split(":", $site->ServerBindings->[0]);
						if ( defined $site->SecureBindings ) {
							( $sip, $sport, $shost ) = split(":", $site->SecureBindings->[0]);
						}
					#re-connect using the Name property to access per-site info
					if ( $conn2 = Win32::OLE->GetObject("IIS://$webserver/$service/" . $site->Name . "/root" ) ) {
						print "Connected to : " . $conn2->AppRoot . "\n";
						print "Path: " . $conn2->Path . "\n";
						print "App Friendly Name: " . $conn2->AppFriendlyName . "\n";
						print "User Name: " . $conn2->AnonymousUserName . "\n\n";
	 				}
					# determine state of the service
					# note that placing this sub within the @row block does not work
					print "State2Desc\n";
					&state2desc($site->ServerState);
					# create an array of the parsed values
					print "Create row\n";
					#print "Values used: $webserver, $site->Name, $site->ServerComment, $conn2->AnonymousUserName, $state, $ip, $port, $host, $sip, $sport, $shost, $conn->LogExtFileBytesRecv, $conn->LogExtFileBytesSent, $conn->LogExtFileClientIp, $conn->LogExtFileComputerName, $conn->LogExtFileCookie, $conn->LogExtFileDate, $conn->LogExtFileHost, $conn->LogExtFileHttpStatus, $conn->LogExtFileMethod, $conn->LogExtFileProtocolVersion, $conn->LogExtFileReferer, $conn->LogExtFileServerIp, $conn->LogExtFileServerPort, $conn->LogExtFileSiteName, $conn->LogExtFileTime, $conn->LogExtFileTimeTaken, $conn->LogExtFileUriQuery, $conn->LogExtFileUriStem, $conn->LogExtFileUserAgent, $conn->LogExtFileUserName, $conn->LogExtFileWin32Status\n";
					@row =  (
                				[ $webserver, $site->Name, $site->ServerComment, $conn2->AnonymousUserName, $state, $ip, $port, $host, $sip, $sport, $shost, $conn->LogExtFileBytesRecv, $conn->LogExtFileBytesSent, $conn->LogExtFileClientIp, $conn->LogExtFileComputerName, $conn->LogExtFileCookie, $conn->LogExtFileDate, $conn->LogExtFileHost, $conn->LogExtFileHttpStatus, $conn->LogExtFileMethod, $conn->LogExtFileProtocolVersion, $conn->LogExtFileReferer, $conn->LogExtFileServerIp, $conn->LogExtFileServerPort, $conn->LogExtFileSiteName, $conn->LogExtFileTime, $conn->LogExtFileTimeTaken, $conn->LogExtFileUriQuery, $conn->LogExtFileUriStem, $conn->LogExtFileUserAgent, $conn->LogExtFileUserName, $conn->LogExtFileWin32Status  ]
            					);
     				# write the values out to the new spreadsheet using a reference to the above array
     				# format according to the site state
     				print "Begin writing to spreadsheet\n";
     				if ( $state =~ /Stopped/ ) {
					   $outsheet->write_col($newrow, 0, \@row, $stopped);
					    }
					elsif ( $state =~ /Paused/ ) {
					  	 $outsheet->write_col($newrow, 0, \@row, $paused);
					}
					elsif ( $state =~ /Starting/ or $state =~ /Stopping/ ) {
					  	 $outsheet->write_col($newrow, 0, \@row, $paused);
					}
					else  {
						  $outsheet->write_col($newrow, 0, \@row, $running);
					}

					$newrow++;
					print "Done updating spreadsheet\n";
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
				elsif ( $site->Class eq "IIsFtpServer" ) {
						print "Starting FTP enumeration on $webserver.\n";
						( $ip, $port, $host ) = split(":", $site->ServerBindings->[0]);
						# determine state of the service
						# note that placing this sub within the @row block does not work
						&state2desc($site->ServerState);
						my @row =  (
                					[ $webserver, $site->Name, $site->ServerComment, $site->AnonymousUserName, $state, $ip, $port, $host, $sip, $sport, $shost, $conn->LogExtFileBytesRecv, $conn->LogExtFileBytesSent, $conn->LogExtFileClientIp, $conn->LogExtFileComputerName, $conn->LogExtFileCookie, $conn->LogExtFileDate, $conn->LogExtFileHost, $conn->LogExtFileHttpStatus, $conn->LogExtFileMethod, $conn->LogExtFileProtocolVersion, $conn->LogExtFileReferer, $conn->LogExtFileServerIp, $conn->LogExtFileServerPort, $conn->LogExtFileSiteName, $conn->LogExtFileTime, $conn->LogExtFileTimeTaken, $conn->LogExtFileUriQuery, $conn->LogExtFileUriStem, $conn->LogExtFileUserAgent, $conn->LogExtFileUserName, $conn->LogExtFileWin32Status  ]
            						);
            			# write the values out to the new spreadsheet using a reference to the above array
				# format according to the site state
     				if ( $state =~ /Stopped/ ) {
					   $outsheet->write_col($newrow, 0, \@row, $stopped);
					    }
					elsif ( $state =~ /Paused/ ) {
					  	 $outsheet->write_col($newrow, 0, \@row, $paused);
					}
					elsif ( $state =~ /Starting/ or $state =~ /Stopping/ ) {
					  	 $outsheet->write_col($newrow, 0, \@row, $paused);
					}
					else  {
						  $outsheet->write_col($newrow, 0, \@row, $running);
					}
						$newrow++;
					
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
		}
		else
		{
			warn "\tCannot create connection object to $webserver for $service: $!\n";
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
