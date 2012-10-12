#!c:/perl/bin -w
#
# del_files.pl
#

use strict;
use diagnostics;
use warnings;
use DirHandle;
use Win32::OLE('in');


my ( $dir, $server, @servers, $dexlog );

$dir = '\\c$\\windows\\system32\\logfiles\\httperr';

@servers = ( 'XIMP2K3LB1','XIMP2K3LB2','XIMP2K3WEB4' );
#@servers = ( 'VMDEV3','VMDEV4','VMDEV5','VMQA6','VMQA7','VMQAWEB1','VMQAWEB2','VMQAWEB3','VMQAWEB4','XIMP2K3LB1','XIMP2K3LB2','XIMP2K3WEB4' );

$dexlog = Win32::OLE->new('Dexma.Dexlog') or warn "Cannot create DexLog object $!\n";
$dexlog->SetProperty('ModuleName','del_files');


foreach $server ( @servers ) {
	my $logdir = "\\\\" . $server . $dir;
	my @files = &plainfiles($logdir);
	print "Starting $server...\n";
	foreach my $file ( @files ) {
			print "$file\n";
	}
}


sub plainfiles {
   my $dir = shift;
   my $dh = DirHandle->new($dir)   or die "can't opendir $dir: $!";
   return sort                     # sort pathnames
          grep {    -f     }       # choose only "plain" files
          map  { "$dir$_" }        # create full paths
          grep {  !/^\./   }       # filter out dot files
          grep {  m/\.log/ }       # filter log files
          $dh->read();             # read all entries
}