#!c:/perl/bin -w
#
# update_servers_in_database.pl
#

use strict;
use diagnostics;
use warnings;
use Win32::NetAdmin;
use POSIX;
use IO::File;
use Win32::ODBC;
use win32::ADO;
use Win32::OLE::Const 'Microsoft ActiveX Data Objects 2.5';

my (@domains, $domain, $outfile, $OUTPUT, $machine, @machines, $line, $pdc, $server, $DSN, %SQL_Errors, $SQL_ins, $failure_file, $FAILURES, $ErrNum, $ErrText, $ErrConn);

$DSN = new Win32::ODBC("status") or die "Error: " . Win32::ODBC::Error();

%SQL_Errors = (server=>'', file=>'', name=>'', SQLState=>'', Number=>'', Text=>'');

# Trailing space is necessary!
$SQL_ins = "exec sp_ins_server ";    #	@server_name varchar(50), @environment_id int, @description varchar, @active int

#@domains = ('home_office','ft_commhub','dexma','webedco','workgroup');
@domains = ('home_office','ft_commhub','dexma');


foreach $domain (@domains) {
	$outfile = "\\\\messano338\\dexma\\" .$domain . "_machinelist.txt";
	$failure_file = "\\\\messano338\\dexma\\" .$domain . "_errors.txt";
	if (-e $outfile){unlink $outfile;}
			unless (Win32::NetAdmin::GetDomainController("", $domain, $pdc)) {warn "Unable to determine/access PDC($pdc) for $domain.";}
			unless (Win32::NetAdmin::GetServers($pdc, $domain, SV_TYPE_NT, \@machines)) {print "Unable to read anything.";}
			$OUTPUT = IO::File->new($outfile, ">>") or warn "Cannot open $outfile! $!\n";
	 		 foreach $machine (@machines) {
#				print "$machine\n";
				print $OUTPUT "$machine\n";
				if (-e $failure_file){unlink $failure_file;}
				   if ($DSN->Sql($SQL_ins . "'" . $machine . "'" . "," . "'" . 11 . "'" . "," . "'" . "Unknown" . "'"  . "," . "'" . 1 . "'"))
                        {
						($ErrNum, $ErrText, $ErrConn) = $DSN->Error();
						$FAILURES = IO::File->new($failure_file, ">>") or warn "Cannot open $failure_file! $!\n";
						print $FAILURES "Machine: $machine\n";
						print $FAILURES "SQL error: $ErrConn\n";
						print $FAILURES "ErrorNum: $ErrNum\n";
						print $FAILURES "Text: $ErrText\n\n";
	                  }
					if ($machine =~ /(\w+\d{3,}$)/) {
#					if ($machine =~ /(^\\\\)(\w+\d{3,}$)/) {
						#print "$machine is a workstation\n";
						}
				}
				print "\n";
					  if ( ! stat($failure_file)){
#					  warn "$failure_file: $!\n"
					  }
		        else {
				close $FAILURES;
				system ("c:\\dexma\\bin\\blat $failure_file -t mmessano\@primealliancesolutions.com -subject \"SQL inserts for $machine have failed.\" " or die "$!\n");
			}
				close $OUTPUT;
#				close $FAILURES;
}

