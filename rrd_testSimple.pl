#!c:/perl/bin -w
#
# rrd_test4.pl
#


use strict;
use RRD::Simple;
use Switch;
use Data::Dumper;
use Win32::OLE('in');
use Win32::ODBC;
use Date::EzDate;

my ( $epochstart, $epochend, $rrd_start, $rrd_end,$day, $date, $mydate, $dexlog, $DSN, $output, $SQLStatement, $URI, $Avg, $dateTime, $stem, $startdate, $enddate, $dir, $rrdupdate, $rrdtool_create, $step, $rra_list, $name, $server, $iisuser);
my ( @data, %data, $data, $key, $ds_list, $ds, $oldserver, $oldiisuser, $client );
my ( $client_list, @pop_array );
my ( $ds_data, $ds_data_list );

chomp($stem=<$ARGV[0]>);
chomp($startdate=<$ARGV[1]>);
chomp($enddate=<$ARGV[2]>);

# use the date before $startdate to prevent update errors
# using $startdate directly causes errors updating the time with no interval
# $epochstart = Date::EzDate->new( $startdate . " 00:00AM" ) - 1;
# $epochend = Date::EzDate->new( $enddate . " 00:00AM" );

$epochstart = Date::EzDate->new( $startdate );
$epochend = Date::EzDate->new( $enddate );
$rrd_start = Date::EzDate->new( $startdate )  - 1;
$rrd_end = Date::EzDate->new( $enddate ) + 1;

$rrdtool_create = "c:\\Dexma\\support\\Monitoring\\rrdtool.exe create ";
$rrdupdate = "c:\\Dexma\\support\\Monitoring\\rrdtool.exe update ";

#current connections rrd format
#day2-5-avg	AVERAGE:0.1:1:600
#week-5-avg	AVERAGE:0.1:6:336
#month-5-avg	AVERAGE:0.1:24:372
#3month-5-avg	AVERAGE:0.1:72:368
#year-5-avg	AVERAGE:0.1:288:365
#year3-5-avg	AVERAGE:0.1:288:1096
#year10-5-avg	AVERAGE:0.1:288:3652

# memory uasge rrd format
#RRA:AVERAGE:0.5:1:112   1 sample every 15 minutes, 112 records stored(28 hour history)
#RRA:AVERAGE:0.5:8:336   8 samples(2-hour average), 336 records stored(28 day history)
#RRA:AVERAGE:0.5:48:274  48 samples(12-hour average), 274 records stored(1.5 year history)
#RRA:AVERAGE:0.5:96:548 96 samples(24-hour average), 548 records stored(1.5 year history)


$dexlog = Win32::OLE->new('Dexma.Dexlog') or warn "Cannot create DexLog object $!\n";
$dexlog->SetProperty('ModuleName','rrd_testSimple');

$dir = "c:\\Dexma\\support\\Monitoring\\Test\\";


# select rrd files to fiddle with
unless (opendir DIR, $dir) {
	$dexlog->Msg("*** Can't open directory $dir: $! ***");
	next;
	}
chdir "$dir";
while ( my $tempfile= readdir DIR ) {
	if ( $tempfile=~m/.*\.rrd/ ) {
		#unlink $tempfile;
		print "RRD: " . $tempfile . "\n";
		my $rrd = RRD::Simple->new( file => "'$tempfile'", 
									rrdtool => "c:\\Dexma\\support\\Monitoring\\rrdtool.exe" );
		my @sources = $rrd->sources($tempfile);
		print "Current Sources: \n";
			foreach my $item ( in @sources ) {
				print "\t" . $item . "\n";
			}
		print "Adding a junk DS.\n";
		$rrd->add_source( $tempfile,junkieDS2 => "GAUGE" );
		my @sources2 = $rrd->sources($tempfile);
		print "Updated Sources: \n";
			foreach my $item ( in @sources2 ) {
				print "\t" . $item . "\n";
			}
	}
}

 # $rrd->add_source($rrdfile,
         # source_name => "TYPE"
     # );