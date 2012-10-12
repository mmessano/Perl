#!c:/perl/bin/perl.exe -w
# livestats_dir_sync.pl
#


use strict;
use diagnostics;
use warnings;
use Win32::OLE('in');


my ( $dexlog, $dir, $index_dir, @files, @index_files, $file, $size, $path, $count, $aggregate_size, $index_path, $index_size );


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
$aggregate_size = 0;

foreach $file ( @index_files ) {
		$index_path = "$index_dir\\$file";
		$path = "$dir\\$file";
		next unless -f $index_path;
		if ( $index_path =~ /\.ipmdb/ ) {
			if ( -e $path ) {
	        	#print "$index_path = \t $path\n";
			}
			else {
	        	print "No match found for $index_path.\n";
	        	$index_size = (stat($index_path))[7] or warn "Stat failed for $index_path: $!";
	        	$aggregate_size = $index_size + $aggregate_size;
				$count++;
				print "Deleting unmatched file... $index_path\n";
				unlink $index_path;
			}
		}
}

print "$count files found with no matches in DB directory.\n";
print "Disk savings in bytes: $aggregate_size \n";