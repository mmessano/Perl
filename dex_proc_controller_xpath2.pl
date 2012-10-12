#!c:/perl/bin -w
#
# dex_proc_controller_xpath.pl
#

use strict;
use diagnostics;
use warnings;
use Win32::ODBC;
use win32::ADO;
use Win32::OLE::Const 'Microsoft ActiveX Data Objects 2.5';
use IO::File;
use XML::XPath;
use XML::XPath::XMLParser;
use File::stat qw(:FIELDS);

my ($stat, $OUTPUT, $count, $self, $file, $failure_file, $failed, $line, $server, $ARGV, %line, $SQL, $DSN, @SQL_Errors, $SQL_Errors, %SQL_Errors, $ErrNum, $ErrText, $ErrConn);

# Set the DSN name
$DSN = new Win32::ODBC("ops_support") or die "Error: " . Win32::ODBC::Error();

# Set the name of the stored procedure to run
# The trailing space is important!!!
$SQL = "exec sp_upd_proc_controller_assoc ";

%line = (name=>'',cmdLine=>'',autoStart=>'',desktop=>'',domain=>'',username=>'');
%SQL_Errors = (server=>'', file=>'', name=>'', SQLState=>'', Number=>'', Text=>'');

my $infile = "\\\\mensa\\Dexma\\Data\\ALL_app.txt";
open(DAT, $infile) || die("Could not open $infile for reading!");
my @machines = <DAT>;

# Truncate table
$DSN->Sql("truncate table t_proc_controller_assoc");


&get_configs(@machines);


sub get_configs {
	foreach $ARGV (@machines) {
		$server = $ARGV;
		chomp $server;
		$file = "\\\\$server\\dexma\\data\\DexProcessControllerConfig.xml";
		$failure_file = "\\\\messano338\\dexma\\temp\\" .$server . "_failures.txt";
		my $dexlog = Win32::OLE->new('Dexma.Dexlog') or warn "Cannot create DexLog object $!\n";
		$dexlog->ModuleName("dex_proc_controller");
		$dexlog->Msg("Begin $server.\n");
		if (-e $file) {
			chomp $file;
			my $parser = XML::XPath->new(filename => $file);
			my $nodeset = $parser->find('//process') or warn "\nCannot open $file! $!\n";
			$count=0;
			$failed=0;
			print "\nDeleting records for $server from the t_procs_controller_assoc table!\n\n";
			$DSN->Sql("delete from t_proc_controller_assoc where server_id = (select server_id from t_server where server_name = '$server')");
				foreach my $node ($nodeset->get_nodelist) {
						$line->{name}= $node->getAttribute('name');
						$line->{cmdLine}= $node->getAttribute('cmdLine');
						$line->{autoStart}= $node->getAttribute('autoStart');
						$line->{desktop}= $node->getAttribute('desktop');
						$line->{domain}= $node->getAttribute('domain');
						$line->{userName}= $node->getAttribute('userName');
					if ($DSN->Sql($SQL . $server . "," . "'" . $line->{name} . "'" . "," . "'" . $line->{cmdLine} . "'"  . "," . "'" . $line->{autoStart} . "'" . "," . "'" . $line->{desktop} . "'" . "," . "'" . $line->{domain} . "'" . "," . "'" . $line->{userName} . "'"))
						{
						($ErrNum, $ErrText, $ErrConn) = $DSN->Error();
						$failed++;
						$OUTPUT = IO::File->new($failure_file, ">>") or warn "Cannot open $failure_file! $!\n";
						print $OUTPUT "Fail count: $failed\n";
						print $OUTPUT "Server: $server\n";
						print $OUTPUT "File: $file\n\n";
						print $OUTPUT "Line name: $line->{name}\n";
						print $OUTPUT "SQL error: $ErrConn\n";
						print $OUTPUT "ErrorNum: $ErrNum\n";
						print $OUTPUT "Text: $ErrText\n\n";
						$dexlog->Msg("Fail count: $failed\n");
						$dexlog->Msg("Server: $server\n");
						$dexlog->Msg("File: $file\n\n");
						$dexlog->Msg("Line name: $line->{name}\n");
						$dexlog->Msg("SQL error: $ErrConn\n");
						$dexlog->Msg("ErrorNum: $ErrNum\n");
						$dexlog->Msg("Text: $ErrText\n\n");
						}
				$count++;
				}
		print "\n";
			if ( ! stat($failure_file))
			{
				warn "$failure_file: $!\n"
			}
			else 
			{
				print $OUTPUT "Total nodes found for $server: $count\n";
				print $OUTPUT "Total failed inserts: $failed\n";
				close $OUTPUT;
				$dexlog->Msg("Total nodes found for $server: $count\n");
				$dexlog->Msg("Total failed inserts: $failed\n");
				system ("c:\\dexma\\bin\\blat $failure_file -t mmessano\@primealliancesolutions.com -subject \"SQL inserts for $server have failed.\" " or die "$!\n");
				unlink ($failure_file);
			}
		}
		else {
#			print "\n";
			print "\nCannot open $file! $!\n"
			}
	$dexlog->Msg("End $server.\n");
	}
}

$DSN->Close();
