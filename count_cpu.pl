#!c:/perl/bin -w
#
# count_cpu.pl
#


use strict;
use diagnostics;
use warnings;
use Win32::OLE qw( in );
use constant wbemFlagReturnImmediately =>  0x10;
use constant wbemFlagForwardOnly =>  0x20;

my $server = shift @ARGV || ".";
my $objWMIService = Win32::OLE-> GetObject("winmgmts:\\\\$server\\root\\CIMV2") or die "WMI connection failed.\n";
my $Processors = $objWMIService->InstancesOf("Win32_Processor");
my %sockets = ( );

foreach my $CPU (in $Processors)
{
  print "CPU Name: " . $CPU->{Name}."\n";
  print "CPU Socket: ".$CPU->{SocketDesignation}."\n";
  print "Cpu Status: ".$CPU->{CpuStatus}."\n\n";
  if ($CPU->{CpuStatus}>0) {$sockets{$CPU->{SocketDesignation}}=1}
  }
print "=======================\n";
print "True processor count: ".scalar(keys %sockets)."\n";
exit;