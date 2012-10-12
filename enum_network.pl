#!c:/perl/bin -w
#
# enumerate the entire network via IP ranges
# enum_network.pl
#

use strict;
use diagnostics;
use warnings;
#use Date::Calc qw/Today Delta_Days/;
use Net::Ping;
use Spreadsheet::WriteExcel;
use Switch;
use Win32::OLE('in');
use Win32::TaskScheduler;
use Sys::Hostname;


my $adr = "192.168.";
my @net = qw / 97. 100. 102. 104. 105. 32. 33. 34. /;
my ( $i, $j, $host, $p );
my ( $ip, $port, $sip, $sport, $shost );
my ( $newrow, $outsheet, $state, $obook, $outbook, @header );



# spreadsheet to write to
$obook = "C:\\Dexma\\temp\\net_list_aggregate.xls";

# header row
@header =  (
			[ "Server", "Site ID", "Comment", "Status", "IP", "Port", "Host Header", "Secure IP", "Secure Port", "Secure Host Header" ]
			);
			
$outbook =  Spreadsheet::WriteExcel->new("$obook");
$outsheet = $outbook->add_worksheet();

$outsheet->write_col(0, 0, \@header);

# increment for header row
$newrow = 1;

# suppress errors on connection failure
Win32::OLE->Option(Warn => 0);




my $dexlog = Win32::OLE->new('Dexma.Dexlog') ;
$p = Net::Ping->new( "tcp", 3 ) or die $dexlog->Msg("Can't create ping object: $!\n");




for ( $i = 0 ; $i <= 7 ; $i++ ) {
  HOST: for ( $j = 16 ; $j <= 250 ; $j++ ) {
        $host = $adr . $net[$i] . $j;
        if ( !$p->ping($host) ) {
            print "Host $host is unreachable.\n";
            $dexlog->Msg("Ping connection failed for $host. $!");
			next HOST;
        }
        else {
			print "Host $host is up.\n";
			$dexlog->Msg("Ping connection succeeded for $host.");
            my $objWMIService = Win32::OLE->GetObject("winmgmts:\\\\$host\\root\\CIMV2") or die "WMI connection failed.\n";
            my $hname = $objWMIService->ExecQuery("SELECT Name FROM Win32_ComputerSystem", "WQL");
			foreach my $item ( in $hname ) {
				print "Name: " . $item->{Name} . "\n";
			}
			#&enumsites($host);
            #&enum_jobs($host);

			
  		}
  }
    $p->close;
}


# begin sub definitions

# enumerate web and ftp sites
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
					# note that placing this sub within the @row block does not work
					&state2desc($site->ServerState);
					# create an array of the parsed values
					my @row =  (
                				[ $webserver, $site->Name, $site->ServerComment, $state, $ip, $port, $host, $sip, $sport, $shost  ]
            					);
     				# write the values out to the new spreadsheet using a reference to the above array
					$outsheet->write_col($newrow, 0, \@row);
					$newrow++;
				}
				elsif ( $site->Class eq "IIsFtpServer" ) {
						( $ip, $port, $host ) = split(":", $site->ServerBindings->[0]);
						# determine state of the service
						# note that placing this sub within the @row block does not work
						&state2desc($site->ServerState);
						my @row =  (
                					[ $webserver, $site->Name, $site->ServerComment, $state, $ip, $port, $host  ]
            						);
            			# write the values out to the new spreadsheet using a reference to the above array
						$outsheet->write_col($newrow, 0, \@row);
						$newrow++;
				}
			}
		}
		else
		{
			warn "Cannot create connection object to $webserver for $service: $!\n";
		}
	}
}

# translate numeric state to text for services
sub state2desc {
    my $item = shift;
    print "Inside state loop: $item\n";
	switch ($item) {
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

# enumerate scheduled tasks
sub enum_jobs {
	my $machine = shift;
	chomp $machine;
	my $unc = "\\\\" . $machine;
	my $scheduler = Win32::TaskScheduler->New();
	if ( $scheduler->SetTargetComputer($unc) ) {
		my @jobs = $scheduler->Enum();
		my $count = @jobs;
		print "Job count for " . $machine . " is " . $count . "\n";
		foreach my $job ( @jobs ) {
			$scheduler->Activate($job);
			print $scheduler->GetAccountInformation() . "\t" . $scheduler->GetApplicationName() . "\t" . $scheduler->GetWorkingDirectory() . "\t" . $scheduler->GetComment() . "\t" . $scheduler->GetCreator() . "\t" . $scheduler->GetTriggerString(0) . "\n";
		}
	}
	else
	{
	print "Connection to $machine failed! (" .  $! . ")\n";
	}
}