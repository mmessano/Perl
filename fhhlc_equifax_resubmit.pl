#!c:/perl/bin -w
#
# fhhlc_equifax_resubmit.pl
#

use strict;
use diagnostics;
use warnings;
use IO::File;
use Win32::OLE;
use File::Copy;
use File::Basename;
use Time::Localtime;
use Time::Local;
use File::stat;
#use open OUT => ":crlf";
use Date::EzDate;


my ($in_dir, @files, $file, $regex, $count, $out_dir, $error_dir, $logfile, $OUTPUT, $failure_file, $os_string, @file_data, $file_data, $ftime, $wtime, $fstat, $age, $fdiff);

$os_string = "MSWin32";
fileparse_set_fstype($os_string);
$regex = "Sent to Equifax";

$wtime = scalar time;
$age = '240';    # 4 minutes

#$in_dir = "\\\\chiltepe\\C\\RelateProd\\Credit\\docs\\OutstandingOrders\\Equifax\\";
$in_dir = "\\\\Messano338\\inbox\\fhhlc_equifax\\";
#$out_dir = "\\\\chiltepe\\RelateProd\\Credit\\docs\\equifax_resubmit\\";
$out_dir = "\\\\Messano338\\inbox\\fhhlc_equifax_out\\";
$error_dir = "\\\\chiltepe\\E\\Dexma\\Support\\Incident\\";

$logfile = "\\\\chiltepe\\e\\dexma\\logs\\fhhlc_equifax_resubmit.log";
$failure_file = "\\\\xweb1\\dexma\\Support\\FHHLC_Equifax_failure.txt";

opendir DIR, $in_dir or die "Can't open directory $in_dir: $!\n";

# grab file list from directory
@files = (readdir DIR);

foreach $file (@files) {
	# exclude the "." and ".." directories
	unless ($file =~ /^\.+/) {
        chdir $in_dir;
		# get the file modified time in seconds from epoch
		$fstat = stat($file);
		$ftime = scalar $fstat->mtime;
		# get wall time(time of day) in seconds from epoch
		$wtime = scalar time;
		$fdiff = $wtime - $ftime;
#		print "File age difference in seconds: $fdiff\n";
		# if file is not old enough, don't bother opening it
		if ($fdiff > $age) {
			$count = "0";
	        open (FILE, "< $file") or die "Can't open file $file: $!\n";
#			@file_data = <FILE>;
			print "Post open\n";
			# count occurences of regex pattern
			while (<FILE>) {
#				 print "counting regex\n";
				 if ($_ =~ /$regex/) {
					$count++;
	   			 }
			}
			@file_data = <FILE>;
			# brute force change the linefeed back to carriage-return linefeed
			foreach my $line (@file_data) {
				$line =~ s/\n/\r\n/g;
#				print "Changing linefeeds\n";
				}
			$OUTPUT = IO::File->new($logfile, ">>\n") or warn "Cannot open $logfile! $!\n";
			if ($count < 5) {
				my $diff = (5 - $count);
				print $OUTPUT "$file has been submitted $count times of 5 with $diff remaining.\n\n";
				opendir DIR, $out_dir or die "Can't open directory $out_dir: $!\n";
				copy("$file","$out_dir$file") or die "Copy failed: $!\n";  # keep a copy just in case
				my $f2q = Win32::OLE->new('Queue.Queue.1') or die "Cannot create Queue.Queue object $!\n";
				my ($name,$path, $type) = fileparse($file,qr{\.xml});
				# local MSMQ network
				$f2q->SendLabelDataToQueue("messano338","temp",$name,"@file_data");
				#$f2q->SendDataToQueue("messano338","temp",$name,@file_data);
				# remote MSMQ network
				#$f2q->SendLabelDataToQueueDirect("chiltepe","routecrrequest",$name,$file,1);
				#print "@file_data\n";
			}
			else
			{
				# write errors to the logfile
				print $OUTPUT "Order $file has been submitted to Equifax $count times with no successful response.  Moving to error folder $error_dir$file\n\n";
	            # blat the failure notification
				system ("c:\\dexma\\bin\\blat.exe $failure_file -t mmessano\@primealliancesolutions.com -subject \"FHHLC Resubmit: moved $file to $error_dir$file.\" " or die "$!\n");
#				chdir $in_dir;
				close FILE;
				move("$file","$error_dir$file") or warn "move failed: $!\n";
#				unlink ("$file");
			}
			close $OUTPUT;
			close FILE;
		}
		else
		{
			print "$file is to young to resubmit, ignoring for now.\n";
		}
	}
}
