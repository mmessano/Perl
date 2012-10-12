#!c:/perl/bin -w
#
# dcom_settings.pl
#
# usage: dcom_settings.pl <machine_name>

use strict;
use diagnostics;
use warnings;

use Win32::OLE('in');
use constant wbemFlagReturnImmediately => 0x10;
use constant wbemFlagForwardOnly => 0x20;

my ($computer, $objWMIService, $colItems, %dcomsettings, $dcomsettings, @dexnames);

%dcomsettings = (AppID=>'',
			  	 AuthenticationLevel=>'',
				 Caption=>'',
				 Description=>'',
				 InstallDate=>'',
				 Name=>'',
				 Status=>'');


@dexnames = ('DexFileImpExp','DexODIPostprocessor','DexAdvCommServer','DexProcessController');

$computer = shift;
$objWMIService = Win32::OLE->GetObject
    ("winmgmts:\\\\$computer\\root\\CIMV2") or die "WMI connection failed.\n";
@colItems = $objWMIService->ExecQuery
#    ("SELECT * FROM Win32_DCOMApplicationSetting","WQL",wbemFlagReturnImmediately | wbemFlagForwardOnly);
    ("SELECT * FROM Win32_DCOMApplicationSetting WHERE Caption LIKE 'Dex%'","WQL",wbemFlagReturnImmediately | wbemFlagForwardOnly);
foreach my $objItem (in @colItems)
{
	  print "App ID: $objItem->{AppID}\n";
      $dcomsettings->{AppID}= $objItem->{AppID};
      print "AuthenticationLevel: $objItem->{AuthenticationLevel}\n";
      $dcomsettings->{AuthenticationLevel}= $objItem->{AuthenticationLevel};
      print "Caption: $objItem->{Caption}\n";
      $dcomsettings->{Caption}= $objItem->{Caption};
      print "CustomSurrogate: $objItem->{CustomSurrogate}\n";
      $dcomsettings->{CustomSurrogate}= $objItem->{CustomSurrogate};
	  print "Description: $objItem->{Description}\n";
	  $dcomsettings->{Description}= $objItem->{Description};
      print "EnableAtStorageActivation: $objItem->{EnableAtStorageActivation}\n";
      $dcomsettings->{EnableAtStorageActivation}= $objItem->{EnableAtStorageActivation};
      print "LocalService: $objItem->{LocalService}\n";
      $dcomsettings->{LocalService}= $objItem->{LocalService};
      print "RemoteServerName: $objItem->{RemoteServerName}\n";
      $dcomsettings->{RemoteServerName}= $objItem->{RemoteServerName};
      print "RunAsUser: $objItem->{RunAsUser}\n";
      $dcomsettings->{RunAsUser}= $objItem->{RunAsUser};
      print "ServiceParameters: $objItem->{ServiceParameters}\n";
      $dcomsettings->{ServiceParameters}= $objItem->{ServiceParameters};
      print "SettingID: $objItem->{SettingID}\n";
      $dcomsettings->{SettingID}= $objItem->{SettingID};
      print "UseSurrogate: $objItem->{UseSurrogate}\n";
      $dcomsettings->{UseSurrogate}= $objItem->{UseSurrogate};
	  print "\n";
}


#Single quote in WQL works fine on Windows 2000, it is the "like"
#statement in the ExecQuery that is not supported in Win2k, it was
#introduced in WinXP (and Microsoft is not going to backport it to
#Win2k).

#Here is a rewritten version of your script that will work on both
#Windows 2000 and XP/2003:

#strComputer = "."
#Set objWMIService = GetObject("winmgmts:" _
#& "\\" & strComputer & "\root\cimv2")

#Set colItems = objWMIService.ExecQuery _
#3("Select * from win32_service")

#For Each objItem in colItems
#If LCase(Left(objItem.name, 2)) = "bi" Then
#Wscript.Echo objItem.caption
#End If
#Next
