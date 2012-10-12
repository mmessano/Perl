#!c:/perl/bin -w
#
# for_loops.pl
#

use strict;
use diagnostics;
use warnings;
use Date::EzDate;
use Win32::ODBC;
use Win32::OLE('in');

my ( $startdate, $startdate2, $startdate3, $mydate );
my ( $i, $g, $j, $k, $days, $startdate2_format, $startdate3_format );


# suppress errors on connection failure(console only, error will be logged)
Win32::OLE->Option(Warn => 0);

# set previous number of days to import
$days = 4;

$mydate = Date::EzDate->new();
$startdate = Date::EzDate->new() - $days;
$startdate2 = Date::EzDate->new() - $days;
$startdate3 = Date::EzDate->new() - $days;
$startdate2_format = "$startdate2->{'%Y%m%d'}";
$startdate3_format = "$startdate2->{'%Y/%m/%d'}";


print "Count backward...\n";
for ( $i = 0; $i <= $days; $i++ ) {
	print $i . " Days ago is " . $mydate . "\n";
	$mydate--;
}
print "\n\n";
print "Count forward, counter not useful as position...\n";
for ( $g = 0; $days >= $g; $g++ ) {
	print "The dates to import are " . $startdate . ", the counter value is " . $g . "\n";
	$startdate++;
}
print "\n\n";
print "Count forward using final date format with a useful counter as position...\n";
for ( $j = $days; $j >= 1; $j-- ) {
	print $j . " Day(s) ago is " . $startdate2_format . "\n";
	$startdate2_format++;
}
print "\n\n";
print "Count forward using date object with a useful counter as position...\n";
print "Rewrite final date form as needed...\n";
for ( $k = $days; $k >= 1; $k-- ) {
	print $k . " Day(s) ago is " . $startdate3->{'%Y/%m/%d'} . "\t" . $startdate3->{'%Y%m%d'} . "\t" . $startdate3->{'%m/%d/%Y'} . "\n";
	#print $k . " Day(s) ago is " . $startdate3->{'%Y%m%d'} . "\n";
	$startdate3++;
}
