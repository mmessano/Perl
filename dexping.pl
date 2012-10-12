#!c:/perl/bin -w
#
# enumerate the entire network via IP ranges
# site_check.pl
#

use strict;
use diagnostics;
use warnings;
use Win32::OLE('in');
#use Date::Calc qw/Today Delta_Days/;
use Net::Ping;
use Socket;
use Data::Dumper;


my $adr = "192.168.";
my @net = qw / 97. 100. 102. 104. 105. 32. 33. 34. /;
my ( $i, $j, $host );
my ( $ftpobj, $w3obj, $smtpobj, $nntpobj );
my ( $p, $d, $iadd );

my $dexlog = Win32::OLE->new('Dexma.Dexlog') ;
$p = Net::Ping->new( "tcp", 3 ) or die "Can't create ping object: $!\n";

#$d = Net::Domain->new;


for ( $i = 0 ; $i <= 7 ; $i++ ) {
  HOST: for ( $j = 16 ; $j <= 250 ; $j++ ) {
        $host = $adr . $net[$i] . $j;
        if ( !$p->ping($host) ) {
            print "Host $host is unreachable.\n";
            $dexlog->Msg("Ping connection failed for $host.");
			next HOST;
        }
        else {
			print "Host $host is up.\n";
			$iadd = inet_aton($host);
			print "iadd: " . $iadd . "\n";
            $d = gethostbyaddr($iadd, AF_INET);
            print "Hostname is: " . $d . "\n";
			$dexlog->Msg("Ping connection succeeded for $host.");

			
  		}

  }
    $p->close;
}

