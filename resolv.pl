#!/usr/bin/perl
# resolv.pl written by detour@metalshell.com
#
# Resolves an ip into a host or a host into an ip.
#
# http://www.metalshell.com/
#

use Socket;
use strict;

my $host_name = hostname($ARGV[0]);
print "$ARGV[0] resolves to $host_name\n";

sub hostname {

  my (@bytes, @octets,
    $packedaddr,
    $raw_addr,
    $host_name,
    $ip
  );

  if($_[0] =~ /[a-zA-Z]/g) {
    $raw_addr = (gethostbyname($_[0]))[4];
    @octets = unpack("C4", $raw_addr);
    $host_name = join(".", @octets);
  } else {
    @bytes = split(/\./, $_[0]);
    $packedaddr = pack("C4",@bytes);
    $host_name = (gethostbyaddr($packedaddr, 2))[0];
  }

  return($host_name);
}