# SAAUDIT.PL
#
# Reports the user account other than LocalSystem used to start
# each services on all servers in a domain
#
# This script was written by Paul Popour (ppopour@infoave.net) in 09/2000.
# It is released into the public domain.  You may use it freely, however,
# if you make any modifications and redistribute, please list your name
# and describe the changes. This script is distributed without any warranty,
# express or implied.
#
#  SYNTAX - perl saaudit.pl [domainname]
#
# Example
#
#   perl saaudit.pl        (uses the domain you are currently logged into)
#  or
#   perl saaudit.pl DOMAIN1
#
# Primary use for this script is to record the accounts used
# to start the services on servers in a domain.  It ignores
# the services that are using the LocalSystem account.
# Occasionally auditing these accounts will allow you to find
# a service that has been improperly configured to use a normal
# user account, (or worst yet, the administrator account) to start.
#
# This script requires the Win32::Lanman module available at the
# following sites:
#
# http://jenda.mccann.cz/
# http://www.roth.net/perl/
#
# Thanks to Jens Helberg for this excellent module.
#
# updated 2004/11/11 mmessano

use strict;
use diagnostics;
use warnings;
use Win32::NetAdmin;
use Win32::Lanman;

my ($domain, $key, $output, $PDC, $server, @servers1, @servers2, @servers3, $service, @services, %config);

if ($ARGV[0] ne ""){$domain = $ARGV[0];} else {$domain = Win32::DomainName;}
$output = "c:\\temp\\Service Account Audit for $domain.txt";
unless (Win32::NetAdmin::GetDomainController("", $domain, $PDC)) {print ("Unable to obtain the PDC name for $domain.");}
unless (Win32::NetAdmin::GetServers($PDC, $domain, 0x00000008, \@servers1)) {print ("Unable to read NetBios 0008.");}
unless (Win32::NetAdmin::GetServers($PDC, $domain, 0x00000010, \@servers2)) {print ("Unable to read NetBios 0010.");}
unless (Win32::NetAdmin::GetServers($PDC, $domain, 0x00008000, \@servers3)) {print ("Unable to read NetBios 8000.");}
@servers1 = (@servers1, @servers2, @servers3);
open(OUTFILE, ">$output") || die ("Cannot open output file $output\n");
foreach $server (@servers1)
	{
	print ".";
	if(!Win32::Lanman::EnumServicesStatus("\\\\$server", "", &SERVICE_WIN32, &SERVICE_STATE_ALL, \@services))
		{
		print "Error enumerating the status of services on $server\t";
		print (Win32::Lanman::GetLastError(), "\n");
		next;
		}
	foreach $service (@services)
		{
		if(!Win32::Lanman::QueryServiceConfig("\\\\$server", '', "${$service}{name}", \%config))
			{
			print "Error querying the configuration of the ${$service}{name} service on $server\t";
			print (Win32::Lanman::GetLastError(), "\n");
			next;
			}
		for $key (sort keys %config)
			{
            if (($key eq "account")&&($config{$key} ne "LocalSystem"))
				{
				print OUTFILE "$server\t${$service}{display}\t$config{$key}\n";
				}
			}
		}
	}
close OUTFILE;
