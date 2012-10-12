#!c:/perl/bin -w
#
# check_db.pl
#

use strict;
use diagnostics;
use warnings;

# include the logins file which contains the auth credentials
# include('wmi-logins.php');

# arguments
$host = $argv[1]; # hostname in form xxx.xxx.xxx.xxx
$credential = $argv[2]; # staff, web, other
$wmiclass = $argv[3]; # what wmic class to query in form Win32_ClassName
$columns = $argv[4]; # what columns to retrieve

$user = escapeshellarg($logins[$credential][0]); # escape the username
$pass = escapeshellarg($logins[$credential][1]); # escape the password <- very important with highly secure passwords

if (count($argv) > 5) { # if the number of arguments isnt above 5 then don't bother with the where = etc
	$condition_key = $argv[5];
	$condition_val = escapeshellarg($argv[6]);
} else {
	$condition_key = null;
};

# globals
$wmiexe = '/usr/local/bin/wmic'; # executable for the wmic command
$output = null; # by default the output is null

$wmiquery = 'SELECT '.$columns.' FROM '.$wmiclass; # basic query built
if ($condition_key != null) {
        $wmiquery = $wmiquery.' WHERE '.$condition_key.'='.$condition_val; # if the query has a filter argument add it in
};
$wmiquery = '"'.$wmiquery.'"'; # encapsulate the query in " "

$wmiexec = $wmiexe.' -U '.$user.'%'.$pass.' #'.$host.' '.$wmiquery; # setup the query to be run

#echo "\n\n".$wmiexec."\n\n"; # debug :)

exec($wmiexec,$wmiout); # execute the query

if (count($wmiout) > 0) {

$names = explode('|',$wmiout[1]); # build the names list to dymanically output it

for($i=2;$i<count($wmiout);$i++) { # dynamically output the key:value pairs to suit cacti
	$data = explode('|',$wmiout[$i]);
	$j=0;
	foreach($data as $item) {
		$output = $output.$names[$j++].':'.str_replace(':','',$item)." ";
	};
};

};

echo $output;

?>
