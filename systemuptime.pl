#! perl

# ********************************************************************
# * SystemUpTime.pl                                                  *
# * Copyright (C) 1998 by Jutta M. Klebe                   010398 JK *
# * All rights reserved.                               LU: 250898 JK *
# ********************************************************************
# * $Author:: Jmk                                                  $ *
# * $Date:: 25.08.98 23:02                                         $ *
# * $Archive:: /Jmk/scripts/saa/systemuptime.pl                    $ *
# * $Revision:: 2                                                  $ *
# ********************************************************************

use Win32::PerfLib;

($machine) = @ARGV;

$perf = new Win32::PerfLib($machine);
if(!$perf)
{
    die "Can't open PerfLib of $machine!\n";
}
my $objlist = {};
my $system = 2;
if($perf->GetObjectList("$system", $objlist))
{
    $perf->Close();
    my $Counters = $objlist->{Objects}->{$system}->{Counters};
    foreach $o ( keys %{$Counters})
    {
    $id = $Counters->{$o}->{CounterNameTitleIndex};
    if($id == 674)
    {
        $Numerator = $Counters->{$o}->{Counter};
        $Denominator = $objlist->{Objects}->{$system}->{PerfTime};
        $TimeBase =  $objlist->{Objects}->{$system}->{PerfFreq};
        $counter = int(($Denominator - $Numerator) / $TimeBase );
        $seconds = $counter;
        $hour = int($seconds / 3600);
        $seconds -= $hour * 3600;
        $minute = int($seconds / 60);
        $seconds -= $minute * 60;
        print "\t$hour hours $minute minutes $seconds seconds\n";
        last;
    }
    }
}


# ********************************************************************
# $History: SystemUpTime.pl $
# 
# *****************  Version 2  *****************
# User: Jmk          Date: 25.08.98   Time: 23:02
# Updated in $/Jmk/scripts/saa
# fixed bug in Win32::PerfLib module. This showed a bug in this script.
# Denominator and Timebase weren't correct.
# 
# *****************  Version 1  *****************
# User: Jmk          Date: 26.05.98   Time: 8:20
# Created in $/Jmk/scripts/saa
# Retrieve the system up time for any (NT) computer
# ********************************************************************