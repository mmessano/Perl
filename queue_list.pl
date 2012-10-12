#!c:/perl/bin -w
#
# queue_list.pl
#



use strict;
use diagnostics;
use warnings;
use Win32::ODBC;
use Win32::OLE('in');
use IO::File;
use Switch;
use constant wbemFlagReturnImmediately => 0x10;
use constant wbemFlagForwardOnly => 0x20;

my ($DSN, $queueItem, $ErrNum, $ErrText, $ErrConn, $SQL, $rxGUID, $failure_file, $OUTPUT);

# Set the DSN name
$DSN = new Win32::ODBC("Status") or die "Error: " . Win32::ODBC::Error();

# Trailing space is necessary!
# parameter list: @server_name varchar(50),	@queue_name varchar(50)
$SQL= "exec sp_ins_queue_server_assoc ";


my $infile = "\\\\mensa\\Dexma\\Data\\ALL_Queues.txt";
open(DAT, $infile) || warn ("Could not open $infile for reading!");
my @computers = <DAT>;
close DAT;
chomp @computers;

foreach my $computer (@computers) {
   chomp $computer;
   my $dexlog = Win32::OLE->new('Dexma.Dexlog') or warn "Cannot create DexLog object $!\n";
   $dexlog->SetProperty('ModuleName','queue_list');
#   print "\n";
#   print "==========================================\n";
#   print "Computer: $computer\n";
#   print "==========================================\n";
#   print "\n";
   if (my $objWMIService = Win32::OLE->GetObject("winmgmts:\\\\$computer\\root\\CIMV2")) {


   my $queueItems = $objWMIService->ExecQuery("SELECT * FROM Win32_PerfRawData_MSMQ_MSMQQueue", "WQL",
                  wbemFlagReturnImmediately | wbemFlagForwardOnly) or warn "WMI connection failed.\n";

    $DSN->Sql("delete from t_queue_server_assoc where server_id = (select server_id from t_server where server_name = '$computer')");
    #$dexlog->Msg("delete from t_queue_server_assoc where server_id = (select server_id from t_server where server_name = '$computer')");

	foreach $queueItem (in sort($queueItems)) {
	  # split $queueItem->{Name} into seperate parts using "\"
	  # by doing this it is easier to exclude the known variations returned by WMI
	  # WMI returns the list of private and dynamic queues by default which are not necessary
	  # dynamic queues will always be a GUID of five(5) parts seperated by a "-"
	  # private queues always have three(3) parts (server\private$\[admin,order,notify]_queue$)
   	  # exclude foreign queues by comparing the value of $parts[0] from the original split
	  my @parts = split(/\\/, $queueItem->{Name});
	  my $parts_num = scalar(@parts);
	  my @parts_name = split(/-/, $parts[0]);
	  my $parts_name_num = scalar(@parts_name);
	  #print "@parts\n";
	  if ($parts_name_num == 5)
	  {
	  	#print "GUID matched!:\n\t $parts[0]\n";
	  }
	  else
	  {
		  #print "Name: $name\n";
		  #print "Computer: $computer\n";
		  if ($parts[0] =~ /$computer/i)
		  {
		  	    if ($parts_num < 3)
			  {
			  	#print "$parts[0] , $parts[1]\n";
                if ($DSN->Sql($SQL . "'" . $parts[0]
							   . "'" . "," . "'" . $parts[1]
							    . "'"))
							   {
									($ErrNum, $ErrText, $ErrConn) = $DSN->Error();
									print "SQL insert failed!\n";
									print "Computer: $parts[0]\n";
									print "Queue: $parts[1]\n";
									print "$ErrText\n";
									$dexlog->Msg("SQL insert failed!\n");
									$dexlog->Msg("Computer: $parts[0]\n");
									$dexlog->Msg("Queue: $parts[1]\n");
									$dexlog->Msg("$ErrText\n");
								}
			  }
			  else
			  {
	              #print "Private queue found!:\n\t$parts[0] , $parts[1] , $parts[2]\n";
			  }

		  }
		  else
		  {
			 #print "Foreign queue!\n\t$parts[0] , $parts[1]\n"
		  }
	  }
	}
}
	else
	{

	$dexlog->Msg("WMI connection failed for $computer.");
 	#print "WMI connection failed for $computer.\n";
	#warn "Cannot connect to WMI: $!\n";
	}

}
