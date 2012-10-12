#!c:/perl/bin -w
#
# enum_scheduled_tasks2.pl
#

use strict;
use diagnostics;
use warnings;
use Win32::NetAdmin;
use Win32::ODBC;
use Win32::TaskScheduler;


my ( $infile, @jobs, $scheduler, @machines, $server, @domains, $domain, $pdc, $runtime );
my ( $DSN, $SQL_ins, $ErrNum, $ErrText, $ErrConn, %SQL_Errors );
my ( $total_jobs, $total_jobs_per_server );
my ( $ms, $sec, $min, $hour, $day, $dayofweek, $month, $year );

@domains = ('home_office','ft_commhub','dexma');

$DSN = new Win32::ODBC("status") or die "Error: " . Win32::ODBC::Error();

# Trailing space is necessary!
# @server_name varchar(50), @account varchar(64), @app_name varchar(64), @working_dir varchar(64), @comment varchar(64), @creator varchar(64), @trigger_string varchar(64)
$SQL_ins = "exec sp_ins_sched_task ";
%SQL_Errors = (server=>'', file=>'', name=>'', SQLState=>'', Number=>'', Text=>'');


#print "Account\tName\tWork Dir\tComment\tCreator\tTrigger String\n";

# purge the table
#$DSN->Sql("truncate table t_sched_task");

# count totals for testing
$total_jobs = 0;
$total_jobs_per_server = 0;

foreach $domain (@domains) {
	unless (Win32::NetAdmin::GetDomainController("", $domain, $pdc)) {warn "Unable to determine/access PDC($pdc) for $domain.";}
	unless (Win32::NetAdmin::GetServers($pdc, $domain, SV_TYPE_NT, \@machines)) {print "Unable to read anything.";}
	foreach $server ( @machines ) {
		chomp $server;
		&enum_jobs($server);

	}
}
#print "There are $total_jobs running on the network.\n";
#print "There are $total_jobs_per_server running on the network, adding server-by-server.\n";

sub enum_jobs {
	my $machine = shift;
	chomp $machine;
	my $unc = "\\\\" . $machine;
	$scheduler = Win32::TaskScheduler->New();
	if ( $scheduler->SetTargetComputer($unc) ) {
		my @jobs = $scheduler->Enum();
		my $count = @jobs;
		print "Job count for " . $machine . " is " . $count . "\n";
        $total_jobs_per_server = $total_jobs_per_server + $count;
		foreach my $job ( @jobs ) {
			$scheduler->Activate($job);
			$total_jobs++;
			print $scheduler->GetAccountInformation() . "\t" . $scheduler->GetApplicationName() . "\t" . $scheduler->GetWorkingDirectory() . "\t" . $scheduler->GetComment() . "\t" . $scheduler->GetCreator() . "\t" . $scheduler->GetTriggerString(0) . "\n";
			( $ms, $sec, $min, $hour, $day, $dayofweek, $month, $year ) = $scheduler->GetMostRecentRunTime();
			print "      HR:MN:SEC:MS	DAY, Weekday, Month, Year\n";
			print "Time: $hour:$min:$sec, $day/$month/$year\n";
			$runtime = $hour . ":" . $min . ":" . $sec . " " . $day . "/" . $month . "/" . $year;
			print "Status: " . $scheduler->GetStatus($job) . "\n";
			print "Exit Code: " . $scheduler->GetExitCode($job) . "\n";
#            if ($DSN->Sql($SQL_ins . "'" . $machine . "'" . "," . "'" . $scheduler->GetAccountInformation() . "'" . "," . "'" . $scheduler->GetApplicationName() . "'"  . "," . "'" . $scheduler->GetWorkingDirectory() . "'"  . "," . "'" .  $scheduler->GetComment()  . "'"  . "," . "'" . $scheduler->GetCreator()  . "'"  . "," . "'" . $scheduler->GetTriggerString(0) . "'"  . "," . "'" . $hour:$min:$sec $day/$month/$year  . "'"))
#                        {
#						($ErrNum, $ErrText, $ErrConn) = $DSN->Error();
#						print  "Machine: $machine\n";
#						print  "SQL error: $ErrConn\n";
#						print  "ErrorNum: $ErrNum\n";
#						print  "Text: $ErrText\n\n";
#	                  }

		}
	}
	else
	{
	print "Connection to $unc failed! (" .  $! . ")\n";
	}
}