use strict;
use Win32::OLE('in');

use constant wbemFlagReturnImmediately => 0x10;
use constant wbemFlagForwardOnly => 0x20;

my @computers = ("xweb1");
foreach my $computer (@computers) {
   print "\n";
   print "==========================================\n";
   print "Computer: $computer\n";
   print "==========================================\n";

   my $objWMIService = Win32::OLE->GetObject("winmgmts:\\\\$computer\\root\\DEFAULT") or die "WMI connection failed.\n";
   my $colItems = $objWMIService->ExecQuery("SELECT * FROM StdRegProv", "WQL",
                  wbemFlagReturnImmediately | wbemFlagForwardOnly);

   foreach my $objItem (in $colItems) {
      print "\n";
   }
}
