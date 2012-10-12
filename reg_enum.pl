#!c:/perl/bin -w
#
# reg_enum.pl
#


use Getopt::Long;
use Win32::Registry;
%TYPES = (
  &REG_SZ         =>  "REG_SZ",
  &REG_EXPAND_SZ  =>  "REG_EXPAND_SZ",
  &REG_MULTI_SZ   =>  "REG_MULTI_SZ",
  &REG_DWORD      =>  "REG_DWORD",
  &REG_BINARY     =>  "REG_BINARY"
	);
$giTotal = $giTotalMatch = 0;
Configure( \%Config );
if( $Config{help} )
	{
    	Syntax();
    	exit();
	}

ProcessKey($Config{root}, $Config{key} );
print STDERR "\n-------------------\n";
print STDERR "Total values checked: $giTotal\n";
print STDERR "Total values matching criteria: $giTotalMatch\n";

#############################################

sub ProcessKey
{
  my( $Root, $Path ) = @_;
  my $Key;
  print STDERR "Found $giTotalMatch match of ", ++$giTotal, " keys\r";
  if( $Root->Open( $Path, $Key ) )
  {
    my @KeyList;
    my %Values;
    $Key->GetKeys( \@KeyList );
    if( $Key->GetValues( \%Values ) )
    {
      foreach my $ValueName ( sort( keys( %Values ) ) )
      {
        my $Type = $Values{$ValueName}->[1];
        my $Data = $Values{$ValueName}->[2];
        $ValueName = "<Default Class>" if( "" eq $ValueName );
        foreach my $Target ( @{$Config{find}} )
        {
          if( $Data =~ /$Target/i )
          {
            printf( " % 6d) %s:%s = '%s'\n",
                    ++$giTotalMatch, $Path,
                    $ValueName, $Data ) ;
            last;
          }
        }
      }
    }
    else
    {
      print STDERR "Unable to get values for key: '$Path'\n";
    }
    $Key->Close();
    $Path .= "\\" unless ( "" eq $Path );
    foreach my $SubKey ( sort ( @KeyList ) )
    {
      ProcessKey( $Root, $Path . $SubKey );
    }
  }
  else
  {
    print STDERR "Unable to open the key: '$Path'\n";
  }
}

########################################

sub Configure
{
    my( $Config, @Args ) = @_;
    my $Result;
    my %Roots = (
      HKEY_LOCAL_MACHINE  => $HKEY_LOCAL_MACHINE,
      HKEY_CURRENT_USER   => $HKEY_CURRENT_USER,
      HKEY_USERS          => $HKEY_USERS,
      HKEY_CLASSES_ROOT   => $HKEY_CLASSES_ROOT,
      HKEY_CURRENT_CONFIG => $HKEY_CURRENT_CONFIG
    );
    Getopt::Long::Configure( "prefix_pattern=(-|\/)" );
    $Config->{root} = "HKEY_LOCAL_MACHINE";
    $Result = GetOptions( $Config, qw(
                          root|r=s key|k=s help|h|? ) );
    $Config->{help} = 1 unless( $Result );
    if( exists( $Roots{uc( $Config->{root} )} ) )
    {
      $Config->{root} = $Roots{uc( $Config->{root} )};
    }
    else
    {
      print STDERR "Unable to access $Config->{root}.\n";
      $Config->{help} = 1;
    }
    if( scalar @ARGV )
    {
      @{$Config->{find}} = @ARGV;
    }
    else
    {
      $Config->{help} = 1;
    }
}

#########################################

sub Syntax
{
    my $Script = ( Win32::GetFullPathName( Win32::GetLongPathName( $0 )))[1];
    my $Line = "-" x length( $Script );
    print STDERR << "EOT";

    $Script
    $Line
    Locates specified strings in the Registry.
    Syntax: $Script [-r <Root>] [-k KeyPath] <Find> [<Find2> [<Find3> [...]]]
      Root..........Registry root to look into such as
                    HKEY_LOCAL_MACHINE or HKEY_CURRENT_USER
                    Default: HKEY_LOCAL_MACHINE
      KeyPath.......Path to a key in the specified root.
                    Default = "\\"
      Find..........String to search for.

      Examples:
        perl $Script -r HKEY_LOCAL_MACHINE wmserver wmplayer
EOT
}
