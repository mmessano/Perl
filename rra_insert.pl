#!/usr/bin/perl -w
#
# rra_insert.pl
#

# $oldxmlfile="cpu_pool_idle.xml";
# $oldrrdfile="cpu_pool_idle.rrd";
# $newrrdfile="cpu_pool_idle_new.rrd";
# $newxmlfile="cpu_pool_idle_new.xml";

$oldxmlfile="pkts_in.xml";
$oldrrdfile="pkts_in.rrd";
$newrrdfile="pkts_in_new.rrd";
$newxmlfile="pkts_in_new.xml";

$appendxmlfile="append.xml";

system("rrdtool dump $oldrrdfile > $oldxmlfile");

open OLDXML, ("< $oldxmlfile");
open NEWXML, ("> $newxmlfile");
open APPENDXML, ("< $appendxmlfile");

my(@oldxml) = <OLDXML>; # read file into list
my(@appxml) = <APPENDXML>;

for (@oldxml) {
  if (! /<\/rrd\>/) {
      print NEWXML $_;
   } else {
      for $appline (@appxml) {
          print NEWXML $appline;
      }
      print NEWXML $_;
      last;
   }
}

close (OLDXML);
close (NEWXML);
close (APPLENDXML);

system("rrdtool restore $newxmlfile $newrrdfile");

# Fix ownership and perms
system("chown nobody.system $newrrdfile");
system("chmod 666 $newrrdfile");

system("/etc/rc.d/init.d/gmetad stop");
system("cp -p $oldrrdfile $oldrrdfile.orig");
system("cp -p $newrrdfile $oldrrdfile");
system("/etc/rc.d/init.d/gmetad start");