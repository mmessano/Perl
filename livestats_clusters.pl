#!c:/perl/bin -w
#
# livestats_clusters.pl
#

use strict;
use diagnostics;
use warnings;
use IO::File;
use File::Basename;
use XML::Twig;
use File::stat qw(:FIELDS);
use Spreadsheet::ParseExcel;
use Spreadsheet::WriteExcel;
package Excel;

# TODO
# if the spreadsheet exists, zero the worksheet, then write new data
# OR add a new sheet and write the data

my ( @row, $clusters, $dir, $Excel, @files, $file, @header, $logdirs, $logdirstext, $logdirstext1, $logdirstext2, $loginID, $loginIDtext, $name, $nametext, $newrow, $obook, $outbook, $outsheet, $path, $twig, $serverID, $url, $urltext, $wbook, $workbook, $worksheet, $iiscon );


$dir = "\\\\carina\\Livestats\\cfg";
$wbook = "C:\\Documents and Settings\\MMessano\\Desktop\\weblogs_directories.xls";
$obook = "C:\\Documents and Settings\\MMessano\\Desktop\\weblogs_directories_aggregate.xls";

$twig = new XML::Twig( TwigHandlers => {URL => \&get_url,
										Clusters => \&get_clusters,
										#LogDir => \&get_logdirs,
										LoginID => \&get_loginID
										}
										);

@header =  (
			["XFS3 Dir", "UNC Path(\\carina\Livestats\cfg)", "Filename", "Login ID", "URL", "Log Dir 1", "Log Dir 2"  ]
			);



$Excel = new Spreadsheet::ParseExcel;
$workbook = $Excel->Parse($wbook);
$worksheet = $workbook->{Worksheet}[0];

$outbook =  Spreadsheet::WriteExcel->new("$obook");
$outsheet = $outbook->add_worksheet();

$outsheet->write_col(0, 0, \@header);

# increment for header row
$newrow = 1;


opendir DIR, $dir or die "Can't open directory $dir: $!\n";
# grab file list from directory
@files = (readdir DIR);
	   foreach $file (@files) {
		   unless ( $file =~ /^\.+/ ) {
			   chdir $dir;
			   $path = "$dir\\$file";
			   $twig->parsefile($file);
               #print $loginIDtext . "\t";
			   #print $urltext . "\t";
			   #print $logdirstext . "\n";
			   &match_cell($loginIDtext, $file);
			   close $file;
		   }
}



sub match_cell() {
	# pass in the values from the cfg file
	my ($customer) = $_[0];
	my($Row, $Col, $cells);
	$file = $_[1];
	#print "Newrow #: " . $newrow . "\n";
	for(my $Row = $worksheet->{MinRow} ; defined $worksheet->{MaxRow} && $Row <= $worksheet->{MaxRow} ; $Row++)
	{
		$cells = $worksheet->{Cells}[$Row][1];
		if ( $cells->Value =~ /logs\\($customer)/ )
			{
				# create an array of the parsed values
				@row =  (
                		[$worksheet->{Cells}[$Row][0]->Value, $worksheet->{Cells}[$Row][1]->Value, $file, $loginIDtext, $urltext, $logdirstext1, $logdirstext2  ]
            			);
				# write the values out to the new spreadsheet using a reference to the above array
				$outsheet->write_col($newrow, 0, \@row);
			}
		else
			{
				#print "No match found for " . $customer . "!  Investigate please...\n";
			}
		#print "( $Row , 1 ) =>", $cells->Value, "\n" if($cells);
    }
	$newrow++;
}


sub get_logdirs {
	my $twig = $_[0];
	$logdirs = $_[1];
	$logdirstext = $logdirs->string_value;
	return $logdirstext;
}


sub get_clusters {
	my $twig = $_[0];
	$clusters = $_[1];
	if ( $clusters->children_count == 2 )
	{
        $logdirstext1 = $clusters->first_child_text;
        $logdirstext2 = $clusters->last_child_text;
		#print "First child: " . $clusters->first_child_text . "\n";
    	#print "Last child: " . $clusters->last_child_text . "\n";
	}
    else
    {
    	$logdirstext1 = $clusters->first_child_text;
        $logdirstext2 = "NULL";
		#print "Only child: " . $clusters->first_child_text . "\n";
	}
	return $logdirstext1, $logdirstext2;
}


sub get_url {
	my $twig = $_[0];
	$url = $_[1];
	$urltext = $url->string_value;
	return $urltext;
}


sub get_loginID {
	my $twig = $_[0];
	$loginID = $_[1];
	$loginIDtext = $loginID->string_value;
	return $loginIDtext;
}


sub enumwebsites {
	my ( $webserver );
	foreach $webserver ( in $iiscon ) {
		#print $webserver->Class . "\n";
		if ( $webserver->Class eq "IIsWebServer" ) {
		print "Site ID = " . $webserver->Name . "\t\t";
		print "Comment = " . $webserver->ServerComment . "\n";
		}
	}
}