#!c:/perl/bin -w
#
# memory_db_update.pl
#

use strict;
use Switch;
use Win32::OLE('in');
use Win32::ODBC;


my ( $PurgeDB, $AvailPhysMemMB, $TotalPhysMem, $AvailVirMem,  $TotalPhysMemMB, $AvailVirMemMB, $TotalVirMem, $PercentPhysMem, $PercentVirMem, $MemSum, $VirMemInUseSum, $SQLStatement, $DSN, $rrdupdate, $name, $dir, $infile, @computers );

use constant wbemFlagReturnImmediately => 0x10;
use constant wbemFlagForwardOnly => 0x20;

$rrdupdate = "e:\\Dexma\\support\\Monitoring\\rrdtool.exe update ";
$dir = "e:\\Dexma\\support\\Monitoring\\memory\\";

switch ($ARGV[0]) {
	case "PROD"			{ $infile = "\\\\mensa\\Dexma\\Data\\PROD_Monitoring_memory.txt"; }
	case "DEMO"			{ $infile = "\\\\mensa\\Dexma\\Data\\DEMO_Monitoring_memory.txt"; }
	case "IMP" 			{ $infile = "\\\\mensa\\Dexma\\Data\\IMP_Monitoring_memory.txt"; }
	case "QA" 			{ $infile = "\\\\mensa\\Dexma\\Data\\QA_Monitoring_memory.txt"; }
	case "DEVT" 		{ $infile = "\\\\mensa\\Dexma\\Data\\DEVT_Monitoring_memory.txt"; }
	case "FHHLC_Prod"	{ $infile = "\\\\mensa\\Dexma\\Data\\FHHLC_PROD_Monitoring_memory.txt"; }
	case "Ops-Inf"		{ $infile = "\\\\mensa\\Dexma\\Data\\Ops-Inf_Monitoring_memory.txt"; }
	case "PrePROD"		{ $infile = "\\\\mensa\\Dexma\\Data\\PreProd_monitoring_memory.txt"; }
	case "DEAD"			{ $infile = "\\\\mensa\\Dexma\\Data\\Dead.txt"; }
}

# suppress errors on connection failure(console only, error will be logged)
Win32::OLE->Option(Warn => 0);

$DSN = new Win32::ODBC("Status");

$PurgeDB = "DELETE FROM Memory_monitor WHERE datediff(d, last_update, getdate())> 30";
         if ($DSN->Sql($PurgeDB)){
              print "SQL failed.\n";
              print "Error: " . $DSN->Error() . "\n";
              }

open (FILE, $infile) or die "Couldn't open $infile: $!; aborting";
@computers = <FILE>;
close FILE;

$MemSum = 0;
$VirMemInUseSum = 0;

