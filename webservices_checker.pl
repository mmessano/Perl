#!c:/perl/bin -w
#
# webservices_checker.pl
#

use strict;
use diagnostics;
use warnings;
use IO::File;
use POSIX;
use Spreadsheet::WriteExcel;
use Switch;
use Win32::OLE qw(in);
use XML::Twig;
$Win32::OLE::Warn = 3;

my ( $server, $webconfig, $serviceurls, $dexlog );
my ( $obook, $outbook, $outsheet, $outsheet2, @header, @header2, $newrow_web, $newrow_ser );
my ( @servers );
my ( $webconfigpath, $servicepath, $Share, $Shares, $unc );

@servers = ( 'PAWeb5','PAWeb6', 'PAWeb7', 'PAWeb8', 'PAWeb9', 'PAWeb10', 'PAWeb11', 'PAWeb12' );

$webconfig = "\\WebSites\\MainSite\\WebUI\\Web.config";
$serviceurls = "\\WebSites\\MainSite\\admin\\xml\\ServiceURLs.xml";

my $twig = new XML::Twig( TwigHandlers => { '/configuration/appSettings/add' 	=> \&get_appSettings,
   		   	   			  			   	  	'/services/service' 	=> \&get_Services});


# spreadsheet to write to
$obook = "C:\\Dexma\\temp\\webservices_settings2.xls";
$outbook =  Spreadsheet::WriteExcel->new("$obook");
$outsheet = $outbook->add_worksheet('WebConfig');
$outsheet2 = $outbook->add_worksheet('ServicesURL');

# format definitions
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
   
# header row for WebConfig
@header =  (
			[ "Client", "File", "Site", "URL" ]
			);


# header row for ServicesURL
@header2 =  (
			[ "Client", "File", "Service", "Environment", "URL" ]
			);

# write the header and freeze the worksheet
$outsheet->write_col(0, 0, \@header, $header);
$outsheet->freeze_panes(1, 0);
$outsheet2->write_col(0, 0, \@header2, $header);
$outsheet2->freeze_panes(1, 0);
# increment for header row
$newrow_web = 1;
$newrow_ser = 1;

$dexlog = Win32::OLE->new('Dexma.Dexlog') or warn "Cannot create DexLog object $!\n";
$dexlog->SetProperty('ModuleName','webservices_checker');

foreach $server ( @servers ) {
	print "Server: " . $server . "\n";
	my $WMI = Win32::OLE->GetObject('winmgmts:\\\\' . $server . '\\root\\cimv2');
	$Shares = $WMI->InstancesOf('Win32_Share');

	foreach $Share (in $Shares) {
		if ( $Share->Name =~ m/\w.*\$/ || $Share->Name =~ m/Dexma/i || $Share->Name =~ m/VPHOME/i || $Share->Name =~ m/RelateProd/i || $Share->Name =~ m/Logfiles/i ) {
			#print "Non-client share found: " . $Share->Name . "\n";
			#print '  Type:        ' . $Share->Type, "\n";
		}
		else {
			$webconfigpath = "\\\\$server\\" . $Share->Name . $webconfig;
			$servicepath = "\\\\$server\\" . $Share->Name . $serviceurls;
			if ( -e $webconfigpath ) {
				$unc = $Share->Name;
				print "File: " . $webconfigpath . "\n";
				$twig->parsefile($webconfigpath);
			}

			if ( -e $servicepath ) {
				$unc = $Share->Name;
				print "File: " . $servicepath . "\n";
				$twig->parsefile($servicepath);
			}
			#$print "\n";
		}
	}
}

sub get_appSettings {
	$dexlog->Msg("Begin importing appSettings section.\n");
	my( $twig, $ename)= @_;
	my @attnames = $ename->att_names;
	if ( $ename->att_xml_string($attnames[0]) =~ m/Dexma/i ) {
		my @row =  (
                		[ $unc, $webconfigpath, $ename->att_xml_string($attnames[0]), $ename->att_xml_string($attnames[1]) ]
            		);
		$outsheet->write_col($newrow_web, 0, \@row);
		$newrow_web++;
		#print $attnames[0] . ":\t" . $ename->att_xml_string($attnames[0]) . "\n" . $attnames[1] . ":\t" . $ename->att_xml_string($attnames[1]) . "\n";
	}
	$dexlog->Msg("End importing appSettings section.\n");
}


sub get_Services {
	$dexlog->Msg("Begin importing Services section.\n");
	my( $twig, $ename)= @_;
	my @attnames = $ename->att_names;
	#print "Config section: " . $ename->att_xml_string($attnames[0]) . "\n";
	my @children= $ename->children;
	foreach my $child (@children) {
		my @attnames2 = $child->att_names;
		if ( $child->att_xml_string($attnames2[0]) =~ m/Prod/i ) {
			my @row =  (
                			[ $unc, $servicepath, $ename->att_xml_string($attnames[0]), $child->att_xml_string($attnames2[0]), $child->att_xml_string($attnames2[1]) ]
            				);
			$outsheet2->write_col($newrow_ser, 0, \@row);
			$newrow_ser++;
			#print "Environment: " . $child->att_xml_string($attnames2[0]) . "\tURL: " . $child->att_xml_string($attnames2[1]) . "\n";
		}
	}
	$dexlog->Msg("End importing Services section.\n");
}
