#!c:/perl/bin/perl.exe -w
# livestats_db_prune.pl
#


use strict;
use diagnostics;
use warnings;
use Switch;
use Win32::OLE('in');


my ( $argcount, $dexlog, $count, $delete, @data, @candidates );
my ( $dir, $index_dir, $file, $path, $index_path, @files, @index_files );
my ( $size, $index_size, $aggregate_size_db, $aggregate_size_index );
my ( $mtime, $now, $time_diff );

$argcount = @ARGV;

$dexlog = Win32::OLE->new('Dexma.Dexlog') or warn "Cannot create DexLog object $!\n";
$dexlog->SetProperty('ModuleName','livestats_db_prune');

$dir = '\\\\xops4\\e$\\ipMonitor7\\db';
$index_dir = '\\\\xops4\\e$\\ipMonitor7\\db\\indexed';

opendir DIR, $dir or die "Can't open directory $dir: $!\n";
# grab file list from directory
@files = (readdir DIR);

opendir DIR2, $index_dir or die "Can't open directory $index_dir: $!\n";
# grab file list from directory
@index_files = (readdir DIR2);


$count = 0;
$aggregate_size_db = 0;
$aggregate_size_index = 0;
# time in seconds since epoch
$now = time;

foreach $file ( @files ) {
	   $path = "$dir\\$file";
	   next unless -f $path;
	   # size in bytes - a 1 KB(1,024 bytes) file on disk uses 4 KB(4,096 bytes) storage(block size)
	   # these files are empty so they use minimum size for a file, 1 KB
	   $size = (stat($path))[7] or warn "Stat failed for $path: $!";
	   # get modified time for the file - if it has not been modified in the last two hours(7200 seconds)
	   # assume it is not accumulating stats and can be safely modified
	   $mtime = (stat($path))[9] or warn "Stat failed for $path: $!";
	   $time_diff = $now - $mtime;
	   if ( $size < 1024 or $time_diff > 7200 ) {
			$index_path = "$index_dir\\$file";
			$index_size = (stat($index_path))[7] or warn "Stat failed for $index_path: $!";
			$aggregate_size_db = $size + $aggregate_size_db;
			if ( $index_size != $size ) {
				push @candidates, $file;
				$count++;
				$aggregate_size_index = $index_size + $aggregate_size_index;
			}
		}
}


if ( $argcount == 1 ) {
	switch ($ARGV[0]) {
		case "--delete"		{ $delete = "true"; @data = " "; }
	}
}
else {
	$delete = "false";
}	


# sort array to remove duplicates
my %hash = map { $_ => 1 } @candidates;
@candidates = sort keys %hash;
foreach (@candidates) {
	if ( $delete eq "true" ) {
		print "Deleting contents of $_.\n";
		open(FILE, ">$dir\\$_") or die "Couldn't open the $dir\\$_ file: $!;\n aborting";
		print FILE @data;
		open(FILE2, ">$index_dir\\$_") or die "Couldn't open the $index_dir\\$_ file: $!;\n aborting";
		print FILE2 @data;
		close FILE;
		close FILE2;
	}
	else {
	print "$_\n";
	}

}

print "$count files found that are likely candidates for removal.\n";
print "Total size of all db files: $aggregate_size_db(" . ( ( $aggregate_size_db / 1024 ) / 1024 ) . " MB)\n";
print "Total size of all indexed files: $aggregate_size_index(" . ( ( $aggregate_size_index / 1024 ) / 1024 ) . " MB)\n";