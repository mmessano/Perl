#!c:/perl/bin -w

my ($pattern, @server, $server, $list, $filesize, $filesizenew, $output, $output2, $file, $dir, $time);

use strict;
use warnings;

$time= scalar(localtime);

#$pattern= "Timeout expired";
$pattern= 'Fail: Message:\n';

open (LIST, "<\\\\mensa\\dexma\\support\\monitoring\\process\\loan_wiz_serverlist.txt") or die "Couldn't open loan_wiz_serverlist.txt: $!; aborting";
while (<LIST>) {
                 print "$_";
                 @server="$_";
                 foreach $server (@server) {
                         chomp $server;

                         $output="\\\\messano338\\dexma\\support\\monitoring\\process\\$server\_timeout_count.txt";
                         $filesize=(stat $output)[7];
                         unlink $output;
                         $output2="\\\\messano338\\dexma\\support\\monitoring\\process\\$server\_timeout_count.txt";

                         open(OUTPUT2, ">$output2") or die "Couldn't open the $output2 file $!;\n aborting";
                         $dir = "\\\\$server\\dexma\\logs";

                         opendir DIR, $dir or die "Can't open directory $dir: $!\n";
                         chdir "$dir";
                         while ($file= readdir DIR) {
	                       if ($file=~/LoanWizardManagement/) {
                                   open (FILE, $file) or die "couldn't open $file: $!; aborting";
                                   while (<FILE>) {
                                         if ($_ =~ /$pattern/ ) {
                                         print OUTPUT2 "Error:\n$dir\\$file\n$_\n";
                                         }
                                  }
                                }
		        }
	                 close OUTPUT2;
                         $filesizenew=(stat $output2)[7];
                         print "$server new size $filesizenew\n";
                         print "$server old size $filesize\n";
                         if ($filesize < $filesizenew) {
                         system ("e:\\dexma\\Thirdparty\\blat.exe \\\\mensa\\dexma\\support\\monitoring\\process\\$server\_timeout_count.txt -to mmessano\@primealliancesolutions.com -s \"Web Services: Loan Wizard Timeout - $server\""or die "$!\n");
                         }
                }
}

