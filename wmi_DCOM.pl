#!c:/perl/bin -w
#
# dcom_settings.pl
#
# usage: dcom_settings.pl <machine_name>

use strict;
use diagnostics;
use warnings;
use Win32::OLE;

my ($computer, $objWMIService, $colItems, %dcomsettings);

%dcomsettings = (AppID=>'',
			  	 AuthenticationLevel=>'',
				 Caption=>'',
				 Description=>'',
				 InstallDate=>'',
				 Name=>'',
				 Status=>'');


$computer = shift;
$objWMIService = Win32::OLE->GetObject
    ("winmgmts:\\\\$computer\\root\\CIMV2") or die "WMI connection failed.\n";
$colItems = $objWMIService->ExecQuery
    ("Select * from Win32_DCOMApplicationSetting");

foreach my $objItem (in $colItems)
{
      print "App ID: $objItem->{AppID}\n";
      print "AuthenticationLevel: $objItem->{AuthenticationLevel}\n";
      print "Caption: $objItem->{Caption}\n";
      print "Description: $objItem->{Description}\n";
      print "Install Date: $objItem->{InstallDate}\n";
      print "Name: $objItem->{Name}\n";
      print "Status: $objItem->{Status}\n";
      print "\n";
}
