#!c:/perl/bin -w
#
# scan_share_perms.pl
#


use strict;
use Win32::FileSecurity qw(Get EnumerateRights);
use File::Find;

my $share=$ARGV[0];
my $out=$ARGV[1];
my ($name,$mask,@rights,%hash,$server,%rights2,@folders,$subfolder,$se
+rvsplit,$subsplit,$right,$item);
my @servers=('SERVERXX','SERVERXX','SERVERXX','SERVERXX','SERVERXX','SERVERXX','SERVERXX','SERVERXX','SERVERXX','SERVERXX','SERVERXX','SERVERXX','SERVERXX','SERVERXX','SERVERXX','SERVERXX','SERVERXX','SERVERXX');
@servers=map ("//$_/$share",@servers);
my @rightsmatch=('DELETE','READ_CONTROL','WRITE_DAC','WRITE_OWNER','SYNCHRONIZE','STANDARD_RIGHTS_REQUIRED','STANDARD_RIGHTS_READ','STANDARD_RIGHTS_WRITE','STANDARD_RIGHTS_EXECUTE','STANDARD_RIGHTS_ALL','SPECIFIC_RIGHTS_ALL','ACCESS_SYSTEM_SECURITY','MAXIMUM_ALLOWED','GENERIC_READ','GENERIC_WRITE','GENERIC_EXECUTE','GENERIC_ALL','FULL','READ','CHANGE');

open (OUT, ">$out") or die "can't open log file!";

foreach $server( @servers ) {
print "$server\n";
@folders='';
    find(\&wanted, $server);
    foreach $subfolder (@folders){
    print "\t:$subfolder\n";
        next unless -e $subfolder ;
    if ( Get( $subfolder, \%hash ) ) {
        while( ($name, $mask) = each %hash ) {
        ($servsplit,$servsplit,$servsplit,$subsplit)=split(/\//,$subfolder,4);
        print OUT "$servsplit\t$subsplit\t$name\t";
        EnumerateRights( $mask, \@rights ) ;#creates @rights, a list of rights for the account
        %rights2=();
        foreach $right (@rights){
                $rights2{$right} = 1;
        }
        foreach $item (@rightsmatch){
        if (exists $rights2{$item}){
            print OUT "$item\t";
        }else{
            print OUT "\'\t";
        }
        }
        print OUT "\n";
    }

    }
    else {
        print( "Error #", int( $! ), ": $!" ) ;
    }
    }
}

close OUT;

sub wanted {
    if (-d){
        push @folders, "$File::Find::dir/$_";
        }
}
