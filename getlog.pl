# getlog.pl
#
# Author: Paul Simmonson
#
# Input: filename of Windows 2000 Performance monitor log file (must be CSV format)
# Name of log item to extract
# eg. perl getlog-fixed.pl c:\perflogs\K6.csv "\\K6\LogicalDisk(C:)\% Disk Time"
# Output: mrtg data format
#
$STUFF=@ARGV[0];
open STUFF or die "Cannot open $STUFF for read :$!";
@entries = <STUFF>;
@details=split /,/, @entries[0]; #get the first line of the log file
@lastline=split /,/, @entries[$#entries]; #get last line of log file

#find the entry that matches $ARGV[1]
$index=-1;
for $entry (@details) {
    $index++;
    $entry=~ tr/"//d;
    chomp ($entry);
    $last=$entry;
    last if $entry eq $ARGV[1];
}

if ($last eq $ARGV[1]) {
    $data=@lastline[$index];
    $data=~ tr/"//d;
    $data = int($data+0.5);
} else {
    $data = 0;
}
print "0\n";
print "$data\n";
print "0\n";
print "0\n";
