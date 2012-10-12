use strict;
use Win32::OLE('in');
use Switch;

use constant wbemFlagReturnImmediately => 0x10;
use constant wbemFlagForwardOnly => 0x20;

my ($cpu0, $cpu1, $cpu2, $cpu3);

my $computer = @ARGV[0];


   my $objWMIService = Win32::OLE->GetObject("winmgmts:\\\\$computer\\root\\CIMV2") or die "WMI connection failed.\n";
   my @colItems = $objWMIService->ExecQuery("SELECT LoadPercentage,DeviceID FROM Win32_Processor", "WQL",
                  wbemFlagReturnImmediately | wbemFlagForwardOnly);

   foreach my $objItem (in @colItems) {
      switch ($objItem->{DeviceID}) {
	  	    case "CPU0"			{ $cpu0 = $objItem->{LoadPercentage} }
	  	    case "CPU1"			{ $cpu1 = $objItem->{LoadPercentage} }
	  	    case "CPU2"			{ $cpu2 = $objItem->{LoadPercentage} }
	  	    case "CPU3"			{ $cpu3 = $objItem->{LoadPercentage} }
	  	  }
	  #print "\n";
   }
print "$cpu0\n";
# don't assume there is a 2nd processor(real or virtual)
if ($cpu1 != 0) {
   print "$cpu1\n";
   }
   else {
	print "0\n";
	}
# if cpu2 has a value, assume cpu3 does as well(has there ever been a 3 processor machine?)
if ($cpu2 != 0) {
    print "$cpu2\n";
    print "$cpu3\n";
}

print "0\n";
print "$computer\n";