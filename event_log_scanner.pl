#!c:/perl/bin -w
#
# event_log_scanner.pl
#

use strict;
use diagnostics;
use warnings;
use Win32::OLE('in');

use constant wbemFlagReturnImmediately => 0x10;
use constant wbemFlagForwardOnly => 0x20;

my @computers = ("indus");
foreach my $computer (@computers) {
   print "\n";
   print "==========================================\n";
   print "Computer: $computer\n";
   print "==========================================\n";

   my $objWMIService = Win32::OLE->GetObject("winmgmts:\\\\$computer\\root\\CIMV2") or die "WMI connection failed.\n";
   my $colItems = $objWMIService->ExecQuery("SELECT * FROM Win32_NTLogEvent Where Logfile = \'BulkFileMover\'", "WQL",
                  wbemFlagReturnImmediately | wbemFlagForwardOnly);

   foreach my $objItem ( in $colItems ) {
      print "Category: $objItem->{Category}\n";
      print "CategoryString: $objItem->{CategoryString}\n";
      print "ComputerName: $objItem->{ComputerName}\n";
      print "Data: " . join(",", (in $objItem->{Data})) . "\n";
      print "EventCode: $objItem->{EventCode}\n";
      print "EventIdentifier: $objItem->{EventIdentifier}\n";
      print "EventType: $objItem->{EventType}\n";
      print "InsertionStrings: " . join(",", (in $objItem->{InsertionStrings})) . "\n";
      print "Logfile: $objItem->{Logfile}\n";
      print "Message: $objItem->{Message}\n";
      print "RecordNumber: $objItem->{RecordNumber}\n";
      print "SourceName: $objItem->{SourceName}\n";
      print "TimeGenerated: $objItem->{TimeGenerated}\n";
      print "TimeWritten: $objItem->{TimeWritten}\n";
      print "Type: $objItem->{Type}\n";
      print "User: $objItem->{User}\n";
      print "\n";
   }
}
