#!c:/perl/bin -w
#
# rrd_extract.pl
# C:\rrdtool\Release\rrdtool.exe fetch \\mensa\dexma\Support\Monitoring\CPU\Apollo_2_cpu.rrd AVERAGE --start now-7days --end now
# Usage: rrd_extract.pl <directory> <server1[,server2,server3]>

use strict;
use diagnostics;
use warnings;
use DirHandle;

my ( $ctime, $rrdres, $rrd_dir, $rrdtool );

# @ARGV uses base 0 counting, ( $#ARGV < 1 ) means 2 arguments
if ( $#ARGV < 1 ) {
	print "\nUsage: rrd_extract.pl <directory> <server1[,server2,server3]>\n";
	print "Servers must be seperated by ',' with no spaces.\n";
	exit;
}

$ctime = time;
$rrdres = 300;
$rrd_dir = $ARGV[0];
$rrdtool = "C:\\rrdtool\\Release\\rrdtool.exe fetch ";

my @servers = split(',', $ARGV[1]);
my @files = &plainfiles($rrd_dir);

foreach my $server ( @servers ) {
	my $out = "c:\\dexma\\temp\\$server" . "_export.txt";
	foreach my $file ( @files ) {
		if ( $file =~ /$server/ ) {
			print "$file\n";
			system "$rrdtool $file AVERAGE > $out";
		}
	}
	open(DAT, $out) || die("Could not open $out for reading!");
	my @data = <DAT>;
	close DAT;
	my @newnames = grep( ( m/^\d{10}/ ), @data );
	foreach my $name ( @newnames ) {
		print "Name: " . $name;
	}
}


# voodoo
# @outputarray =  grep( ( ($h{$_}++ == 1) || 0 ), @inputarray );
# my @newnames = grep( ( (^\d{10}) ), @files );


sub plainfiles {
   my $dir = shift;
   my $dh = DirHandle->new($dir)   or die "can't opendir $dir: $!";
   return sort                     # sort pathnames
          grep {    -f     }       # choose only "plain" files
          map  { "$dir$_" }        # create full paths
          grep {  !/^\./   }       # filter out dot files
          grep {  m/\.rrd/ }       # filter rrd files
          $dh->read();             # read all entries
}


#for ( my $i = 1; $i <= $#ARGV; $i++ ) {
#	print $ARGV[$i] . "\n";
#}
