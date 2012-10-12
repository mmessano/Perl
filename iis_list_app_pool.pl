use strict;
use Win32::OLE('in');

use constant wbemFlagReturnImmediately => 0x10;
use constant wbemFlagForwardOnly => 0x20;

my @computers = ("paweb5");
foreach my $computer (@computers) {
   print "\n";
   print "==========================================\n";
   print "Computer: $computer\n";
   print "==========================================\n";

   my $objWMIService = Win32::OLE->GetObject("winmgmts:\\\\$computer\\root\\MicrosoftIISv2") or die "WMI connection failed.\n";
   my $colItems = $objWMIService->ExecQuery("SELECT * FROM IIsApplicationPool", "WQL", wbemFlagReturnImmediately | wbemFlagForwardOnly);

   foreach my $objItem (in $colItems) {
      print "Caption: $objItem->{Caption}\n";
      print "Description: $objItem->{Description}\n";
      print "InstallDate: $objItem->{InstallDate}\n";
      print "Name: $objItem->{Name}\n";
      print "Status: $objItem->{Status}\n";
      print "\n";
   }
}sub WMIDateStringToDate(strDate)
{
   return "blah";
}
