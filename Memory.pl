#   Memory.pl
#   -----------
#   This will attempt to display the memory configuration
#   for the specified machine. It uses WMI so it may or
#   may not work for your particular machine.
#   Syntax:
#       perl Memory.pl [Machine Name]
#
#   Examples:
#       perl Memory.pl
#       perl Memory.pl \\server
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
use Win32::OLE qw( EVENTS HRESULT in );

my @MEM_TYPES = qw(
  Unable_to_deterime Unknown Other DRAM
  Synchronous DRAM Cache DRAM EDO EDRAM
  VRAM SRAM RAM ROM Flash EEPROM FEPROM
  EPROM CDRAM 3DRAM SDRAM SGRAM
);

my @MEM_DETAIL = qw(
  Unable_to_deterime Reserved Other
  Unknown Fast-paged Static column
  Pseudo-static RAMBUS Synchronous
  CMOS EDO Window_DRAM Cache_DRAM
  Non-volatile
);

my @FORM_FACTOR = qw(
  Unknown_Type Non_Recognized_Type
  SIP DIP ZIP SOJ Proprietary_Type
  SIMM DIMM TSOP PGA RIMM SODIMM
);

my $Class = "Win32_PhysicalMemory";
my $Total;
my $iCount = 0;
(my $Machine = shift @ARGV || "." ) =~ s/^[\\\/]+//;
my $WMIServices = Win32::OLE->GetObject( "winmgmts:{impersonationLevel=impersonate,(security)}//$Machine/" ) || die;

$~ = "INFO";
foreach my $Object ( in( $WMIServices->InstancesOf( $Class ) ) )
{
  my $Speed = $Object->{Speed} || "unknown speed";

  print ++$iCount . ") $Object->{Name} ($FORM_FACTOR[$Object->{FormFactor}])\n";
  DumpInfo( "Tag", $Object->{Tag} );
  DumpInfo( "Type", $MEM_TYPES[$Object->{MemoryType}] );
  DumpInfo( "Detail", $MEM_DETAIL[$Object->{TypeDetail}] );
  DumpInfo( "Size", FormatMemory( $Object->{Capacity} ) . "bytes" );
  DumpInfo( "Speed", "$Speed (ns)" );
  DumpInfo( "Location", "$Object->{BankLabel} ($Object->{DeviceLocator})" );
  if( $Object->{DataWidth} != $Object->{TotalWidth} )
  {
    print "\tThis is ECC memory.\n";
  }
  $Total += $Object->{Capacity};
  print "\n";
}
printf( "\nTotal Memory: %s ( %sbytes )\n",
        FormatNumber( $Total ),
        FormatMemory( $Total ) );

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
  return( FormatNumber( $Format ) . " $Suffix" );
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
