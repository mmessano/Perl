#!c:/perl/bin -w
# SqlRegKeys.pl - Get and set registry keys for MSSQL instances easily
#   Written by Vince Iacoboni
#   06/07/2007  VRI  Created

#use strict;
use Win32::TieRegistry (Delimiter => '/');

my %RegKeys = ('BackupDirectory'       => 'MSSQLServer//BackupDirectory',
               'Port'                  => 'MSSQLServer/SuperSocketNetLib/Tcp/IPAll//TcpPort',
               'DynamicPorts'          => 'MSSQLServer/SuperSocketNetLib/Tcp/IPAll//TcpDynamicPorts',
               'FullTextDefaultPath'   => 'MSSQLServer//FullTextDefaultPath',
               'ErrorLog'              => 'MSSQLServer/Parameters//SqlArg1',
               'MasterDataFile'        => 'MSSQLServer/Parameters//SqlArg0',
               'MasterLogFile'         => 'MSSQLServer/Parameters//SqlArg2',
               'CurrentVersion'        => 'MSSQLServer/CurrentVersion//CurrentVersion',
               'RegisteredOwner'       => 'MSSQLServer/CurrentVersion//RegisteredOwner',
               'SerialNumber'          => 'MSSQLServer/CurrentVersion//SerialNumber',
               'Collation'             => 'Setup//Collation',
               'Edition'               => 'Setup//Edition',      
               'PatchLevel'            => 'Setup//PatchLevel',   
               'SQLBinRoot'            => 'Setup//SQLBinRoot',   
               'SQLDataRoot'           => 'Setup//SQLDataRoot',  
               'SQLPath'               => 'Setup//SQLPath',      
               'SQLProgramDir'         => 'Setup//SQLProgramDir',
               'Version'               => 'Setup//Version',
               'AgentWorkingDirectory' => 'SQLServerAgent//WorkingDirectory',
               'AgentErrorLogFile'     => 'SQLServerAgent//ErrorLogFile',
              );

my $inst = shift;
my $parm = shift;
my $parmval = shift;
my $machine;
my %DirNames;

syntax() unless ($inst);

# if $inst has a machine name, use that for the Registry strings.  Change backslashes to slashes first
$inst =~ s{\\}{/}g;
if ($inst =~ m{^(//[^/]+/)(.*)$}) {
    $machine = $1;
    $inst = $2;
}

my $sqlkey = $Registry -> {$machine . "LMachine/SOFTWARE/Microsoft/Microsoft SQL Server/"};
my $InstNamesKey = $sqlkey -> {"Instance Names/SQL/"};
my @parms;
my @Instances;

if (!$parm or $parm eq '*' or lc($parm) eq 'all') {
    # Comment out the following line if you want to set a key for all instances, but it is dangerous!
    die "Can't set a value for all registry keys." if ($parmval);
    @parms = sort keys %RegKeys;
} else {
    # Ensure parm exists and normalize its case
    unless (@parms = grep(/^$parm$/i, keys %RegKeys)) { 
        print "$parm is not a valid parameter - see syntax below.\n\n";
        syntax();
    }
}

if (!$inst or $inst eq '*' or lc($inst) eq 'all') {
    @Instances = $InstNamesKey->ValueNames;
} else {
    # Ensure instance exists and normalize its case
    unless (@Instances = grep(/^$inst$/i, $InstNamesKey -> ValueNames)) {
        die "$inst not found as SQL instance.\n";
    }
}

foreach my $i (@Instances) {
    $DirNames{$i} = $InstNamesKey -> GetValue($i);
}

foreach $parm (@parms) {
    foreach $inst (@Instances) {
        getparmval($inst, $parm);
        setparmval($inst, $parm, $parmval) if ($parmval);
    }
    print "\n" if (scalar(@parms) > 1 and scalar(@Instances) > 1);
}

sub getparmval {
    my ($inst, $parm) = @_;
    if (exists $sqlkey -> {"$DirNames{$inst}/$RegKeys{$parm}"}) {
        my $regval = $sqlkey -> {"$DirNames{$inst}/$RegKeys{$parm}"};
        print "$inst $parm = $regval.\n";
    }
    else {
        print "$inst $parm REGISTRY KEY NOT FOUND.\n";
    }
}

sub setparmval {
    my ($inst, $parm, $parmval) = @_;
    $parmval = '' if ($parmval eq '(empty)' or $parmval eq "''");
    $sqlkey -> {"$DirNames{$inst}/$RegKeys{$parm}"} = $parmval;
    print "\t$parm set to $parmval.\n";
}


sub syntax {
    my $parms = join("\n\t\t", sort keys(%RegKeys));
    $0 =~ s/^.*\\(.*)$/$1/;
	#print &lt;&lt; "DONE";
	print "$0 - Retrieve and Set Instance-specific SQL Server registry keys\n";
	print "syntax: perl $0 [\\\\machine\\]instance parm [new value]\n";
	print "where \n";
	print "machine   = optional remote server machinename\n";
    print "instance  = name of SQL instance (* or all uses all instances) \n";
    print "parm      = one of the following (* or all allowed):\n\t\t$parms\n";
    print "new value = optional value to set key (use '' to set to empty).\n";
#DONE
    exit(0);
}
__END__
