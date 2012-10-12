#!c:/perl/bin -w
#
# create_freespace_rrd_dynamic.pl
#

use strict;
use diagnostics;
use warnings;
use Time::Local;
use Win32::ODBC;
use Win32::OLE('in');

use constant wbemFlagReturnImmediately => 0x10;
use constant wbemFlagForwardOnly => 0x20;

my ( @server, $rrdcreate, $rrdupdate, $Data, %Data, @data, $db, $dir, $ds, $ds_list, $DSN, $infile, $name, $partition, $rra_list, $server, $step, $start_time, $SQL );

my $argcount = @ARGV;


if ( $argcount < 1 ) {
	$infile = "\\\\mensa\\Dexma\\Support\\Monitoring\\Diskspace\\serverlist.txt";
	open(DAT, $infile) || die("Could not open $infile for reading!");
	@server = <DAT>;
}
else {
	@server = @ARGV;	
}

$rrdcreate = "C:\\Dexma\\support\\Monitoring\\rrdtool.exe create ";
$rrdupdate = "C:\\Dexma\\support\\Monitoring\\rrdtool.exe update ";
$dir = "C:\\Dexma\\support\\Monitoring\\Diskspace\\";
# December 1st, 2006 in seconds since epoch
$start_time = "1164992400";

# Set the DSN name
$DSN = new Win32::ODBC("status") or die "Error: " . Win32::ODBC::Error();

$SQL = "select server, partition, percentused, last_update, freespaceMB, totalMB from diskspace where server ='";


if ( ! ( $db = new Win32::ODBC($DSN ) ) ){
    print "Error connecting to $DSN\n";
    print "Error: " . Win32::ODBC::Error() . "\n";
    exit;
}


# diskspace rrd format
# 1st average happens every time with 56 samples for 28 day history
# 2nd average happens every 2 samples(24 hours) for 56 day history
# 3rd average happens every 14 samples(7 days) for 6 month history
# 4th average happens every 56 samples(1 month) for 1.5 year history



foreach $server ( @server ) {
	chomp $server;
	print "Server: " . $server . "\n";

	if ( $db->Sql($SQL . $server . "' order by 4 asc") ) {
		print "SQL failed.\n";
	    print "Error: " . $db->Error() . "\n";
	    $db->Close();
	    exit;
	}

	while($db->FetchRow()){
		undef %Data;
	    %Data = $db->DataHash();
		my ($year,$mon,$mday,$hour,$min,$sec) = ( $Data{last_update} =~ /(\d{4}?)-(\d{2}?)-(\d{2}?)\s(\d\d):(\d\d):(\d\d)/);
		my $epoch_seconds = ( timelocal($sec,$min,$hour,$mday,$mon-1,$year) );
		( $partition )= ( $Data{partition} =~ /(\w)/ );
        $name = $server  . "_" . $partition . "_diskspace_dyn.rrd ";
        
        # run every 12 hours
		$step = " --step 43200 --start $start_time";
		$rra_list = " DS:" . $partition . ":DERIVE:43200:0:" . $Data{totalMB} ."
			RRA:AVERAGE:0.5:1:56
			RRA:AVERAGE:0.5:2:56
			RRA:AVERAGE:0.5:14:26
			RRA:AVERAGE:0.5:56:18
			RRA:MAX:0.5:1:56
			RRA:MAX:0.5:8:56
			RRA:MAX:0.5:24:26
			RRA:MAX:0.5:56:18";

		# create the rrd if it does not exist
		if ( ! -e ("$dir" . "$name") ) {
			system "$rrdcreate" . "$dir" . "$name" . "$step" . "$rra_list";
		}
		else {
			#print "File exists, skipping creation...\n";
		}
		my $bytes = ( $Data{totalMB} - $Data{freespaceMB} ) * 1024;
	    #print "$rrdupdate" . "$dir" . "$name" . "-t $partition " . "$epoch_seconds:$bytes\n";
		system "$rrdupdate" . "$dir" . "$name" . "-t $partition " . "$epoch_seconds:$bytes";
	}
}

$db->Close();