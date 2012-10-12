#!c:/perl/bin -w
#
# dcom_settings.pl
#
# usage: dcom_progids.pl <machine_name>

use strict;
use diagnostics;
use warnings;

use Win32::OLE('in');
use constant wbemFlagReturnImmediately => 0x10;
use constant wbemFlagForwardOnly => 0x20;

my ($computer, $objWMIService, $colItems);

$computer = shift;
$objWMIService = Win32::OLE->GetObject
    ("winmgmts:\\\\$computer\\root\\CIMV2") or die "WMI connection failed.\n";
$colItems = $objWMIService->ExecQuery
    ("SELECT * FROM Win32_ProgIDSpecification","WQL",wbemFlagReturnImmediately | wbemFlagForwardOnly);

foreach my $objItem (in $colItems)
{
      print "Caption: $objItem->{Caption}\n";
      print "Check ID: $objItem->{CheckID}\n";
      print "Check Mode: $objItem->{CheckMode}\n";
      print "Description: $objItem->{Description}\n";
      print "Name: $objItem->{Name}\n";
      print "Parent: $objItem->{Parent}\n";
      print "Prog ID: $objItem->{ProgID}\n";
      print "Software Element ID: $objItem->{SoftwareElementID}\n";
      print "Software Element State: $objItem->{SoftwareElementState}\n";
      print "Target Operating System: $objItem->{TargetOperatingSystem}\n";
      print "Version: $objItem->{Version}\n";
      print "\n";
}
