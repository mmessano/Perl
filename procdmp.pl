#! c:\perl\bin\perl.exe
#-------------------------------------------------------------------------
# procdmp.pl
# script to consolidate the output of several external commands
# (netstat, fport, listdlls, handle, pslist, etc) into a single
# HTML file for ease of analysis (example batch file at the end of this
# file).
#
# Usage:
# 1.  Run each of the listed tools, redirecting their output to a .log file
#     NOTE: The file names and locations are hard-coded into the script.
# 2.  Make sure that all of the .log files are in the same directory as
#     the script, and then run the script (ie, c:\perl>procdmp.pl)
# 3.  Open the resulting HTML file in a browser, or simply type "procdmp.html"
#     at the prompt.
#
# TODO:
# 1.  Add a switch that will handle XP systems (fport does not work, on XP,
#     need to use '-o' switch in netstat instead)
# 2.  Add a GUI to allow the user to select the files rather than hard-
#     coding them
#
# Author: H. Carvey, keydet89@yahoo.com
#-------------------------------------------------------------------------
use strict;

my $html = "procdmp.html";
my %procs;

# Get list of processes/PIDs
my $pslist = "pslist\.log";
open(FH, $pslist) || die "Could not open $pslist: $!\n";
while (<FH>) {
	chomp;
	my @list = split(/\s+/,$_,9);
	next if ($list[0] =~ m/^pslist/i);
	if ($list[2] =~ m/^\d+$/) {
		$procs{$list[1]} = $list[0];
	}
}
close(FH);

# Start HTML file
my $html = "procdmp\.html";
open(HTML, ">$html") || die "Could not open $html: $!\n";
print HTML "<html><head>\n";
print HTML "<title>NT/2K Process Dump</title>\n";
print HTML "</head>\n";
print HTML "<body bgcolor=#cccccc>\n";
print HTML "<center><h2>NT/2K Process Dump</h2></center><p>\n";

foreach my $pid (sort keys %procs) {
	print HTML "<center>\n";
	print HTML "<table border=2 cols=4 cellspacing=0 cellpadding=5 width=\"80%\">\n";

	my $cmd = getCommandLine($pid);
	my $context = getContext($procs{$pid},$pid);
	my @ports = getPorts($pid);
#	print "PID: $pid\tProcess: $procs{$pid}\n";
	print HTML "<tr><td width=\"15%\" bgcolor=\"#66ffff\"><b>PID</b></td>";
	print HTML "<td colspan=3> $pid</td></tr>\n";
	print HTML "<tr><td width=\"15%\" bgcolor=\"#66ffff\"><b>Process</b></td>";
	print HTML "<td colspan=3>$procs{$pid}</td></tr>\n";
#	print "CommandLine: $cmd\n";
	print HTML "<tr><td width=\"15%\" bgcolor=\"#66ffff\"><b>Command Line</b></td>";
	print HTML "<td colspan=3>$cmd</td></tr>\n";
#	print "Context    : $context\n";
	print HTML "<tr><td width=\"15%\" bgcolor=\"#66ffff\"><b>Context</b></td>";
	print HTML "<td colspan=3> $context</td></tr>\n";
	if (@ports) {
		my $rows = scalar @ports;
		print HTML "<tr><td width=\"15%\" bgcolor=\"#66ffff\" rowspan=".$rows."><b>Ports</b></td>\n";
		my ($proto,$port) = split(/:/,$ports[0],2);
		my $str = getConnections($proto,$port);
		print HTML "<td>$proto</td><td>$port</td><td>$str</td></tr>\n";

		foreach my $index (1..$rows-1) {
			my($proto,$port) = split(/:/,$ports[$index],2);
			my $str = getConnections($proto,$port);
			print HTML "<tr><td>$proto</td><td>$port</td><td>$str</td></tr>\n";
		}
	}
	print HTML "</table><p><p>\n";
	print HTML "</center>\n";
}

print HTML "</html>\n";
close(HTML);

#-----------------------------------------------------------------
#
#-----------------------------------------------------------------
sub getCommandLine {
	my $pid = $_[0];
	my $cmdline;
	my @list;
	my $listdlls = "listdlls\.log";
	open(FH, $listdlls) || die "Could not open $listdlls: $!\n";
	@list = <FH>;
	close(FH);

	my $count = scalar @list;
	foreach my $index (0..$count-1) {
		my $test = (split(/:/,$list[$index],2))[1];
		if ($test == $pid) {
			$cmdline = (split(/:/,$list[$index+1],2))[1];
			$cmdline =~ s/\"//g;
			chop($cmdline);
		}
	}
	return $cmdline;
}

#-----------------------------------------------------------------
#
#-----------------------------------------------------------------
sub getContext {
	my $proc = $_[0];
	my $pid = $_[1];
	my $test = "pid: $pid";
	my $context;
	my $handle = "handle\.log";
	open(FH,$handle) || die "Could not open $handle: $!\n";
	my @list = <FH>;
	close(FH);
	my $count = scalar @list;
	foreach my $index (0..$count-1) {
		next if ($list[$index] =~ m/^(-|\s)/);
		if ($list[$index] =~ m/^$proc/i && grep(/$test/,$list[$index])) {
			$context = (split(/$pid/,$list[$index],2))[1];
			chop($context);
		}
	}
	return $context;
}

#-----------------------------------------------------------------
#
#-----------------------------------------------------------------
sub getPorts {
	my $pid = $_[0];
	my @ports;
	my $fport = "fport\.log";
	open(FH,$fport) || die "Could not open $fport: $!\n";
	while(<FH>) {
		chomp;
		if ($_ =~ m/^$pid/) {
			my ($port,$proto) = (split(/\s+/,$_,6))[3,4];
			push(@ports,"$proto:$port");
		}
	}
	close(FH);
	return @ports;
}

#-----------------------------------------------------------------
#
#-----------------------------------------------------------------
sub getConnections {
	my $proto = $_[0];
	my $port = $_[1];
	my @conns;
	my $netstat = "netstat\.log";
	open(FH,$netstat) || die "Could not open $netstat: $!\n";
	while(<FH>) {
		chomp;
		my $line = $_;
		if ($line =~ m/^\s+$proto/i) {
			my ($local,$remote,$status) = (split(/\s+/,$line,5))[2,3,4];
			my $lport = (split(/:/,$local,2))[1];
			push(@conns,$remote.":$status") if ($lport == $port);
		}
	}
	close(FH);
	my $str = join(',',@conns);
}

#-------------------------------------------------------------------------
# This script requires that the following files be located in the current
# working directory (NOTE: The filenames must be spelled properly!!):
# - handle.log (output of handle.exe from SysInternals)
#   handle > handle.log
# - listdlls.log (output of listdlls.exe from SysInternals)
#   listdlls > listdlls.log
# - fport.log (output of fport.exe from FoundStone)
#   fport > fport.log
# - pslist.log (output of pslist.exe from SysInternals)
#   pslist > pslist.log
# - netstat.log (output of 'netstat -an' on NT/2K...for XP, add '-o')
#   netstat -an > netstat.log
#
# @echo off
# pslist > pslist.log
# handle > handle.log
# listdlls > listdlls.log
# netstat -an > netstat.log
# fport > fport.log
#-------------------------------------------------------------------------
