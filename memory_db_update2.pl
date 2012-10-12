#!c:/perl/bin -w
#
# memory_db_update2.pl
#

use strict;
use Win32::OLE('in');
use Win32::ODBC;


my ($AvailPhysMemMB, $TotalPhysMem, $AvailVirMem, $TotalVirMem, $TotalPhysMemMB, $AvailVirMemMB, $PercentPhysMem, $PercentVirMem, $MemSum, $VirMemInUseSum, $SQLStatement, $DSN, $rrdupdate, $name, $dir);

use constant wbemFlagReturnImmediately => 0x10;
use constant wbemFlagForwardOnly => 0x20;

$rrdupdate = "C:\\Dexma\\support\\Monitoring\\rrdtool.exe update ";
#$dir = "C:\\Dexma\\support\\Monitoring\\rrd\\memory\\";
$dir = "\\\\xopsmonitor2\\Dexma\\Support\\Monitoring\\rrd\\memory\\";

$DSN = new Win32::ODBC("perltest");

open (FILE, "<\\\\mensa\\Dexma\\Support\\Monitoring\\Memory\\serverlist_mjm.txt") or die "Couldn't open serverlist.txt: $!; aborting";

while (<FILE>) {
      my @computers ="$_";
      $MemSum = 0;
      $VirMemInUseSum = 0;
      foreach my $computer (@computers) {
      chomp $computer;
      $name = $computer  . "_mem.rrd ";
      print "\n";
      print "==========================================\n";
      print "Computer: $computer\n";
      print "==========================================\n";

      my $objWMIService = Win32::OLE->GetObject("winmgmts:\\\\$computer\\root\\CIMV2") or die "WMI connection failed.\n";

      my $colItems = $objWMIService->ExecQuery("SELECT TotalPhysicalMemory FROM Win32_LogicalMemoryConfiguration", "WQL", wbemFlagReturnImmediately | wbemFlagForwardOnly);

      my $colItems2 = $objWMIService->ExecQuery("SELECT AvailableMBytes FROM Win32_PerfRawData_PerfOS_Memory", "WQL", wbemFlagReturnImmediately | wbemFlagForwardOnly);

      my $colItems4 = $objWMIService->ExecQuery("SELECT AllocatedBaseSize FROM Win32_PageFileUsage", "WQL", wbemFlagReturnImmediately | wbemFlagForwardOnly);

      my $colItems5 = $objWMIService->ExecQuery("SELECT CurrentUsage FROM Win32_PageFileUsage", "WQL", wbemFlagReturnImmediately | wbemFlagForwardOnly);

      my $output="\\\\mensa\\Dexma\\Support\\Monitoring\\Memory\\mem_monitor_db_update2.txt";
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
	  system "$rrdupdate" . "$dir" . "$name" . "N" . ":$PercentPhysMemInUse" . ":$PercentVirMem";
	  print "Updating the rrd file for " . $computer . "...\n";
	  print "$rrdupdate" . "$dir" . "$name" . "N" . ":$PercentPhysMemInUse" . ":$PercentVirMem" . "\n";
	  
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

      }
}
$DSN->Close();
close FILE;
close OUTPUT;
