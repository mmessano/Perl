#!c:/perl/bin -w
#
# time_getset_remote.pl
#

use Win32::OLE qw(in);

my $datetime = Win32::OLE->new("WbemScripting.SWbemDateTime") or die;
my $machine = shift @ARGV or ".";
$machine =~ s/^[\\\/]+//;
my $wmiservices = Win32::OLE->GetObject("winmgmts:{impersonationLevel=impersonate,(security)}//$machine") or die;
foreach my $os ( in( $wmiservices->InstancesOf("Win32_OperatingSystem") ) )
{
  print "Last Boot Time:".$os->{LastBootUpTime}."\n";
  print "Current time:".$os->{LocalDateTime}."\n";
  $datetime->{Value} = $os->{LocalDateTime};
  printf( "Current Time: %02d-%02d-%04d at %02d:%02d:%02d\n", $datetime->{Month}, $datetime->{Day}, $datetime->{Year}, $datetime->{Hours}, $datetime->{Minutes}, $datetime->{Seconds} );
  #print "Setting time + 2 hours:";
  #$datetime->{Hours} += 2;
  #printf( "Current Time: %02d-%02d-%04d at %02d:%02d:%02d\n", $datetime->{Month}, $datetime->{Day}, $datetime->{Year}, $datetime->{Hours}, $datetime->{Minutes}, $datetime->{Seconds} );
  print "\tHard value: $datetime->{Value}\n";
  $Result = $os->SetDateTime($datetime->{Value});
  print "Result: $Result\n";
}