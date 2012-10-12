my ($AvailPhysMemMB, $TotalPhysMem, $AvailVirMem, $TotalVirMem, $TotalPhysMemMB, $AvailVirMemMB, $TotalVirMem, $PercentPhysMem, $PercentVirMem, $MemSum, $VirMemInUseSum);

use strict;
use Win32::OLE('in');

use constant wbemFlagReturnImmediately => 0x10;
use constant wbemFlagForwardOnly => 0x20;

open (FILE, "<\\\\mensa\\Dexma\\Support\\Monitoring\\Memory\\serverlist.txt") or die "Couldn't open serverlist.txt: $!; aborting";

while (<FILE>) {
      my @computers ="$_";
      $MemSum = 0;
      $VirMemInUseSum = 0;
      foreach my $computer (@computers) {
      chomp $computer;
      print "\n";
      print "==========================================\n";
      print "Computer: $computer\n";
      print "==========================================\n";

      my $objWMIService = Win32::OLE->GetObject("winmgmts:\\\\$computer\\root\\CIMV2") or die "WMI connection failed.\n";

      my $colItems = $objWMIService->ExecQuery("SELECT TotalPhysicalMemory FROM Win32_LogicalMemoryConfiguration", "WQL", wbemFlagReturnImmediately | wbemFlagForwardOnly);

      my $colItems2 = $objWMIService->ExecQuery("SELECT AvailableMBytes FROM Win32_PerfRawData_PerfOS_Memory", "WQL", wbemFlagReturnImmediately | wbemFlagForwardOnly);

      my $colItems3 = $objWMIService->ExecQuery("SELECT Name, ProcessID, ExecutablePath, WorkingSetSize, PageFileUsage FROM Win32_Process", "WQL", wbemFlagReturnImmediately | wbemFlagForwardOnly);

      my $colItems4 = $objWMIService->ExecQuery("SELECT AllocatedBaseSize FROM Win32_PageFileUsage", "WQL", wbemFlagReturnImmediately | wbemFlagForwardOnly);

      my $colItems5 = $objWMIService->ExecQuery("SELECT CurrentUsage FROM Win32_PageFileUsage", "WQL", wbemFlagReturnImmediately | wbemFlagForwardOnly);


      my $output="\\\\mensa\\Dexma\\Support\\Monitoring\\Memory\\mem_monitor.txt";
      unlink $output;

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
      my $PercentVirMem = ($VirMemInUseSum) * 100 / $MemSum;

      open(OUTPUT, ">>$output") or die "Couldn't open the $output file $!;\n aborting";
      if ($PercentPhysMem < 1 or $PercentVirMem > 80) {
         print OUTPUT "==================================\n";
         print OUTPUT "Server: $computer\n";
         print OUTPUT "Available Physical Memory MB: $AvailPhysMemMB \n";
         print OUTPUT "Total Physical Memory MB: $TotalPhysMemMB \n";
         print OUTPUT "Virtual Memory In Use MB: $VirMemInUseSum \n";
         print OUTPUT "Total Virtual Memory MB: $MemSum \n";
         print OUTPUT "Percent Physical Memory Free: $PercentPhysMem \n";
         print OUTPUT "Percent Virtual Memory Used: $PercentVirMem \n";
         print OUTPUT "==================================\n";
      }

         foreach my $objItem (in $colItems3) {

              my $qualify=$objItem->{WorkingSetSize};
              my $qualify2=$objItem->{PageFileUsage};
              my $qualify3=$objItem->{Name};
              
              if ($qualify > 299000000 && $qualify2 > 399000000) {
                 unless ($qualify3=~/sqlservr.exe/ or $qualify3=~/inetinfo/ or $qualify3=~/w3wp.exe/) {
                 print OUTPUT "Server: $computer\n";
                 my $name=$objItem->{Name};
                 print OUTPUT "Process: $name\n";
                 my $id=$objItem->{ProcessId};
                 print OUTPUT "ProcessId: $id\n";
                 my $path=$objItem->{ExecutablePath};
                 print OUTPUT "ExecutablePath: $path\n";
                 my $var1=$objItem->{WorkingSetSize};
                 my $phys=$var1 / 1024;
                 print OUTPUT "Physical Memory: $phys KB\n";
                 my $var2=$objItem->{PageFileUsage};
                 my $vm=$var2 / 1024;
                 print OUTPUT "Virtual Memory: $vm KB\n";
                 print OUTPUT "==================================\n";
                 }
             }
         }

      print "Available Physical Memory MB: $AvailPhysMemMB \n";
      print "Total Physical Memory MB: $TotalPhysMemMB \n";
      print "Virtual Memory In Use MB: $VirMemInUseSum \n";
      print "Total Virtual Memory MB: $MemSum \n";
      print "Percent Physical Memory Free: $PercentPhysMem \n";
      print "Percent Virtual Memory Used: $PercentVirMem \n";

      }
}
close FILE;
close OUTPUT;

my $output="\\\\mensa\\dexma\\support\\monitoring\\memory\\mem_monitor.txt";
my $filesize=(stat $output)[7];
unless ($filesize==0) {
       system ('e:\dexma\thirdparty\blat.exe e:\dexma\support\monitoring\memory\mem_monitor.txt -to productoperations@primealliancesolutions.com -s "PROD: Server Memory Alert"' or die "$!\n");
}
