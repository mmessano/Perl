#!c:/perl/bin -w
#
# enumwebsites.pl
#

use strict;
use diagnostics;
use warnings;
use IO::File;
use File::Basename;
use File::stat qw(:FIELDS);
use Spreadsheet::WriteExcel;
use Switch;
use Win32::OLE;


my ( $infile, $state, $bindings, $enumbindings, $iiscon, $server, @server, @header, $obook, $outbook, $outsheet, $newrow, $ip, $port, $host, $sip, $sport, $shost );

$infile = "\\\\mensa\\Dexma\\Data\\mjm_temp.txt";
#$infile = "\\\\mensa\\Dexma\\Data\\ALL_Active.txt";
open(DAT, $infile) || die("Could not open $infile for reading!");
@server = <DAT>;

# spreadsheet to write to
$obook = "C:\\Dexma\\temp\\site_list_aggregate.xls";

# header row
@header =  (
			[ "Server", "Site ID", "Comment", "Configured User", "Status", "IP", "Port", "Host Header", "Secure IP", "Secure Port", "Secure Host Header" ]
			);
			
$outbook =  Spreadsheet::WriteExcel->new("$obook");
$outsheet = $outbook->add_worksheet();

$outsheet->write_col(0, 0, \@header);

# increment for header row
$newrow = 1;

# suppress errors on connection failure
Win32::OLE->Option(Warn => 0);

foreach $server ( @server ) {
	chomp $server;
	print "Enumerating sites on " . $server . "...\n";
	&enumsites($server);
	print "\n";
}


sub enumsites {
	my @services = ('W3SVC', 'MSFTPSVC');
	my ( $webserver ) = @_;
	foreach my $service ( @services ) {
		if ( my $conn = Win32::OLE->GetObject("IIS://$webserver/$service") ) {
			foreach my $site ( in $conn ) {
				if ( $site->Class eq "IIsWebServer" ) {
					    ( $ip, $port, $host ) = split(":", $site->ServerBindings->[0]);
						if ( defined $site->SecureBindings ) {
							( $sip, $sport, $shost ) = split(":", $site->SecureBindings->[0]);
						}
					# determine state of the service
					&state2desc($site->ServerState);
					# create an array of the parsed values
					my @row =  (
                				[ $webserver, $site->Name, $site->ServerComment, $site->{AnonymousUserName}, $state, $ip, $port, $host, $sip, $sport, $shost  ]
            					);
     				# write the values out to the new spreadsheet using a reference to the above array
					$outsheet->write_col($newrow, 0, \@row);
					$newrow++;
					
					print $webserver . "\t" . $site->Name . "\t" . $site->ServerComment . "\t" . $site->{AnonymousUserName} . "\t" . $state . "\t" . $ip . "\t" . $port . "\t" . $host . "\t" . $sip . "\t" . $sport . "\t" . $shost . "\n";
                    
					print "Logging flags: " . $conn->LogExtFileBytesRecv . "\n";
					print "LogExtFileBytesRecv: " . $conn->LogExtFileBytesRecv . "\n";;
					print "LogExtFileBytesSent: " . $conn->LogExtFileBytesSent . "\n";;
					print "LogExtFileClientIp: " . $conn->LogExtFileClientIp . "\n";;
					print "LogExtFileComputerName: " . $conn->LogExtFileComputerName . "\n";;
					print "LogExtFileCookie: " . $conn->LogExtFileCookie . "\n";;
					print "LogExtFileDate: " . $conn->LogExtFileDate . "\n";;
					#print "LogExtFileHost: " . $conn->LogExtFileHost . "\n";;
					print "LogExtFileHttpStatus: " . $conn->LogExtFileHttpStatus . "\n";;
					print "LogExtFileMethod: " . $conn->LogExtFileMethod . "\n";;
					print "LogExtFileProtocolVersion: " . $conn->LogExtFileProtocolVersion . "\n";;
					print "LogExtFileReferer: " . $conn->LogExtFileReferer . "\n";;
					print "LogExtFileServerIp: " . $conn->LogExtFileServerIp . "\n";
					print "LogExtFileServerPort: " . $conn->LogExtFileServerPort . "\n";
                    print "LogExtFileSiteName: " . $conn->LogExtFileSiteName . "\n";
                    print "LogExtFileTime: " . $conn->LogExtFileTime . "\n";
                    print "LogExtFileTimeTaken: " . $conn->LogExtFileTimeTaken . "\n";
                    print "LogExtFileUriQuery: " . $conn->LogExtFileUriQuery . "\n";
                    print "LogExtFileUriStem: " . $conn->LogExtFileUriStem . "\n";
                    print "LogExtFileUserAgent: " . $conn->LogExtFileUserAgent . "\n";
                    print "LogExtFileUserName: " . $conn->LogExtFileUserName . "\n";
                    print "LogExtFileWin32Status: " . $conn->LogExtFileWin32Status . "\n";

					if ( my $conn2 = Win32::OLE->GetObject("IIS://$webserver/$service/" . $site->Name . "/root" ) ) {
	 					print "Connected to : " . $conn2->AppRoot . "\n";
                        print "Path: " . $conn2->Path . "\n";
                        print "App Friendly Name: " . $conn2->AppFriendlyName . "\n";

                        print "User Name: " . $conn2->AnonymousUserName . "\n\n";

	 				}

				}
				elsif ( $site->Class eq "IIsFtpServer" ) {
						( $ip, $port, $host ) = split(":", $site->ServerBindings->[0]);
						# determine state of the service
						# note that placing this sub within the @row block does not work
						&state2desc($site->ServerState);
						my @row =  (
                					[ $webserver, $site->Name, $site->ServerComment, $site->{AnonymousUserName}, $state, $ip, $port, $host  ]
            						);
            			# write the values out to the new spreadsheet using a reference to the above array
						$outsheet->write_col($newrow, 0, \@row);
						$newrow++;
						print $webserver . "\t" . $site->Name . "\t" . $site->ServerComment . "\t" . $site->{AnonymousUserName} . "\t" . $state . "\t" . $ip . "\t" . $port . "\t" . $host . "\n";
				}
			}
		}
		else
		{
			warn "Cannot create connection object to $webserver for $service: $!\n";
		}
	}
}


sub state2desc {
    my $item = shift;
    #print "Inside state loop: $item\n";
	switch ($item) {
		#case "filePattern" 		{ $dir_listener->{filePattern}= $text; }
		case '1' { $state = "Starting"; }
	    case '2' { $state = "Started"; }
	    case '3' { $state = "Stopping"; }
	    case '4' { $state = "Stopped"; }
	    case '5' { $state = "Pausing"; }
	    case '6' { $state = "Paused"; }
	    case '7' { $state = "Continuing (MD_SERVER_STATE_CONTINUING)"; }
	    case ""  { $state = "Unknown state"; }
	    return $state;
    }
}