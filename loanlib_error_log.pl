#!c:/perl/bin -w

my ($pattern, @server, $server, $list, $output, $file, $dir, $time, $mydate, $kleep);

use strict;
use warnings;
use Date::EzDate;
use File::Copy;
$mydate = Date::EzDate->new();

$kleep="$mydate->{'%m-%d-%Y'}";
$time= scalar(localtime);
#$pattern= "Error string";
$output="\\\\mensa\\dexma\\support\\monitoring\\process\\loanlib_errors.txt";
unlink $output;

print "Current date: " . $mydate . "\n\n";
print "Scalar Date: " . $time . "\n";

open (LIST, "<\\\\mensa\\dexma\\support\\monitoring\\process\\loanlib_serverlist.txt") or die "Couldn't open loanlib_serverlist.txt: $!; aborting";
while (<LIST>) {
                 print "$_";
                 @server="$_";
                 foreach $server (@server) {
                        chomp $server;

                        open(OUTPUT, ">>$output") or die "Couldn't open the $output file $!;\n aborting";
                        $dir = "\\\\$server\\dexma\\logs";

                         opendir DIR, $dir or die "Can't open directory $dir: $!\n";
                         chdir "$dir";
                         while ($file= readdir DIR) {
	                       if ($file=~/^DexLoanLib.*\.txt/) {
								  my $file2 = ">>Processed_" . $file;
                                  open (FILE2, $file2) or warn "Unable to open backup file for writing!\n";
                                  open (FILE, $file) or warn "couldn't open $file: $!; aborting";
                                  print "\n$dir\\$file\n";

                                  &puppet;
                                   
                                   sub puppet
                                   {
                                   while (<FILE>) {
                                         print FILE2 "$_\n";
										 if ($_ =~/Not enough storage is available/) {
                                         print OUTPUT "Error Detected:\n" . $dir . "\\" . $file . "\n\n";
										 close FILE;
                                               }
                                         }
                                   close FILE;
								   close FILE2;
                                   }   #end sub loop
                                unlink $file;
                                }
		        }
                }
}

close OUTPUT;
my $output2="\\\\mensa\\dexma\\support\\monitoring\\process\\loanlib_errors.txt";
my $filesize=(stat $output2)[7];
unless ($filesize==0) {
        system ("e:\\dexma\\Thirdparty\\blat.exe \\\\mensa\\dexma\\support\\monitoring\\process\\loanlib_errors.txt -to outage\@primealliancesolutions.com -s \"LoanLib Memory Errors Detected\""or die "$!\n");
        }

