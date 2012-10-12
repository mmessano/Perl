#! perl

# pretty printer for the Win32::PerfLib data structure
# note: this subroutine expects an hash array %counter filled by the
#       function Win32::PerfLib::GetCounterNames
# arguments:
#     hash reference
sub PrintPerfLibHash
{
    my($href, $level) = @_;
    my $text;
    my $k;
    my $v;
    $level = "" unless $level;
    foreach $k (sort keys %{$href})
    {
    if(ref $href->{$k} eq "HASH")
    {
        $text = $level . "$k => {";
        print "$text\n";
        PrintPerfLibHash($href->{$k}," " x length($text));
        print " " x (length($text)-1), "}\n";
    }
    elsif(ref $href->{$k} eq "ARRAY")
    {
        $text = $level . "$k => [";
        print "$text\n";
        foreach $v (@{$href->{$k}})
        {
        print " " x length($text), "$v\n";
        }
        print " " x (length($text)-1), "]\n";
    }
    elsif(ref $href->{$k} eq "CODE")
    {
        print $level, "$k => Code\n";
    }
    else
    {
        print $level, "$k => ";
        if ($k eq "CalculationModifiers" or $k eq "CounterType"
        or $k eq "Size" or $k eq "SubType" or $k eq "TimeBase" or
        $k eq "Type")
        {
        printf("0x%08x", $href->{$k});
        }
        else
        {
        print $href->{$k};
        }
        if (defined $counter{$href->{$k}})
        {
        if( $k eq "CounterNameTitleIndex" or
            $k eq "ObjectNameTitleIndex")
        {
            print " [$counter{$href->{$k}}]";
        }
        }
        if ($k eq "CounterType")
        {
        print " [", Win32::PerfLib::GetCounterType($href->{$k}), "]"
        }
        print "\n";
    }
    }
}
