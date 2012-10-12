use strict;
#use diagnostics;
#use warnings;
use Win32::OLE('in');

use constant wbemFlagReturnImmediately => 0x10;
use constant wbemFlagForwardOnly => 0x20;

my @computers = ("xdev2kapp1");
foreach my $computer (@computers) {
   print "\n";
   print "==========================================\n";
   print "Computer: $computer\n";
   print "==========================================\n";

   my $objWMIService = Win32::OLE->GetObject("winmgmts:\\\\$computer\\root\\CIMV2") or die "WMI connection failed.\n";
   my $colItems = $objWMIService->ExecQuery("SELECT * FROM Win32_PerfRawData_MSMQ_MSMQQueue", "WQL",
                  wbemFlagReturnImmediately | wbemFlagForwardOnly);
   sort $colItems;
   foreach my $objItem (in $colItems) {
      print "Name: $objItem->{Name}\n";
#      print "MessagesinQueue: $objItem->{MessagesinQueue}\n";
#      print "MessagesinJournalQueue: $objItem->{MessagesinJournalQueue}\n";
#      print "BytesinJournalQueue: $objItem->{BytesinJournalQueue}\n";
#      print "BytesinQueue: $objItem->{BytesinQueue}\n";
      print "\n";
   }
}