foreach my $computer (@computers) {
      chomp $computer;
      $name = $computer  . "_mem.rrd ";
      my $dexlog = Win32::OLE->new('Dexma.Dexlog') or warn "Cannot create DexLog object $!\n";
	  $dexlog->SetProperty('ModuleName','memory_db_update');
      print "\n";
      print "==========================================\n";
      print "Computer: $computer\n";
      print "==========================================\n";

      if (my $objWMIService = Win32::OLE->GetObject("winmgmts:\\\\$computer\\root\\CIMV2")) { #or die "WMI connection failed.\n";

	      my $colItems = $objWMIService->ExecQuery("SELECT TotalPhysicalMemory FROM Win32_LogicalMemoryConfiguration", "WQL", wbemFlagReturnImmediately | wbemFlagForwardOnly);
	
	      my $colItems2 = $objWMIService->ExecQuery("SELECT AvailableMBytes FROM Win32_PerfRawData_PerfOS_Memory", "WQL", wbemFlagReturnImmediately | wbemFlagForwardOnly);
	
	      my $colItems3 = $objWMIService->ExecQuery("SELECT Name, ProcessID, ExecutablePath, WorkingSetSize, PageFileUsage FROM Win32_Process", "WQL", wbemFlagReturnImmediately | wbemFlagForwardOnly);
	
	      my $colItems4 = $objWMIService->ExecQuery("SELECT AllocatedBaseSize FROM Win32_PageFileUsage", "WQL", wbemFlagReturnImmediately | wbemFlagForwardOnly);
	
	      my $colItems5 = $objWMIService->ExecQuery("SELECT CurrentUsage FROM Win32_PageFileUsage", "WQL", wbemFlagReturnImmediately | wbemFlagForwardOnly);
	
	      my $output="\\\\mensa\\Dexma\\Support\\Monitoring\\Memory\\mem_monitor_db_update.txt";
	      
	      my $output2="\\\\mensa\\Dexma\\Support\\Monitoring\\Memory\\mem_monitor_alert.txt";
	
	      unlink $output;
	      unlink $output2;

	         foreach my $objItem (in $colItems) {
	              $TotalPhysMem=$objItem->{TotalPhysicalMemory};
	              $TotalPhysMemMB=$TotalPhysMem / 1024;
	   		}
	         foreach my $objItem (in $colItems2) {
	              $AvailPhysMemMB=$objItem->{AvailableMBytes};
	   		}

	         foreach my $objItem (in $colItems4) {
	             my $VirMem=$objItem->{AllocatedBaseSize};
	             $MemSum = ($MemSum += $VirMem);
	   		}

	         foreach my $objItem (in $colItems5) {
	              my $VirMemInUse=$objItem->{CurrentUsage};
	              $VirMemInUseSum = ($VirMemInUseSum += $VirMemInUse);
	   		}

	      my $PercentPhysMem = ($AvailPhysMemMB) * 100 / $TotalPhysMemMB;
	      my $PercentPhysMemInUse = 100 - $PercentPhysMem;
	      my $PercentVirMem = ($VirMemInUseSum) * 100 / $MemSum;
	      my $PhysMemInUse = ($TotalPhysMemMB) - $AvailPhysMemMB;

	      if ($PhysMemInUse =~ /(\d+)/){
	          chomp($PhysMemInUse = $1);
	      }
	      if ($TotalPhysMemMB =~ /(\d+)/){
	          chomp($TotalPhysMemMB = $1);
	      }
	      if ($VirMemInUseSum =~ /(\d+)/){
	          chomp($VirMemInUseSum = $1);
	      }
	      if ($MemSum =~ /(\d+)/){
	          chomp($MemSum = $1);
	      }
	      if ($PercentPhysMemInUse =~ /(\d+)/){
	          chomp($PercentPhysMemInUse = $1);
	      }
	      if ($PercentVirMem =~ /(\d+)/){
	          chomp($PercentVirMem = $1);
	      }
		  # update rrd
		  #system "$rrdupdate" . "$dir" . "$name" . "N" . ":$PercentPhysMemInUse" . ":$PercentVirMem";
		  $dexlog->Msg("Updating the rrd file for " . $computer . "...\n");
		  $dexlog->Msg("$rrdupdate" . "$dir" . "$name" . "N" . ":$PercentPhysMemInUse" . ":$PercentVirMem" . "\n");
	
		  $SQLStatement = "INSERT INTO Memory_monitor (server, phys_mem_in_use, total_phys_mem, vr_mem_in_use, total_vr_mem, percent_phys_in_use, percent_vr_in_use, last_update) values ('$computer', '$PhysMemInUse', '$TotalPhysMemMB', '$VirMemInUseSum', '$MemSum', '$PercentPhysMemInUse', '$PercentVirMem', getdate())";
	              if ($DSN->Sql($SQLStatement)){
	              print "SQL failed.\n";
	              print "Error: " . $DSN->Error() . "\n";
	              }
	
	      open(OUTPUT, ">>$output") or die "Couldn't open the $output file $!;\n aborting";
	         print OUTPUT "==================================\n";
	         print OUTPUT "Server: $computer\n";
	         print OUTPUT "Physical Memory In Use MB: $PhysMemInUse \n";
	         print OUTPUT "Total Physical Memory MB: $TotalPhysMemMB \n";
	         print OUTPUT "Virtual Memory In Use MB: $VirMemInUseSum \n";
	         print OUTPUT "Total Virtual Memory MB: $MemSum \n";
	         print OUTPUT "Percent Physical Memory Used: $PercentPhysMemInUse\n";
	         print OUTPUT "Percent Virtual Memory Used: $PercentVirMem \n";
	         print OUTPUT "==================================\n";
	
	      print "Physical Memory In Use MB: $PhysMemInUse \n";
	      print "Total Physical Memory MB: $TotalPhysMemMB \n";
	      print "Virtual Memory In Use MB: $VirMemInUseSum \n";
	      print "Total Virtual Memory MB: $MemSum \n";
	      print "Percent Physical Memory Used: $PercentPhysMemInUse \n";
	      print "Percent Virtual Memory Used: $PercentVirMem \n";
	
	      open(OUTPUT2, ">>$output2") or die "Couldn't open the $output2 file $!;\n aborting";        
	      if ($PercentPhysMemInUse > 99 or $PercentVirMem > 85) {
	         print OUTPUT2 "==================================\n";
	         print OUTPUT2 "Server: $computer\n";
	         print OUTPUT2 "Physical Memory In Use MB: $PhysMemInUse \n";
	         print OUTPUT2 "Total Physical Memory MB: $TotalPhysMemMB \n";
	         print OUTPUT2 "Virtual Memory In Use MB: $VirMemInUseSum \n";
	         print OUTPUT2 "Total Virtual Memory MB: $MemSum \n";
	         print OUTPUT2 "Percent Physical Memory Used: $PercentPhysMemInUse \n";
	         print OUTPUT2 "Percent Virtual Memory Used: $PercentVirMem \n";
	         print OUTPUT2 "==================================\n";
	      }
	
	         foreach my $objItem (in $colItems3) {
	
	              my $qualify=$objItem->{WorkingSetSize};
	              my $qualify2=$objItem->{PageFileUsage};
	              my $qualify3=$objItem->{Name};

	              if ($qualify > 299000000 && $qualify2 > 399000000) {
	                 unless ($qualify3=~/sqlservr.exe/ or $qualify3=~/inetinfo/ or $qualify3=~/w3wp.exe/ or $qualify3=~/HNCService.exe/) {
	                 print OUTPUT2 "Server: $computer\n";
	                 my $name=$objItem->{Name};
	                 print OUTPUT2 "Process: $name\n";
	                 my $id=$objItem->{ProcessId};
	                 print OUTPUT2 "ProcessId: $id\n";
	                 my $path=$objItem->{ExecutablePath};
	                 print OUTPUT2 "ExecutablePath: $path\n";
	                 my $var1=$objItem->{WorkingSetSize};
	                 my $phys=$var1 / 1024;
	                 print OUTPUT2 "Physical Memory: $phys KB\n";
	                 my $var2=$objItem->{PageFileUsage};
	                 my $vm=$var2 / 1024;
	                 print OUTPUT2 "Virtual Memory: $vm KB\n";
	                 print OUTPUT2 "==================================\n";
	                 }
	             }
	         }
	}
	else {
		 #log error
         $dexlog->Msg("WMI connection to $computer failed\n");
         print "WMI connection to $computer failed\n";
	}
}

$DSN->Close();
close OUTPUT;
close OUTPUT2;

my $output2="\\\\mensa\\dexma\\support\\monitoring\\memory\\mem_monitor_alert.txt";
my $filesize=(stat $output2)[7];
unless ($filesize==0) {
       system ('e:\dexma\thirdparty\blat.exe e:\dexma\support\monitoring\memory\mem_monitor_alert.txt -to productoperations@primealliancesolutions.com -s "PROD: Server Memory Alert"' or die "$!\n");
}
