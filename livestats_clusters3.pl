#!c:/perl/bin -w
#
# livestats_clusters3.pl
#

use strict;
use diagnostics;
use warnings;
use IO::File;
use File::Basename;
use Win32::ODBC;
use XML::Twig;
use File::stat qw(:FIELDS);


# TODO
# if the spreadsheet exists, zero the worksheet, then write new data
# OR add a new sheet and write the data

my ( $clusters, $dir, @files, $file, $logdirs, $logdirstext, $logdirstext1, $logdirstext2, $loginID, $loginIDtext, $name, $nametext, $newrow, $path, $twig, $serverID, $url, $urltext, $server_id );
my ( $DSN, $SQL, $ErrNum, $ErrText, $ErrConn );


$dir = "\\\\carina\\Livestats\\cfg";

$DSN = new Win32::ODBC("status") or die "Error: " . Win32::ODBC::Error();
$SQL = "sp_ins_livestats_cfg ";


$twig = new XML::Twig( TwigHandlers => {URL => \&get_url,
										Clusters => \&get_clusters,
										LoginID => \&get_loginID
										}
										);


# truncate table t_livestats_cfg
$DSN->Sql("truncate table t_livestats_cfg");

opendir DIR, $dir or die "Can't open directory $dir: $!\n";
# grab file list from directory
@files = (readdir DIR);
	   foreach $file ( @files ) {
		   unless ( $file =~ /^\.+/ ) {
			   # null variables just in case
               ( $loginIDtext, $urltext, $logdirstext1, $logdirstext2 ) = "";
			   $path = "$dir\\$file";
			   $twig->parsefile($path);
			   $server_id = $1 if $file =~ /(\d[0-9]*)/;
               #print $loginIDtext . "\t";
			   #print $urltext . "\t";
			   #print $logdirstext1 . "\t" . $logdirstext2 . "\n";
			   
			   if ( $DSN->Sql( $SQL . "'" . $server_id . "'" . "," . "'" . $loginIDtext . "'" . "," . "'" . $urltext . "'" . "," . "'" . $logdirstext1 . "'"  . "," . "'" . $logdirstext2 . "'" ) )
                        {
						($ErrNum, $ErrText, $ErrConn) = $DSN->Error();
						print  "SQL error: $ErrConn\n";
						print  "ErrorNum: $ErrNum\n";
						print  "Text: $ErrText\n\n";
	                    }

			   close $file;
		   }
}


sub get_clusters {
	my $twig = $_[0];
	$clusters = $_[1];
	if ( $clusters->children_count == 2 )
	{
        $logdirstext1 = $clusters->first_child_text;
        $logdirstext2 = $clusters->last_child_text;
	}
    else
    {
    	$logdirstext1 = $clusters->first_child_text;
        $logdirstext2 = "";
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
