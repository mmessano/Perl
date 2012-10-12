# SRVCPUMEM.PL - Reports the speed, brand and number of processors
#                as well as the amount of RAM for servers in a domain
#
# This script was written by Paul Popour (ppopour@infoave.net) in 08/2000.
# It is released into the public domain.  You may use it freely, however,
# if you make any modifications and redistribute, please list your name
# and describe the changes. This script is distributed without any warranty,
# express or implied.
#
#  SYNTAX - perl srvcpumem.pl [domainname]
#
# Example
#
#   perl srvcpumem.pl            (uses the domain you are currently logged into)
#  or
#   perl srvcpumem.pl DOMAIN1
#
# Primary use for this script is to record the amount of processors
# and RAM memory in your servers.  The numbers are close on the
# processor speed and RAM but not deadly acurate.
# This is due to the fact that a 550 MHZ  processor might
# report to be a 549 MHZ while a 500 processor reports as 498 etc.,.
# You could build a hash to cross reference the actual numbers but....
#
# This script requires the Win32::TieRegistry available at the following URL
#
# http://www.activestate.com/Packages/:
#
# Thanks to Peter Guzis for coming up with an improved method for reading
# a translated registry key
#

use Win32::TieRegistry( Delimiter=>"/" );
use Win32::NetAdmin;
use POSIX;

$output = "c:\\dexma\\srvdata.txt";
if (-e $output){unlink $output;}
if (@ARGV[0] ne ""){$domain = @ARGV[0];} else {$domain = Win32::DomainName;}
unless (Win32::NetAdmin::GetDomainController("", $domain, $pdc)) {die "Unable to PDC for $domain.";}
unless (Win32::NetAdmin::GetServers($pdc, $domain, 0x00000008, \@servers1)) {print "Unable to read NetBios 0008.";}
unless (Win32::NetAdmin::GetServers($pdc, $domain, 0x00000010, \@servers2)) {print "Unable to read NetBios 0010.";}
unless (Win32::NetAdmin::GetServers($pdc, $domain, 0x00008000, \@servers3)) {print "Unable to read NetBios 8000.";}
@servers1 = (@servers1, @servers2, @servers3);
foreach $server (@servers1)
	{
	my ($key, $realname, $speed, $numproc, $data);
	print ".";
	if ($key = $Registry->Open("//$server/LMachine/SYSTEM/CurrentControlSet/Control/ComputerName/ComputerName/", {Access=>KEY_READ}))
		{
		unless ($realname = $key->GetValue("ComputerName"))
			{
			print "\nCan't attach to read value of ComputerName on $server\n";
			open(OUTPUT, ">>$output") || die "Can't open $output";
			print OUTPUT "Can't attach to read value of ComputerName on $server\n";
			close OUTPUT;
			next;
			}
		}
	else
		{
		print "\nCan't attach to registry key 1 of $server\n";
		open(OUTPUT, ">>$output") || die "Can't open $output";
		print OUTPUT "Can't attach to registry key 1 of $server\n";
		close OUTPUT;
		next;
		}
	next if ($server ne $realname);
	print ".";
	if ($key = $Registry->Open("//$server/LMachine/HARDWARE/DESCRIPTION/System/CentralProcessor/0/", {Access=>KEY_READ}))
		{
		unless ($speed = $key->GetValue("~MHZ"))
			{
			print "\nCan't attach to read value of ~MHZ on $server\n";
			open(OUTPUT, ">>$output") || die "Can't open $output";
			print OUTPUT "Can't attach to read value of ~MHZ on $server\n";
			close OUTPUT;
			next;
			}
		$speed = int (((int(hex ($speed) /5) + 1) * 5));
		}
	else
		{
		print "\nCan't attach to registry key 2 of $server\n";
		open(OUTPUT, ">>$output") || die "Can't open $output";
		print OUTPUT "Can't attach to registry key 2 of $server\n";
		close OUTPUT;
		next;
		}
	print ".";
	if ($key = $Registry->Open("//$server/LMachine/SYSTEM/CurrentControlSet/Control/Session Manager/Environment/", {Access=>KEY_READ}))
		{
		unless ($numproc = $key->GetValue("NUMBER_OF_PROCESSORS"))
			{
			print "\nCan't attach to read value of NUMBER_OF_PROCESSORS on $server\n";
			open(OUTPUT, ">>$output") || die "Can't open $output";
			print OUTPUT "Can't attach to read value of NUMBER_OF_PROCESSORS on $server\n";
			close OUTPUT;
			next;
			}
		}
	else
		{
		print "\nCan't attach to registry key 3 of $server\n";
		open(OUTPUT, ">>$output") || die "Can't open $output";
		print OUTPUT "Can't attach to registry key 3 of $server\n";
		close OUTPUT;
		next;
		}
	print ".";
	if ($key = $Registry->Open("//$server/LMachine/HARDWARE/DESCRIPTION/System/CentralProcessor/0/", {Access=>KEY_READ}))
		{
		unless ($brand = $key->GetValue("VendorIdentifier"))
			{
			print "\nCan't attach to read value of VendorIdentifier on $server\n";
			open(OUTPUT, ">>$output") || die "Can't open $output";
			print OUTPUT "Can't attach to read value of VendorIdentifier on $server\n";
			close OUTPUT;
			next;
			}
		}
	else
		{
		print "\nCan't attach to registry key 4 of $server\n";
		open(OUTPUT, ">>$output") || die "Can't open $output";
		print OUTPUT "Can't attach to registry key 4 of $server\n";
		close OUTPUT;
		next;
		}
	print ".";
	if ($remoteKey = $Registry->{"//$server/LMachine/HARDWARE/RESOURCEMAP/System Resources/Physical Memory/"})
		{
		unless ($data = ceil((unpack "L*", $remoteKey->GetValue('.Translated'))[-1] / 1024/ 1024 + 16))
			{
			print "\nCan't attach to read value of .Translated on $server\n";
			open(OUTPUT, ">>$output") || die "Can't open $output";
			print OUTPUT "Can't attach to read value of .Translated on $server\n";
			close OUTPUT;
			next;
			}
		}
	 else
		{
		print "\nCan't attach to registry key 5 of $server\n";
		open(OUTPUT, ">>$output") || die "Can't open $output";
		print OUTPUT "Can't attach to registry key 5 of $server\n";
		close OUTPUT;
		next;
		}

	open(OUTPUT, ">>$output") || die "Can't open $output";
	print OUTPUT "$server\t$speed MHZ\t$brand\t$numproc\t$data MB\n";
	close OUTPUT;
	print "\n\nOutput recorded in $output\n\n";
	}
