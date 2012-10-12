#!c:/perl/bin -w
#
# snapshot_process.pl
#

use strict;
use diagnostics;
use warnings;
use Date::EzDate;
use IO::File;
use Time::Local;
use Win32::OLE('in');

use Data::Dumper;
use Array::PrintCols;

use constant wbemFlagReturnImmediately => 0x10;
use constant wbemFlagForwardOnly => 0x20;

my (@AoA, @newAoA, @newAoA2, @newAoA3, @tempAoA, $computer, $outfile, $dumpfile, $OUTPUT, $OUTPUT2, $capture_time, $start_date, $dexlog, %qrx, $qrx, $key, $asize, $size, $i, $href, $role, %href);

@AoA = ();
@newAoA = ();

$dexlog = Win32::OLE->new('Dexma.Dexlog') or warn "Cannot create DexLog object $!\n";
$dexlog->SetProperty('ModuleName','snapshot_process');

my @computers = ("apus");

foreach $computer (@computers) {
   print "Begin: $computer\n";
   $dexlog->Msg("Begin $computer.\n");
   $outfile = "\\\\apus\\Dexma\\support\\logs\\" . $computer . "_proc_list_test.csv";
   $dumpfile = "\\\\messano338\\Dexma\\logs\\" . $computer . "_dumper.csv";
   my $objWMIService = Win32::OLE->GetObject("winmgmts:\\\\$computer\\root\\CIMV2") or die $dexlog->Msg("WMI connection to $computer failed, ending here.\n");
   my @colItems = $objWMIService->ExecQuery("SELECT Caption,CreationDate,ProcessId,PageFaults,PageFileUsage,PeakPageFileUsage,PeakVirtualSize,PeakWorkingSetSize,PrivatePageCount,VirtualSize,WorkingSetSize FROM Win32_Process where Name='qrx.exe'", "WQL", wbemFlagReturnImmediately | wbemFlagForwardOnly);
   $dexlog->Msg("WMI connection to $computer succeeded.\n");
   $OUTPUT = IO::File->new($outfile, ">>") or warn "Cannot open $outfile! $!\n";
   $OUTPUT2 = IO::File->new($dumpfile, ">>") or warn "Cannot open $dumpfile! $!\n";
   $capture_time = Date::EzDate->new();
   $capture_time->set_format('my_format', '{weekday short} {month short} {day of month} {year} {hour}:{min}:{sec}');
   #print $OUTPUT "Capture Time, Caption, CreationDate, ProcessId, PageFaults, PageFileUsage, PeakPageFileUsage, PeakVirtualSize, PeakWorkingSetSize, PrivatePageCount, VirtualSize, WorkingSetSize\n";
	   foreach my $objItem (in @colItems) {
		  $start_date = Date::EzDate->new(utc2seconds($objItem->{CreationDate}));
	      $start_date->set_format('my_format', '{weekday short} {month short} {day of month} {year} {hour}:{min}:{sec}');
		  print $OUTPUT "$objItem->{Caption}, $capture_time->{'my_format'}, $start_date->{'my_format'}, $objItem->{ProcessId}, $objItem->{PageFaults}, $objItem->{PageFileUsage}, $objItem->{PeakPageFileUsage}, $objItem->{PeakVirtualSize}, $objItem->{PeakWorkingSetSize}, $objItem->{PrivatePageCount}, $objItem->{VirtualSize}, $objItem->{WorkingSetSize}\n";
			  my @array = ($objItem->{Caption},
			  	 		   $capture_time->{'my_format'},
			  			   $start_date->{'my_format'},
				 		   $objItem->{ProcessId},
						   $objItem->{PageFaults},
						   $objItem->{PageFileUsage},
						   $objItem->{PeakPageFileUsage},
						   $objItem->{PeakVirtualSize},
						   $objItem->{PeakWorkingSetSize},
						   $objItem->{PrivatePageCount},
						   $objItem->{VirtualSize},
						   $objItem->{WorkingSetSize});

          push @AoA, [ @array ];
#	   print "Regex start: $2/$3/$1 $4:$5:$6\n" if $objItem->{CreationDate} =~ /(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/;
	   }
   $dexlog->Msg("End $computer.\n");
   print $OUTPUT "\n";
   print "End: $computer\n";
   $asize = @AoA;
   print "Size of array: $asize\n";


# print rows
for my $i ( 0 .. $#AoA ) {
    #print $OUTPUT2 "row $i is: @{$AoA[$i]}\n";
}

# rotate array so columns become rows
# works, autosize to rows and columns
for (my $starty = my $y = 0; $y <= $asize; $y++) {
	my $row = $AoA[$y];
	for (my $startx = my $x = 0; $x <= $#{$row}; $x++) {
        # swap columns and rows and append a comma
        # leaves a trailing comma :(
		$newAoA2[$x - $startx][$y - $starty] = $AoA[$y][$x] . ",";
    }
}

# works, autosize to rows and columns
for (my $starty = my $y = 0; $y <= $asize; $y++) {
	my $row = $AoA[$y];
	for (my $startx = my $x = 0; $x <= $#{$row}; $x++) {
        # swap columns and rows and append a comma
        # leaves a trailing comma :(
		if ( $x != $asize ) {
		   $newAoA3[$x - $startx][$y - $starty] = $AoA[$y][$x] . ",";
		}
		else
		{
		 	$newAoA3[$x - $startx][$y - $starty] = $AoA[$y][$x];
		}
    }
}

# print new rows
#for my $i ( 0 .. $#newAoA ) {
#    print $OUTPUT2 "NEW row $i is: @{$newAoA[$i]}\n";
    #print "NEW row $i is: @{$newAoA[$i]}\n";
#}

for my $i ( 0 .. $#newAoA2 ) {
    print $OUTPUT2 "NEW row2 $i is: @{$newAoA2[$i]}\n";
    #print "NEW row2 $i is: @{$newAoA2[$i]}\n";
}

for my $i ( 0 .. $#newAoA3 ) {
    print $OUTPUT2 "@{$newAoA3[$i]}\n";
    #print "NEW row3 $i is: @{$newAoA3[$i]}\n";
}

#transpose(@AoA);

for my $i ( 0 .. $#tempAoA ) {
    print $OUTPUT2 "NEW row4 $i is: @{$tempAoA[$i]}\n";
    #print "NEW row4 $i is: @{$tempAoA[$i]}\n";
}


} # close main loop

# not working, or not returning array
sub transpose {
	my @array = shift @_;
	my $size = @array;
	my @tempAoA = ();
	for (my $starty = my $y = 0; $y <= $size; $y++) {
    	my $row = $array[$y];
        for (my $startx = my $x = 0; $x <= $#{$row}; $x++) {
        	if ( $x != $size ) {
			$tempAoA[$x - $startx][$y - $starty] = $AoA[$y][$x] . ",";
			      }
			      else
			      {
				  $tempAoA[$x - $startx][$y - $starty] = $AoA[$y][$x];
				  }
        }
	}
    #return @tempAoA;
}

#my $seconds = utc2seconds(200407221405000);
sub utc2seconds {
	my $utc = shift @_;
	my $YYYY = substr($utc,0,4);
	my $MM = substr($utc,4,2);
	my $DD = substr($utc,6,2);
	my $hh = substr($utc,8,2);
	my $mm = substr($utc,10,2);
	my $ss = substr($utc,12,2);
	# off-by-one error in months portion, kludgey fix is to subtract 1
	return timelocal($ss,$mm,$hh,$DD,($MM-1),$YYYY);
}
