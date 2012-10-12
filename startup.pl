#! c:\perl\bin\perl.exe
# startup.pl
#
# Combs through Registry keys and StartUp folders
# to show what applications are started when the system
# starts and users login on local and remote systems
#
# usage: perl startup.pl [machine]
#
# H. Carvey, keydet89@yahoo.com

use strict;
use Win32::TieRegistry(Delimiter=>"/");
use Win32::Shortcut;

my $server = shift || Win32::NodeName;
my $me = Win32::NodeName;

print "[Checking Registry keys on $server]\n";
my ($remote);

my %rkeys = ("UserInit" => "SOFTWARE/Microsoft/Windows NT/CurrentVersion/Winlogon/UserInit",
						"Load" => "SOFTWARE/Microsoft/Windows NT/CurrentVersion/Windows/Load");

if ($remote = $Registry->{"//$server/LMachine"}) {
	foreach my $k (keys %rkeys) {
		my $reg = $rkeys{$k};
		print "[$reg]\n";
		my $data = $remote->{$reg};
		if (defined $data) {
			print "  - $data\n";
  	}
	}
}
else {
	print "Could not connect to hive.\n";
}
print "\n";
my %hives = ("LMachine" => "HKLM",
						 "CUser" => "HKCU");

foreach my $hive (keys %hives) {
#	print "[Checking $hives{$hive} hive keys]\n";
	($remote = $Registry->{"//$server/$hive"}) ?
		(\&getTrojanKeys($hive)) :
		(print "Could not connect to $hives{$hive} hive.\n");
	print "\n";
}

sub getTrojanKeys {
	my $hive = $_[0];
	my($path) = 'SOFTWARE/Microsoft/Windows/CurrentVersion';
	print "[Checking $hive/$path keys]\n";
	my(@keys) = ('Run','RunOnce','RunOnceEx','RunServices');
	foreach my $k (@keys) {
		my $key = $remote->{"$path/$k"};
	 	if (defined $key) {
	 		my @vals = $key->ValueNames;
   		if($#vals != -1) {
   			foreach my $val (@vals) {
   				my $data = $key->{$val};
   				$data = "NotFound" unless($data);
   			  print "  - $k:$val:$data\n";
   			}
  		}
  	}
  }
}

print "[Checking Startup directories in all profiles on $server]\n";

my $startdir;
($server eq $me) ? ($startdir = "c:\\") : ($startdir = "\\\\$server\\c\$\\");

my $start = $startdir."winnt\\profiles\\";
my $startup = "\\start menu\\programs\\startup";
my ($dir,$err);

if (-e $start && -d $start) {
	opendir(ST,"$start");
	foreach $dir (sort readdir(ST)) {
		next if ($dir eq "." || $dir eq "..");
		my $dir2 = $start.$dir;
		if (-e $dir2 && -d $dir2) {
			my $newdir = "$start".$dir."$startup";
			if (-e $newdir && -d $newdir) {
				opendir(SUP,$newdir);
				my @files = readdir(SUP);
				closedir(SUP);
				if (@files) {
					foreach my $file (@files) {
						next if ($file eq "." || $file eq "..");
				  	if ($file =~ m/lnk$/) {
				  		my $shortcut = Win32::Shortcut->new($newdir."\\".$file);
							($shortcut) ? (print "$dir:$file:$shortcut->{Path}\n") :
								(print "Error with Shortcut: ".Win32::FormatMessage Win32::GetLastError."\n");
						}
						else {
							print "$dir:$file\n";
						}
					}
				}
			}
			else {
				print "$newdir does not exist or is not a directory.\n";
			}
		}
		else {
			print "$dir2 does not exist or is not a directory.\n";
		}
	}
	closedir(ST);
}
else {
	print "$start does not exist or is not a directory.\n";
}
