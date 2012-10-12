#! c:\perl\bin\perl.exe
#---------------------------------------------------
# adsi_ex.pl
#
# Script to demonstrate some of what's available via
#   ADSI classes on NT 4.0
# NOTE: Must install ADSI classes from Microsoft in
#       order to run this script
#
# Usage: adsi_ex.pl
#        Use "perl adsi_pl.exe > file" to capture the
#          output to a file
# NOTE:  Runs on the local machine only.
#
# copyright 2000 by H.Carvey
# email contact: wintermute2k@yahoo.com
#---------------------------------------------------

use strict;
use Win32::OLE;
use Win32::OLE::Enum;

my(@state) = ("",
       "Stopped",
       "Start_Pending",
       "Stop_Pending",
       "Running",
       "Continue_Pending",
       "Pause_Pending",
       "Paused");

my $server = Win32::NodeName;

my $node = Win32::OLE->GetObject("WinNT://$server,computer") ||
 die "Could not connect to $server: ".Win32::FormatMessage
Win32::GetLastError()."\n";

my $obj = Win32::OLE::Enum->new($node);

$node->{Filter} = ["domain"];
foreach ($node) {
 print "Domain:\t$_->{'Name'}\n";
}

$node->{Filter} = ["computer"];
foreach ($node) {
 print "Computer:\t$_->{'Name'}\n";
}

$node->{Filter} = ["group"];
foreach ($node) {
 print "Group:\t$_->{'Name'}\n";
}

foreach ($obj->All) {
 if(lc($_->{'class'}) eq "user") {
  print "$_->{'name'}\t$_->{'description'}\n";
  print "\tLastLogon:  $_->{'lastlogin'}\n";
  print "\tLastLogoff: $_->{'lastlogoff'}\n\n";
 }

 if (lc($_->{'class'}) eq "service") {
  print "$_->{'DisplayName'}\n";
  print "\tAccount:  $_->{'ServiceAccountName'}\n";
  print "\tSrvType:  $_->{'ServiceType'}\n";
  print "\tPath:     $_->{'Path'}\n";
  print "\tStatus:   $state[$_->{'Status'}]\n";
  print "\n\n";
 }
}
