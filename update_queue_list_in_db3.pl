#!c:/perl/bin/perl.exe -w

# usage: perl update_queue_list_in_db3.pl <filename>

use strict;
use diagnostics;
use warnings;
use Win32::ODBC;
use IO::File;
use XML::Twig;
use File::stat qw(:FIELDS);

my ($SQL, $file, $DSN, $name, $ErrNum, $ErrText, $ErrConn);

# Set the DSN name
$DSN = new Win32::ODBC("status") or die "Error: " . Win32::ODBC::Error();

# Set the name of the stored procedure to run
# The trailing space is important!!!
$SQL = "exec sp_ins_queue_server_assoc ";

#%SQL_Errors = (server=>'', file=>'', name=>'', SQLState=>'', Number=>'', Text=>'');

$file= shift;

my $field = 'machine';
my $twig = new XML::Twig( TwigHandlers => { '/servers/machine' => \&insert_row});

$twig->parsefile($file);
my $root = $twig->root;
my @machines= $root->children;


sub insert_row {
	my( $twig, $ename)= @_;
	my $server= $ename->att('name');
	my @queues= $ename->children;
	$DSN->Sql("delete from t_queue_server_assoc where server_id = (select server_id from t_server where server_name = '$server')");
	foreach my $queue (@queues) {
	    my $qname = $queue->att('name');
		if ($DSN->Sql($SQL . $server . "," . "'" . $qname . "'"))
            {
				($ErrNum, $ErrText, $ErrConn) = $DSN->Error();
				print "SQL insert failed!\n";
				print "Server: $server\n";
				print "Name: $qname\n";
#				print "$ErrNum\n";
				print "$ErrText\n";
#				print "$ErrConn\n";
				print "\n";
			}
		

		}
	$twig->purge;
    }


close $file;
