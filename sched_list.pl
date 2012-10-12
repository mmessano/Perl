#!c:/perl/bin -w
#
#
# sched_list.pl
#

#  ppm install http://taskscheduler.sourceforge.net/perl58/Win32-TaskScheduler.ppd

use strict;
use Win32::TaskScheduler;

(my $Machine = shift @ARGV || "" ) =~ s/^[\\\/]+//;

my $scheduler;
my @jobs;
my $job;
my $jobname;
my $account;
my $APname;
my $parameter;
my $workdir;
my $triggerCnt;
my $idx;
my %trigger;
my $key;
my $trigType;
my $flags;
my $status;
my $exitcode;

$scheduler = Win32::TaskScheduler->New();
if ( $Machine ) {
	$scheduler->SetTargetComputer("\\\\".$Machine) or die("Failed: Set Server Machine:".$Machine."\n");
}
@jobs = $scheduler->Enum();
foreach $job ( @jobs ) {
	$jobname = substr($job,0,length($job)-4);
	$scheduler->Activate($jobname) or die("Failed: Activate".$job." [".$jobname."]\n");
	print "==>".$job." [".$jobname."]\n";
	$APname = $scheduler->GetApplicationName();
	if ( $APname ) {print "\tAPname:".$APname."\n";}
	$parameter = $scheduler->GetParameters();
	if ( $parameter ) {print "\tParameter:".$parameter."\n";}
	$workdir = $scheduler->GetWorkingDirectory();
	if ( $workdir ) {print "\tWorkDir:".$workdir."\n";}
	$account = $scheduler->GetAccountInformation();
	if ( $account ) {print "\tAccount:".$account."\n";}
	$scheduler->GetExitCode($exitcode);
	print "\tExitCode:".$exitcode."\n";
	$scheduler->GetStatus($status);
	if ( $status == 267008 ) { #Ready
		print "\tStatus:ready\n";
	}
	elsif ( $status == 267009 ) { #Runnig
		print "\tStatus:RUNNING\n";
	}
	elsif ( $status == 267010 ) { #Not Scheduled
		print "\tStatus:Not Scheduled\n";
	}
	else {
		print "\tStatus:UNKNOWN\n";
	}
	$flags = $scheduler->GetFlags();
	if ( $flags ) {print "\tFlags:".$flags."\n";}
	$triggerCnt = $scheduler->GetTriggerCount();
	if ( $triggerCnt > 0 ) {
		for ( $idx = 0; $idx < $triggerCnt; $idx++ ) {
			print "\tTrigger $idx:\n";
			$scheduler->GetTrigger($idx,\%trigger);
			foreach $key (keys %trigger) {
				if ( $key eq "TriggerType" ) {
					$trigType = $trigger{$key};
					if ( $trigType == $scheduler->TASK_TIME_TRIGGER_ONCE ) {
						print "\t\t$key=ONCE\n";
					}
					elsif ( $trigType == $scheduler->TASK_TIME_TRIGGER_DAILY ) {
						print "\t\t$key=DAILY\n";
					}
					elsif ( $trigType == $scheduler->TASK_TIME_TRIGGER_WEEKLY ) {
						print "\t\t$key=WEEKLY\n";
					}
					elsif ( $trigType == $scheduler->TASK_TIME_TRIGGER_MONTHLYDATE ) {
						print "\t\t$key=MONTHLY_DATE\n";
					}
					elsif ( $trigType == $scheduler->TASK_TIME_TRIGGER_MONTHLYDOW ) {
						print "\t\t$key=MONTHLY_DOW\n";
					}
					elsif ( $trigType == $scheduler->TASK_EVENT_TRIGGER_ON_IDLE ) {
						print "\t\t$key=ON_IDLE\n";
					}
					elsif ( $trigType == $scheduler->TASK_EVENT_TRIGGER_AT_SYSTEMSTART ) {
						print "\t\t$key=AT_SYSTEMSTART\n";
					}
					elsif ( $trigType == $scheduler->TASK_EVENT_TRIGGER_AT_LOGON ) {
						print "\t\t$key=AT_LOGON\n";
					}
					else {
						print "\t\t$key=".$trigger{$key}."\n";
					}
				}
				else {
					print "\t\t$key=".$trigger{$key}."\n";
				}
			}
		}
	}
}
$scheduler->End();