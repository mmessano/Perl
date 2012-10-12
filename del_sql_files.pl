#!c:/perl/bin -w
#
# del_files.pl
#

use strict;
use diagnostics;
use warnings;
use File::stat;
use Spreadsheet::WriteExcel;
use Win32::OLE('in');


my ( $infile, $file, @files, @dirs, $dexlog, $stats, $totalsize );
my ( @header, $obook, $outbook, $outsheet, $newrow);

$infile = "C:\\Dexma\\temp\\sql_delete_old_files.txt";



# spreadsheet to write to
$obook = "C:\\Dexma\\temp\\del_sql_files.xls";

if ( -e $obook ) {
	unlink $obook;
	}
	
open(DAT, $infile) || die("Could not open $infile for reading!");
@files = <DAT>;
close DAT;


$dexlog = Win32::OLE->new('Dexma.Dexlog') or warn "Cannot create DexLog object $!\n";
$dexlog->SetProperty('ModuleName','del_sql_files');


$outbook =  Spreadsheet::WriteExcel->new("$obook");
$outsheet = $outbook->add_worksheet();


my %header_row = (
					font 		=>	'Arial',
					size 		=>	'14',
					bg_color 	=>	'55',
					bold 		=>	'1',
					align		=>	'center'
				);
				
				
				
				# row formats
my $header = $outbook->add_format();
   $header->set_properties(%header_row);


# header row
@header =  (
			[ "File", "Size", "Modified Time", "Access Time" ]
			);
			

# write the header and freeze the worksheet
$outsheet->write_col(0, 0, \@header, $header);
$outsheet->freeze_panes(1, 0);

# increment for header row
$newrow = 1;

@files = sort(@files);
foreach $file ( @files ) {
	chomp($file);
	unless ( -f $file ) {
			#$dexlog->Msg("*** $file - Doesn't appear to exist!: $! ***");
			if ( -d $file ) {
				push @dirs, $file;
				}
			next;	
		}
	$stats = stat($file);
	my $size = $stats->size;
	my $mtime = localtime($stats->mtime);
	my $atime = localtime($stats->atime);
	my @row =  (
				[ $file, $size, $mtime, $atime ]
				);
	$outsheet->write_col($newrow, 0, \@row);
	print "File: " . $file . "\n";
	# remove file
	print "Deleting " . $file  . "\n";
	unlink $file;
	$totalsize = ( $totalsize + $stats->size );
	$newrow++;
	}

@dirs = sort(@dirs);	
foreach my $dir ( @dirs ) {
	print "Directory: " . $dir . "\n";
	$stats = stat($dir);
	my $mtime = localtime($stats->mtime);
	my $atime = localtime($stats->atime);
	my @row =  (
				[ $dir, "", $mtime, $atime ]
				);
	$outsheet->write_col($newrow, 0, \@row);
	$newrow++;
	# remove directory
	system "rmdir /S $dir";
	}
	
#totals
my $mb = ( ( $totalsize/1024 )/1024 );
my $gb = ( $mb/1024 );
my @row =  (
				[ "TotalSize", $totalsize . " Bytes", $mb . " MB", $gb . " GB" ]
				);	
$outsheet->write_col($newrow, 0, \@row);