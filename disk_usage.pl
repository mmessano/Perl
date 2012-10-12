use strict;
use Win32::OLE('in');
use Win32::ODBC;
use Win32::OLE('in');

use constant wbemFlagReturnImmediately => 0x10;
use constant wbemFlagForwardOnly => 0x20;

my ($PurgeDB, $DSN, $partition, $description, $freespaceBytes, $totalspaceBytes, $SQLStatement, $rrdupdate, $dir, $name);

$rrdupdate = "e:\\Dexma\\support\\Monitoring\\rrdtool.exe update ";
$dir = "e:\\Dexma\\support\\Monitoring\\Diskspace\\";

$DSN = new Win32::ODBC("Status");

$PurgeDB = "DELETE FROM DiskSpace WHERE datediff(d, last_update, getdate())> 90";
         if ($DSN->Sql($PurgeDB)){
              print "SQL failed.\n";
              print "Error: " . $DSN->Error() . "\n";
              }


open (FILE, "<\\\\mensa\\Dexma\\Data\\Diskspace_Monitoring.txt") or die "Couldn't open serverlist.txt: $!; aborting";

my $dexlog = Win32::OLE->new('Dexma.Dexlog') or warn "Cannot create DexLog object $!\n";
$dexlog->SetProperty('ModuleName','disk_usage');

while (<FILE>) {
      my @computers ="$_";
      foreach my $computer (@computers) {
           chomp $computer;
           $name = $computer  . "_diskspace.rrd ";
           $dexlog->Msg("Scanning... $computer");
           print "\n";
           print "==========================================\n";
           print "Computer: $computer\n";
           print "==========================================\n";

           my $output="\\\\mensa\\Dexma\\Support\\Monitoring\\Diskspace\\disk_usage_alert.txt";
           if (my $objWMIService = Win32::OLE->GetObject("winmgmts:\\\\$computer\\root\\CIMV2")) { # or warn $dexlog->Msg("$!; WMI connection to $computer failed");
	           my $colItems = $objWMIService->ExecQuery("SELECT Caption, Description, FreeSpace, Size FROM Win32_LogicalDisk", "WQL", wbemFlagReturnImmediately | wbemFlagForwardOnly);

	           unlink $output;
	
	           foreach my $objItem (in $colItems) {
	                   $partition=$objItem->{Caption};
	                   $description=$objItem->{Description};
	                   $freespaceBytes=$objItem->{FreeSpace};
	                   $totalspaceBytes=$objItem->{Size};
	
		           my $freespace=((($freespaceBytes) / 1024) / 1024) / 1024;
		           my $totalspace=((($totalspaceBytes) / 1024) / 1024) / 1024;
		
		           if ($freespace =~ /(\d+)/){
		                chomp($freespace = $1);
		           }
		           if ($totalspace =~ /(\d+)/){
		                chomp($totalspace = $1);
		           }
		           if ($description =~/Local Fixed Disk/){
		           my $percentused= 100 - (($freespaceBytes) * 100) / $totalspaceBytes;
		           if ($percentused =~ /(\d+)/){
		           chomp($percentused = $1);
		           }
		           open(OUTPUT, ">>$output") or die "Couldn't open the $output file $!;\n aborting";
		           if ($percentused > 95) {
		              print OUTPUT "==================================\n";
		              print OUTPUT "Server: $computer\n";
		              print OUTPUT "Partition: $partition\n";
		              print OUTPUT "Free Space (GB): $freespace\n";
		              print OUTPUT "Total Space (GB): $totalspace\n";
		              print OUTPUT "Percent Diskspace Used: $percentused\n";
		              print OUTPUT "==================================\n";
		           }
					# update rrd, embedded spaces in quotes are required for argument spacing
					my $letter = $1 if $partition =~ /(\w)/;
					system "$rrdupdate" . "$dir" . "$name" . "-t $letter " . "N" . ":$percentused";
					$dexlog->Msg("Updating the rrd file for " . $computer . "...\n");
					$dexlog->Msg("$rrdupdate" . "$dir" . "$name" . "-t $letter " . "N" . ":$percentused". "\n");

		           $SQLStatement = "INSERT INTO DiskSpace (server, partition, description, freespaceGB, totalGB, percentused, last_update) values ('$computer', '$partition', '$description', '$freespace', '$totalspace', '$percentused', getdate())";
		              if ($DSN->Sql($SQLStatement)){
		              print "SQL failed.\n";
		              print "Error: " . $DSN->Error() . "\n";
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
}
$DSN->Close();
close FILE;
close OUTPUT;

my $output="\\\\mensa\\dexma\\support\\monitoring\\diskspace\\disk_usage_alert.txt";
my $filesize=(stat $output)[7];
unless ($filesize==0) {
       system ('e:\dexma\thirdparty\blat.exe e:\dexma\support\monitoring\diskspace\disk_usage_alert.txt -to productoperations@primealliancesolutions.com -s "Low Disk Space Alert"' or die "$!\n");
}


