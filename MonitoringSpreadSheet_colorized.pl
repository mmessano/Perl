#!c:/perl/bin -w
#
# MonitoringSpreadSheet_colorized.pl
#

# When updating with new columns:
# Add to select statement
# Add to header definition
# Add to main loop as an elsif
# Adjust the column width section

use strict;
use diagnostics;
use warnings;
use feature 'say';
use feature 'switch';
use Spreadsheet::WriteExcel;
use Win32::ODBC;
use Win32::OLE::Const 'Microsoft ActiveX Data Objects 2.5';

my ( $dexlog );
my ( $obook, $outbook, $outsheet, @header, %header, $newrow );
my ( $DSN, $SQLSEL, $ErrNum, $ErrText, $ErrConn, @Data, @row );
my ( %Data, $Data );

# spreadsheet to write to
$obook = "E:\\Dexma\\Logs\\MonitoredServers.xls";
#$obook = "\\\\pwebutil20\\Relateprod\\Prodops.dexma.com\\Monitoring\\MonitoredServers.xls";

$outbook =  Spreadsheet::WriteExcel->new("$obook");
$outsheet = $outbook->add_worksheet();

# format definitions
my %header_row = (
	font 		=>	'Arial',
	size 		=>	'14',
	bg_color 	=>	'55',
	bold 		=>	'1',
	align		=>	'center',
	rotation	=>	'90'
	);

my %disabled = (
	bg_color	=>	'yellow',
	bold 		=>	'1',
	align		=>	'center'
	);

my %enabled = (
	bg_color	=>	'green',
	align		=>	'center'
	);

my %undefined = (
	bg_color	=>	'red',
	align		=>	'center'
	);

# row formats
my $header = $outbook->add_format();
   $header->set_properties(%header_row);
my $disabled = $outbook->add_format();
   $disabled->set_properties(%disabled);
my $enabled = $outbook->add_format();
   $enabled->set_properties(%enabled);
my $undefined = $outbook->add_format();
   $undefined->set_properties(%undefined);

# header row
@header =  (
	[ "Server", "Env", "DSN", "DCOM", "SchedTasks", "PerfMon", "IISSites", "DRM", "Active" ]
	);

# set the column widths
# write the header and freeze the worksheet
$outsheet->set_column(0, 0,  17.5);
$outsheet->set_column(1, 1,  9);
$outsheet->set_column(2, 12,  3);
$outsheet->write_col(0, 0, \@header, $header);
$outsheet->freeze_panes(1, 0);

# increment for header row
$newrow = 1;

# suppress errors on connection failure
Win32::OLE->Option(Warn => 0);

$DSN = new Win32::ODBC("status") or die "Error: " . Win32::ODBC::Error();

$dexlog = Win32::OLE->new('Dexma.Dexlog') or warn "Cannot create DexLog object $!\n";
$dexlog->SetProperty('ModuleName','MonitoringSpreadSheet');


$SQLSEL = "select s.server_name AS Server, \
		  e.environment_name AS Env, \
		  m.dsn AS DSN, \
		  m.dcom AS DCOM, \
		  m.sched_tasks AS SchedTasks, \
		  m.Perfmon AS PerfMon, \
		  m.IISSites AS IISSites, \
    		  m.DRM AS DRM, \
		  s.active AS Active \
		  from dbo.t_monitoring m FULL OUTER JOIN \
		  dbo.t_server s ON s.server_id = m.server_id FULL OUTER JOIN \
		  dbo.t_environment e ON s.environment_id = e.environment_id \
		  where s.active = '1' \
		  and e.environment_name NOT IN ('Workstation', 'Infrastructure', 'Non Dexma') \
		  AND s.server_name not like '%.dexma.com' \
		  order by s.server_name asc";


# select data
if ( $DSN->Sql($SQLSEL) ) {
	($ErrNum, $ErrText, $ErrConn) = $DSN->Error();
		print  "SQL error: $ErrConn\n";
		print  "ErrorNum: $ErrNum\n";
		print  "Text: $ErrText\n\n";
		$DSN->Close();
		exit;
}

say "Begin updating spreadsheet...\n";

while( $DSN->FetchRow() ) {
 	%Data = $DSN->DataHash();
 	while ( my $item = each %Data ) {
	      if ( $item eq 'Server' ) {
		  $outsheet->write($newrow,0,$Data{$item});
	      }
	      elsif ( $item eq 'Env' ) {
                  $outsheet->write($newrow,1,$Data{$item});
	      }
	      elsif ( $item eq 'DSN' ) {
	      	  &color($Data{$item},2);
	      }
	      elsif ( $item eq 'DCOM' ) {
	      	  &color($Data{$item},3);
	      }
	      elsif ( $item eq 'SchedTasks' ) {
	      	  &color($Data{$item},4);
	      }
	      elsif ( $item eq 'PerfMon' ) {
	      	  &color($Data{$item},5);
	      }
	      elsif ( $item eq 'IISSites' ) {
	      	  &color($Data{$item},6);
	      }
	      elsif ( $item eq 'DRM' ) {
	      	  &color($Data{$item},7);
	      }
	      elsif ( $item eq 'Active' ) {
	      	  &color($Data{$item},8);
	      }
	}
	$newrow++;
}

say "Done updating spreadsheet...\n";

$DSN->Close();

sub color {
	my $obj = shift;
	my $col = shift;
	if ( ! defined($obj) ) {
		$outsheet->write($newrow,$col,$obj,$undefined);
	}
	else {
		if ( $obj == '0' ) {
			$outsheet->write($newrow,$col,$obj,$disabled);
		}
		elsif ( $obj == '1' ) {
			$outsheet->write($newrow,$col,$obj,$enabled);
		}
	}
}