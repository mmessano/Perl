#!c:/perl/bin -w
#
# dsn_list.pl
#

use strict;
use diagnostics;
use warnings;
use Win32::ODBC;
use Win32::OLE('in');
use Win32::Registry;
use Switch;
use IO::File;
use File::stat qw(:FIELDS);


my ( $reg_node, $hkey, $key_list, $key, %RegType, $value, %values, $name, $SQL, %dsn_info, $dsn_info, $nkey, $machine, $node, $ErrNum, $ErrText, $ErrConn, $DSN, $OUTPUT, $failure_file );

my $infile = "\\\\mensa\\Dexma\\Data\\ALL_Active.txt";
#my $infile = "\\\\mensa\\Dexma\\Data\\dsn_failed_machines.txt";
open(DAT, $infile) || die("Could not open $infile for reading!");
my @machines = <DAT>;
chomp @machines;
#print @machines;

# Trailing space is necessary!
# parameter list:  	@dsn_name varchar(32), @server_name varchar(32), @remote_server_name varchar(32), @database_name varchar(50), @description varchar(64)
$SQL= "exec sp_ins_dsn ";
$DSN = new Win32::ODBC("status") or die "Error: " . Win32::ODBC::Error();



%dsn_info = (dsn_name=>'', r_server=>'', server=>'', database=>'', description=>'');

%RegType = (
			0 => 'REG_0',
			1 => 'REG_SZ',
			2 => 'REG_EXPAND_SZ',
			3 => 'REG_BINARY',
			4 => 'REG_DWORD',
			5 => 'REG_DWORD_BIG_ENDIAN',
			6 => 'REG_LINK',
			7 => 'REG_MULTI_SZ',
			8 => 'REG_RESOURCE_LIST',
			9 => 'REG_FULL_RESOURCE_DESCRIPTION',
			10 => 'REG_RESSOURCE_REQUIREMENT_MAP');



# registry node
$reg_node = "Software\\ODBC\\ODBC.INI"; 

# Truncate table
$DSN->Sql("truncate table t_dsn");


my $dexlog = Win32::OLE->new('Dexma.Dexlog') or warn "Cannot create DexLog object $!\n";
$dexlog->SetProperty('ModuleName','dsn_list');



foreach $machine (@machines) {
	#print "$machine\n";
	$dexlog->Msg("Begin $machine.\n");
	#chomp $machine;
	$dsn_info->{server} = $machine;
	$node = "\\\\$machine";
	if ($HKEY_LOCAL_MACHINE->Connect($node,$nkey) && $nkey->Open($reg_node,$hkey))
	   {
	   &extract_keys($hkey);
	   
	   }
	   else
	   {
	   $failure_file = "\\\\mensa\\dexma\\logs\\" .$dsn_info->{server} . "_reg_failure.txt";
       $OUTPUT = IO::File->new($failure_file, ">>") or warn "Cannot open $failure_file! $!\n";
       print $OUTPUT "Cannot connect to $node\\$reg_node: $!\n";
       $dexlog->Msg("Cannot connect to $node\\$reg_node: $!\n");
	   warn "Cannot connect to $node\\$reg_node: $!\n";
	   }
	#print "$hkey\n";
    if ( ! stat($failure_file))
				{
					#print "warn loop\n";
					#warn "$failure_file: $!\n"
				}
				else
				{
					#print "Email loop\n";
					close $OUTPUT;
					switch ($failure_file) 
						   {
						   case /(.*reg_failure.*)/ { system ("e:\\dexma\\thirdparty\\blat $failure_file -t mmessano\@primealliancesolutions.com -subject \"Registry access to $dsn_info->{server} has failed.\" " or die "$!\n"); }
						   case /(.*dsn_import.*)/  { system ("e:\\dexma\\thirdparty\\blat $failure_file -t mmessano\@primealliancesolutions.com -subject \"DSN SQL inserts for $dsn_info->{server} have failed.\" " or die "$!\n"); }
						   }
					unlink ($failure_file);
				}
$dexlog->Msg("End $machine.\n");
}
#---------------------------------------
#Extract the subkeys of a specified key
#---------------------------------------

sub extract_keys {
	my ($hkey) = @_;
	my ($newkey,@key_list,$key);
	&extract_values($hkey,$name);	# get the values of the current key
	$hkey->GetKeys(\@key_list);   # key the list of its subkeys
	foreach $key (@key_list) {	   # loop thru the list
		# hack job to not import dynamic DSN's which are 32 characters in length (they are also uppercase with numbers, but a predictable regex is difficult)
		# also exclude the ODBC DSN's
		if ($key =~ m/(ODBC.*)/) {
 		   #print "Match found: $key\n";
 		   }
		else
		{
		if ($key ne "" && (length $key != 32)) {
            $dsn_info->{dsn_name}= $key;
			#print "DSN Key: $key\n";
			if ( $hkey->Open($key, $newkey)) # open the subkey
				{
				&extract_keys($newkey);	# recurse
				}
			}
		}
	}
	$hkey->Close();	   # Clean work !

}

