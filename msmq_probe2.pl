use strict;
use Win32::OLE('in');

use constant wbemFlagReturnImmediately => 0x10;
use constant wbemFlagForwardOnly => 0x20;

my @computers = ("pyxis");
foreach my $computer (@computers) {
   print "\n";
   print "==========================================\n";
   print "Computer: $computer\n";
   print "==========================================\n";

   my $objWMIService = Win32::OLE->GetObject("winmgmts:\\\\$computer\\root\\CIMV2") or die "WMI connection failed.\n";
   my $colItems = $objWMIService->ExecQuery("SELECT * FROM Win32_PerfRawData_MSMQ_MSMQQueue", "WQL",
                  wbemFlagReturnImmediately | wbemFlagForwardOnly);

   foreach my $objItem (in $colItems) {
      print "BytesinJournalQueue: $objItem->{BytesinJournalQueue}\n";
      print "BytesinQueue: $objItem->{BytesinQueue}\n";
      print "Caption: $objItem->{Caption}\n";
      print "Description: $objItem->{Description}\n";
      print "Frequency_Object: $objItem->{Frequency_Object}\n";
      print "Frequency_PerfTime: $objItem->{Frequency_PerfTime}\n";
      print "Frequency_Sys100NS: $objItem->{Frequency_Sys100NS}\n";
      print "MessagesinJournalQueue: $objItem->{MessagesinJournalQueue}\n";
      print "MessagesinQueue: $objItem->{MessagesinQueue}\n";
      print "Name: $objItem->{Name}\n";
      print "Timestamp_Object: $objItem->{Timestamp_Object}\n";
      print "Timestamp_PerfTime: $objItem->{Timestamp_PerfTime}\n";
      print "Timestamp_Sys100NS: $objItem->{Timestamp_Sys100NS}\n";
      print "\n";
   }
}
