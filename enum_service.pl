#!c:/perl/bin -w
#
# enum_service.pl
#

use strict;
use diagnostics;
use warnings;
use Win32::Service;

my $service = 'iisadmin';

my ( %hash );
my ( %status );
Win32::Service::GetStatus('messano338', $service, \%status);
Win32::Service::GetServices('messano338', \%hash);

print "Begin GetStatus block:\n";
print "\n";
while ( my ($key, $value) = each(%status) ) {
	print "\t$key => $value\n";
}
print "\n";
print "End GetStatus block:\n";
print "\n";

print "\n";
print "Begin GetServices block:\n";
print "\n";
while ( my ($key, $value) = each(%hash) ) {
	#print "\t$key => $value\n";
}
print "End GetServices block:\n";
print "\n";

# service states
# 4 - running
# 1 - stopped
# 7 - paused