#!c:/perl/bin -w
#
# time_retrieve.pl
#

use strict;
use diagnostics;
use warnings;
use Win32::OLE('in');
use Date::EzDate;
use Time::Local;

use constant wbemFlagReturnImmediately => 0x10;
use constant wbemFlagForwardOnly => 0x20;

my ( $sys_time );

#my @computers = ("STGAPP811","STGAPP813","STGCON610","STGCON611","STGCON612","STGSQL611","STGWEBMET510");
my @computers = ("PSQLSVC21","PSQLDLS30");
foreach my $computer (@computers) {
   print "\n";
   print "==========================================\n";
   print "Computer: $computer\n";
   print "==========================================\n";

   my $objWMIService = Win32::OLE->GetObject("winmgmts:\\\\$computer\\root\\CIMV2") or die "WMI connection failed.\n";
   my $colItems = $objWMIService->ExecQuery("SELECT * FROM Win32_OperatingSystem", "WQL",
                  wbemFlagReturnImmediately | wbemFlagForwardOnly);

   foreach my $objItem (in $colItems) {
      $sys_time = Date::EzDate->new(utc2seconds($objItem->{LocalDateTime}));
      $sys_time->set_format('my_format', '{weekday short} {month short} {day of month} {year} {hour}:{min}:{sec}');
	  print "LocalDateTime: $sys_time->{'my_format'}\n";
      print "\n";
   }
}


#my $seconds = utc2seconds(200407221405000);
sub utc2seconds {
	my $utc = shift @_;
	my $YYYY = substr($utc,0,4);
	my $MM = substr($utc,4,2);
	my $DD = substr($utc,6,2);
	my $hh = substr($utc,8,2);
	my $mm = substr($utc,10,2);
	my $ss = substr($utc,12,2);
	# off-by-one error in months portion, kludgey fix is to subtract 1
	return timelocal($ss,$mm,$hh,$DD,($MM-1),$YYYY);
}