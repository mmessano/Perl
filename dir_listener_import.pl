#!c:/perl/bin/perl.exe -w
# C:\Documents and Settings\mmessano\Desktop\InProgress\directory_listener\prod\DirectoryListener_mjmtest.xml
# usage: perl dir_listener_import.pl <filename>

use strict;
use diagnostics;
use warnings;
use Win32::ODBC;
use IO::File;
use XML::Twig;
use File::stat qw(:FIELDS);
use Switch;
use Win32::OLE('in');

my ($SQL, $SQL_trunc, $file, $DSN, $dexlog, $name, @files,
   	@dirs, $dir, $clientname, $method, $path,
	$description, $queueServer, $queueName,
	$searchDirectory,	$filePattern, $progID, $altLabel,
	$backupDir,	$interval, $mtsKillTime,
	$writeFileName,	$sendDirect, $backupFileExt,
	$logDirectory,	$dir_listener, $children,
	$ErrNum, $ErrText, $ErrConn);

# Set the DSN name
$DSN = new Win32::ODBC("status") or die "Error: " . Win32::ODBC::Error();

# Set the name of the stored procedure to run
# The trailing space is important!!!
$SQL = "exec sp_ins_dir_listener ";
# stored proc to truncate the table
$SQL_trunc = "exec sp_trunc_dir_listener ";

@dirs = ('\\\\mensa\\VSS\\ConfigFiles\\ConnectionConfigFiles\\Environment\\PROD','\\\\mensa\\VSS\\ConfigFiles\\ConnectionConfigFiles\\Environment\\DEMO','\\\\mensa\\VSS\\ConfigFiles\\ConnectionConfigFiles\\Environment\\IMP');

$dexlog = Win32::OLE->new('Dexma.Dexlog') or warn "Cannot create DexLog object $!\n";
$dexlog->SetProperty('ModuleName','dl_import');


my %dir_listener = (clientname=>'',
					method=>'',
					environment=>'',
					description=>'',
					queueServer=>'',
					queueName=>'',
					searchDirectory=>'',
					filePattern=>'',
					progID=>'',
					altLabel=>'',
					backupDir=>'',
					interval=>'',
					mtsKillTime=>'',
					writeFileName=>'',
					sendDirect=>'',
					backupFileExt=>'',
					logDirectory=>'');


my $twig = new XML::Twig( TwigHandlers => { '/dexma.directoryListener.ini/DirectoryListener' => \&get_dl_data,
   		   	   			  			   	  	 'opsdlinfo' => \&get_ops_info});

# truncate table t_dir_listener and t_dir_monitor
$DSN->Sql($SQL_trunc);

