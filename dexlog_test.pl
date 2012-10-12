#log = new ActiveXObject("Dexma.DexLog");
#log.ModuleName = "MyComponentName";
#// write a message to the log
#log.Msg("Nothing is either good or bad but thinking makes it so");

use strict;
use diagnostics;
use warnings;
use Win32::OLE('in');

my ($log);


$log = Win32::OLE->new('Dexma.Dexlog') or warn "Cannot create DexLog object $!\n";
#$log->ModuleName("testlog");
$log->SetProperty('ModuleName','testlog');
$log->Msg("Testing the ModuleName method.");