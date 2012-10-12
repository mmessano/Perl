#!c:/perl/bin -w
#
# snapshot_process_perfmon.pl
#

#use strict;
use diagnostics;
use warnings;
use Win32::Process::Perf;

my $PERF = Win32::Process::Perf->new("apus", "QRX");
  # The computer name have to be used without the \\
  # e.g. my $PERF = Win32::Process::Perf->new("taifun", "explorer");
  # check if success:
  if(!$PERF)
  {
          die;
  }

  my $anz = $PERF->GetNumberofCounterNames();
  print "$anz Counters available\n\n";
  my %counternames = $PERF->GetCounterNames();
  print "Avilable Counternames:\n";
  foreach (1 .. $anz)
  {
          print $counternames{$_} . "\n";
  }
  my $status = $PERF->PAddCounter();    # add all available counters to the query
  if($status == 0) {
          my $error = $PERF->GetErrorText();
          print "error caught\n";
		  print $error . "\n";
          exit;
  }
  while(1)
  {
          $status = $PERF->PCollectData();
          if($status == 0) {
                  my $error = $PERF->GetErrorText();
                  print "Error caught in collect data\n";
                  print $error . "\n";
                  exit;
          }
          my %val = $PERF->PGetCounterValues($status);
          # now you can also get the CPU Time:
          my $cputime = $PERF->PGetCPUTime();
          # and also the username which started the process:
          #my $username = $PERF->PGetUserName();
          foreach  (1..$anz)
          {
           if(!$val{$_}) { exit; }
                   my $key = $counternames{$_};
                   print "$key=" . $val{$_} . "\n";
          }
          sleep(1);
          print "\n";
  }