foreach $dir (@dirs) {
	opendir DIR, $dir or die "Can't open directory $dir: $!\n";
	# grab file list from directory
	@files = (readdir DIR);
		   foreach $file (@files) {
			   unless ($file =~ /^\.+/ or $file =~ /vssver.scc/) {
				   chdir $dir;
				   #foreach $ARGV (@ARGV) {
				   #$file= $ARGV;
				   $path = "$dir\\$file";
				   $dexlog->Msg("Begin import of $dir\\$file.\n");
				   #print "Opening $path for parsing...\n";
				   $twig->parsefile($file);
				   $dexlog->Msg("End import of $dir\\$file.\n");
				   close $file;
			   }
#}
}
}
sub get_dl_data {
	$dexlog->Msg("Begin section import.\n");
	my( $twig, $ename)= @_;
#	my $element= $ename;
	my @children= $ename->children;
#	print "ename: $ename\n";
	foreach my $child (@children) {
		my $text = $child->string_value;
		my $name = $child->name;
#		print $name . "->\t\t" . $text . "\n";

		switch ($name) {
				case "queueServer" 		{ if (  $text ne '' ) { $dir_listener->{queueServer} = $text} else {$dir_listener->{queueServer}='undefined'}; }
				case "queueName" 		{ if (  $text ne '' ) { $dir_listener->{queueName}	 = $text} else {$dir_listener->{queueName}='undefined'}; }
				case "searchDirectory" 	{ $dir_listener->{searchDirectory}= $text; }
				case "filePattern" 		{ $dir_listener->{filePattern}= $text; }
				case "progID" 			{ $dir_listener->{progID}= $text; }
				case "altLabel" 		{ $dir_listener->{altLabel}= $text; }
				case "backupDir" 		{ $dir_listener->{backupDir}= $text; }
				case "interval" 		{ $dir_listener->{interval}= $text; }
				case "mtsKillTime" 		{ $dir_listener->{mtsKillTime}= $text; }
				case "writeFileName" 	{ $dir_listener->{writeFileName}= $text; }
				case "sendDirect" 		{ $dir_listener->{sendDirect}= $text; }
				case "backupFileExt" 	{ $dir_listener->{backupFileExt}= $text; }
				case "logDirectory" 	{ $dir_listener->{logDirectory}= $text; }
			}

   }
					if ($DSN->Sql($SQL . "'" . $dir_listener->{clientname}
						. "'" . "," . "'" . $dir_listener->{queueServer}
						. "'" . "," . "'" . $dir_listener->{queueName}
						. "'" . "," . "'" . $dir_listener->{method}
						. "'" . "," . "'" . $dir_listener->{environment}
						. "'" . "," . "'" . $dir_listener->{description}
						. "'" . "," . "'" . $dir_listener->{searchDirectory}
						. "'" . "," . "'" . $dir_listener->{filePattern}
						. "'" . "," . "'" . $dir_listener->{progID}
						. "'" . "," . "'" . $dir_listener->{altLabel}
						. "'" . "," . "'" . $dir_listener->{backupDir}
						. "'" . "," . "'" . $dir_listener->{interval}
						. "'" . "," . "'" . $dir_listener->{mtsKillTime}
						. "'" . "," . "'" . $dir_listener->{writeFileName}
						. "'" . "," . "'" . $dir_listener->{sendDirect}
						. "'" . "," . "'" . $dir_listener->{backupFileExt}
						. "'" . "," . "'" . $dir_listener->{logDirectory}
						. "'" . "," . "'" . $dir_listener->{home_server}
						. "'" . "," . "'" . $dir_listener->{monitored}
						. "'" . "," . "'" . $dir_listener->{threshold}
						. "'" . "," . "'" . $dir_listener->{exclusions}
						. "'" . "," . "'" . $path . "'"))
						{
							($ErrNum, $ErrText, $ErrConn) = $DSN->Error();
							print "SQL insert failed!\n";
							print "$ErrNum\n";
							print "$ErrText\n";
							print "$ErrConn\n";
						}
            $dexlog->Msg("End section import.\n");
			$twig->purge;
}

sub get_ops_info {
	$dexlog->Msg("Begin importing Ops section.\n");
	my( $twig, $ename)= @_;
	my @attributes = $ename->att_names;
	foreach my $atts (@attributes) {
	    my $text = $ename->att_xml_string($atts);
	    switch ($atts) {
				case "clientname"		{ $dir_listener->{clientname}= $text; }
				case "method" 			{ $dir_listener->{method}= $text; }
                case "environment" 		{ $dir_listener->{environment}= $text; }
				case "description" 		{ $dir_listener->{description}= $text; }
				case "home_server" 		{ if (  $text ne '' ) { $dir_listener->{home_server}= $text;} else {$dir_listener->{home_server}='unknown'}; }
				case "threshold" 		{ if (  $text ne '' ) { $dir_listener->{threshold}= $text;} else {$dir_listener->{threshold}='0'}; }
				case "exclusions" 		{ if (  $text ne '' ) { $dir_listener->{exclusions}= $text;} else {$dir_listener->{exclusions}='undefined'}; }
				case "monitored" 		{ if (  $text ne '' ) { $dir_listener->{monitored}= $text;} else {$dir_listener->{monitored}='0'}; }
				}
#	    print "Attribute name: $atts \t Attribute text: $text\n";
		}
		$dexlog->Msg("End importing Ops section.\n");
	}

