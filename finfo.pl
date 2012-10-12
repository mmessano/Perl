#! c:\perl\bin\perl.exe
#---------------------------------------------------------
# finfo.pl
# Retrieves file information
#
# usage: finfo.pl <file>
# Requires Win32::Perms
# http://www.roth.net/perl/perms
# Copyright 2000/2001 H. Carvey keydet89@yahoo.com
#---------------------------------------------------------
use strict;
use Win32::AdminMisc;
use Win32::Perms;
Win32::Perms::LookupDC(0);

my $file = shift || die "Must enter a filename\n";

if (-e $file) {
	\macdaddy($file);

	my %info;
	if (Win32::AdminMisc::GetFileInfo($file,\%info)) {
		printf "%-25s %-30s\n","OriginalFilename",$info{'OriginalFilename'};
		printf "%-25s %-30s\n","InternalName",$info{'InternalName'};
		printf "%-25s %-30s\n","FileDescription",$info{'FileDescription'};
		printf "%-25s %-30s\n","FileVersion",$info{'FileVersion'};
		printf "%-25s %-30s\n","Language",$info{'Language'};
		printf "%-25s %-30s\n","CompanyName",$info{'CompanyName'};
		printf "%-25s %-30s\n","LegalCopyright",$info{'LegalCopyright'};
		printf "%-25s %-30s\n","ProductName",$info{'ProductName'};
		printf "%-25s %-30s\n","ProductVersion",$info{'ProductVersion'};
	}
	else {
		print "Could not retrieve $file info: ";
		my $err = Win32::FormatMessage Win32::GetLastError;
		$err = Win32::GetLastError if ($err eq "");
		print $err;
		print "\n";
	}
}
else {
	print "Could not find $file.\n";
}

sub macdaddy {
	my $file = $_[0];
	my $owner = "";
	my ($size,$atime,$mtime,$ctime) = (stat($file))[7..10];
	my $a_time = localtime($atime);
	my $m_time = localtime($mtime);
	my $c_time = localtime($ctime);
	eval {
		my $perms = new Win32::Perms($file);
		$owner = $perms->Owner();
	};

	print "Filename:                $file\n";
	print "Size:                    $size\n";
	print "Owner:                   $owner\n";
	print "Creation Time:           $c_time\n";
	print "Last Access Time:        $a_time\n";
	print "Last Modification Time:  $m_time\n";
}
