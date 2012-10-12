# WMI-Generic.pl
# List all the available WMI properties for a various WMI Class on a remote or local box
# Version 1.0
# Tested on W2K and AS630 (with clients using W2K and NT4)

# Dumps a lot of information similar to the WMI SDK Utility, WBEMDUMP
#    If you were to run the command WBEMDUMP /M2 \\COMPUTER\root\CIMV2 Win32_Classname
#      *Where:
#         -COMPUTER is a valid computer, and
#         -Win32_Classname is a valid calss name

# Valid Classnames can be found in the WMI SDK
# Class names can also found at:
#      http://msdn.microsoft.com/library/default.asp?url=/library/en-us/wmisdk/r_32hard1_3d4j.asp
#      *Last checked the above URL on 2002/03/22
#      http://msdn.microsoft.com/library/default.asp?url=/library/en-us/wmisdk/wmi/wmi_classes.asp
#      *added 7/26/2004 mmessano
# Download the WMI Software Development Kit from:
#      http://msdn.microsoft.com/downloads/default.asp?URL=/code/sample.asp?url=/msdn-files/027/001/566/msdncompositedoc.xml
#      *Last checked the above URL on 2002/03/22
#
# Here's a list of a few Helpful classes to get you started.
# Win32_ComputerSystem
# Win32_Processor
# Win32_TapeDrive
# Win32_TimeZone

# Last note.  If a class has a property that your computer doesn't show a value for, it
# isn't necessarily a problem with the script, OLE or WMI, but that the property isn't/wasn't
# populated in WMI for some reason

use Win32;
use Win32::OLE qw (in);

$x=0;

# syntax:
# perl wmi-generic.pl computername Win32_TapeDrive
#     *Note: This may not return any information due
#            to the system you are querying not having a tape drive!
#     *Where the following command should return information (and for both systems)
# perl wmi-generic.pl computername Win32_ComputerSystem computername2 Win32_Processor
#     *And lastly, the asterisk can be used when looking for local computer information
# perl wmi-generic.pl * Win32_ComputerSystem computername2 Win32_Processor

foreach $item (@ARGV) {
  $x++;
  if ($x == 1) {
    if ($item eq "*") {
      $name = Win32::NodeName();
    } else {
      $name = $item;
    }
  } elsif ($x == 2) {
    WMI($name,$item);
    $x=0;
  }
}
sub WMI {
  my $Computername = $_[0];
  my $Win32_Class = $_[1];
  my $Class = "WinMgmts://$Computername";
  my $Wmi = Win32::OLE->GetObject ($Class);
  print "$Computername ($Win32_Class)-> ";
  if ($Wmi) {
    my $Computers = $Wmi->ExecQuery("SELECT * FROM $Win32_Class");
    if (scalar(in($Computers)) lt "1") {
      print "\n    Check the computer and class name.\n";
      print   "    No information was found on the specified class!\n";
      return 0;
    }
    print "$Computername\n";
    foreach my $pc (in ($Computers)) {
        properties($pc);
    }
  } else {
    print "Unable to talk to WMI (Maybe I should ping this box instead of assuming it is alive? :)   )\n";
  }
}

sub properties {
  my $node = $_[0];
  foreach my $object (in $node->{Properties_}) {
    if (ref($object->{Value}) eq "ARRAY") {
      print "  $object->{Name} = { ";
      foreach my $value (in($object->{Value}) ) {
        print "$value ";

      }
      print "}\n";
    } else {
      print "  $object->{Name} = $object->{Value}\n";
    }
  }
  print "----------------------------------\n";
}