#---------------------------------------
#Extract the values of a specified key
#---------------------------------------
sub extract_values {
	my ($hkey,$key) = @_;
	my ($vkey,%value,$RegType,$RegData,$RegValue);

	$hkey->GetValues(\%values);	 # Get hash with the values

	foreach $value (%values) 
	{	 # loop thru the hash
		$RegType 	= $values{$value}->[1];		# Type of the value
		$RegData	= $values{$value}->[2];		# Value
		$RegValue 	= $values{$value}->[0];		# Name of the value

		if ( $RegType ne '')
		{
		$RegValue = 'Default' if ($RegValue eq '');	# name the default key
		switch ($RegValue) {
				case "Server"  	 			{ $dsn_info->{r_server}= $RegData; }
				case "Database"				{ $dsn_info->{database}= $RegData; }
				case "Description"			{ $dsn_info->{description}= $RegData; }
				}
		}
		else
		{
		#print "null value of regtype\n";
		# ignore null values
		}
		#print "\t$RegValue \t:\t $RegData\n";
	}
	#print "DSN Name: $dsn_info->{dsn_name}\nRemote Server: $dsn_info->{r_server}\nDatabase: $dsn_info->{database}\nDescription: $dsn_info->{description}\n";
	# update the database
	# parameter list:  	@dsn_name varchar(32), @server_name varchar(32), @remote_server_name varchar(32), @database_name varchar(50), @description varchar(64)
	if (  $dsn_info->{r_server} ne '')
		{
	    if ($DSN->Sql($SQL . "'" . $dsn_info->{dsn_name}
								   . "'" . "," . "'" . $dsn_info->{server}
								   . "'" . "," . "'" . $dsn_info->{r_server}
								   . "'" . "," . "'" . $dsn_info->{database}
								   . "'" . "," . "'" . $dsn_info->{description}
								    . "'"))
								   {
										($ErrNum, $ErrText, $ErrConn) = $DSN->Error();
										$failure_file = "\\\\mensa\\dexma\\logs\\" .$dsn_info->{server} . "_dsn_import_failure.txt";
										$OUTPUT = IO::File->new($failure_file, ">>") or warn "Cannot open $failure_file! $!\n";
										print $OUTPUT "Server: $dsn_info->{server}\n";
										print $OUTPUT "SQL error: $ErrConn\n";
										print $OUTPUT "ErrorNum: $ErrNum\n";
										print $OUTPUT "Text: $ErrText\n";
										print $OUTPUT "\n";
										print $OUTPUT "Server Name: $dsn_info->{server}\nDSN Name: $dsn_info->{dsn_name}\nRemote Server: $dsn_info->{r_server}\nDatabase: $dsn_info->{database}\nDescription: $dsn_info->{description}\n";
										print $OUTPUT "\n\n";
										$dexlog->Msg("Server: $dsn_info->{server}\n");
										$dexlog->Msg("SQL error: $ErrConn\n");
										$dexlog->Msg("ErrorNum: $ErrNum\n");
										$dexlog->Msg("Text: $ErrText\n");
										$dexlog->Msg("\n");
										$dexlog->Msg("Server Name: $dsn_info->{server}\n");
										$dexlog->Msg("DSN Name: $dsn_info->{dsn_name}\n");
										$dexlog->Msg("Remote Server: $dsn_info->{r_server}\n");
										$dexlog->Msg("Database: $dsn_info->{database}\n");
										$dexlog->Msg("Description: $dsn_info->{description}\n");
									}
	    
	
		}
	else
	{
    #print "zero value for r_server\n";
	# don't update database with null values
    }
	undef %values;
}




# custom function to connect to a remote registry
# Hack by Michael Frederick
sub Connect
{
	my $self = shift;

	if( $#_ != 1 )
		{
		die 'usage: Connect( $Node, $ObjRef )';
		}

	my ($Node) = @_;
	my ($Result,$SubHandle);

	$Result = RegConnectRegistry ($Node, $self->{'handle'}, $SubHandle);
	$_[1] = _new( $SubHandle );

	return 0 if (!$_[1] );

	($! = Win32::GetLastError()) if(!$Result);

	# return a boolean value
	return($Result);
}
