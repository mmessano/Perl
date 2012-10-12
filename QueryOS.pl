#   QueryOS.pl
#   -----------
#   This will discover and print information about the
#   Windows OS on a given machine.
#   Syntax:
#       perl QueryOS.pl [Machine Name]
#
#   Examples:
#       perl QueryOS.pl
#       perl QueryOS.pl \\server
#
#   2002.01.20 rothd@roth.net
#
#   Permission is granted to redistribute and modify this code as long as
#   the below copyright is included.
#
#   Copyright © 2002 by Dave Roth
#   Courtesty of Roth Consulting
#   http://www.roth.net/

use vars qw( $Log $Message $Name $Value );
use strict;
use Win32::OLE qw( in );
my @OS_TYPE = qw(
  Unknown Other Mac_OS ATTUNIX DGUX DECNT Digital_Unix
  OpenVMS HPUX AIX MVS OS400 OS/2 JavaVM MSDOS
  Windows_3x Windows_95 Windows_98 Windows_NT Windows_CE
  NCR3000 NetWare OSF DC/OS Reliant_UNIX SCO UnixWare
  SCO_OpenServer Sequent IRIX Solaris SunOS U6000 ASERIES
  TandemNSK TandemNT BS2000 LINUX Lynx XENIX VM/ESA
  Interactive_UNIX BSDUNIX FreeBSD NetBSD GNU_Hurd OS9
  MACH_Kernel Inferno QNX EPOC IxWorks VxWorks MiNT
  BeOS HP_MPE NextStep PalmPilot Rhapsody
);
my $Class = "Win32_OperatingSystem";
(my $Machine = shift @ARGV || "." ) =~ s/^[\\\/]+//;
my $WMIServices = Win32::OLE->GetObject( "winmgmts:{impersonationLevel=impersonate,(security)}//$Machine" ) || die;

$~ = "INFO";
foreach my $OS ( in( $WMIServices->InstancesOf( $Class ) ) )
{
  my $Organization = "($OS->{Organization})" if ( "" ne $OS->{Organization} );
  DumpInfo( "Name", $OS->{Caption} );
  DumpInfo( "OS", "$OS_TYPE[$OS->{OSType}] v$OS->{Version}" );
  DumpInfo( "Service pack", $OS->{CSDVersion} ) if( "" ne $OS->{CSDVersion} );
  DumpInfo( "Memory (RAM+Virt)", FormatMemory( $OS->{TotalVirtualMemorySize} * 1024 ) . " bytes" );
  DumpInfo( "System path", $OS->{SystemDirectory} );
  DumpInfo( "OS installed on", $OS->{SystemDevice} );
  DumpInfo( "Serial number", $OS->{SerialNumber} );
  DumpInfo( "Registered to", "$OS->{RegisteredUser} $Organization" );
}

sub FormatNumber
{
    my($Number) = @_;
    while( $Number =~ s/^(-?\d+)(\d{3})/$1,$2/ ){};
    return( $Number );
}

sub FormatMemory
{
  my( $Size ) = @_;
  my $Format;
  my $Suffix;
  my $K = 1024;
  my $M = $K * 1024;
  if( $M < $Size )
  {
      $Suffix = "M";
      $Format = $Size / $M;
  }
  elsif( $K < $Size )
  {
      $Suffix = "K";
      $Format = $Size / $K;
  }
  else
  {
      $Format = $Size;
  }
  $Format =~ s/\.(\d){1,2}\d+/.$1/;
  return( FormatNumber( $Format ) . $Suffix );
}

sub DumpInfo
{
  local( $Name ) = shift @_;
  local( $Value ) = shift @_;
  write;
}

format INFO =
        @<<<<<<<<<<<<<<<<< ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
        "$Name:",             $Value
~~                         ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                           $Value
.
