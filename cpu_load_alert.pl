use strict;
use Win32::OLE('in');
use Switch;

use constant wbemFlagReturnImmediately => 0x10;
use constant wbemFlagForwardOnly => 0x20;

my $computer = @ARGV[0];
#strComputer = "."


   my $objWMIService = Win32::OLE->GetObject("winmgmts:{impersonationLevel=impersonate}!\\\\$computer\\root\\CIMV2") or die "WMI connection failed.\n";
   my $objRefresher = Win32::OLE->new("WbemScripting.Swbemrefresher");
   my $objProcessor = $objRefresher->Addenum ($objWMIService, "Win32_PerfFormattedData_PerfOS_Processor")->objectSet;
   #my @colItems = $objWMIService->ExecQuery("SELECT LoadPercentage,DeviceID FROM Win32_Processor", "WQL", wbemFlagReturnImmediately | wbemFlagForwardOnly);

#Set objWMIService = GetObject("winmgmts:" _
#    & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
#set objRefresher = CreateObject("WbemScripting.Swbemrefresher")
#Set objProcessor = objRefresher.AddEnum _
#    (objWMIService, "Win32_PerfFormattedData_PerfOS_Processor").objectSet

my $intThresholdViolations = 0;
$objRefresher->Refresh;

#intThresholdViolations = 0
#objRefresher.Refresh

foreach my $intProcessorUse (in $objProcessor) {
	if ($intProcessorUse->PercentProcessorTime > 90) {
	   my $intThresholdViolations = $intThresholdViolations + 1;
	   	  if ($intThresholdViolations = 10) {
		  	$intThresholdViolations = 0;
		  	print "Processor usage threshold exceeded.\n";
		  	  }
	}
	else {
		$intThresholdViolations = 0;
	}
}

#Do
#    For each intProcessorUse in objProcessor
#        If intProcessorUse.PercentProcessorTime > 90 Then
#            intThresholdViolations = intThresholdViolations + 1
#                If intThresholdViolations = 10 Then
#                    intThresholdViolations = 0
#                    Wscript.Echo "Processor usage threshold exceeded."
#                End If
#        Else
#            intThresholdViolations = 0
#        End If
#    Next
#    Wscript.Sleep 6000
#    objRefresher.Refresh
#Loop