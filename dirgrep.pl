#!c:/perl/bin -w

my ($pattern1, $file, $dir, $output, $time, $filesize);

use strict;
use warnings;

$time= scalar(localtime);

print "Choose output file name with full path: 'c:/perl/output.txt' \n";
chomp($output=<STDIN>);

open(OUTPUT, ">$output") or die "Couldn't open the
$output file for writing\n";

$dir= shift;
opendir DIR, $dir or die "Can't open directory $dir: $!\n";

chdir "$dir";

print "Enter search string: \n";
chomp($pattern1 =<STDIN>);

while ($file= readdir DIR) {
	$filesize = (stat $file)[7];
        unless ($filesize == 0){
	print "Found a file: '$file'\n";
        &search;
}
}

sub search {

        open (FILE, $file) or die "Couldn't open $file: $!; aborting";

        while (<FILE>) {
        if (/$pattern1/i) {
                print "line $. of $file is : $_\n";
                print OUTPUT "line $. of $file is : $_";
                  }
}
}

close OUTPUT;
close FILE;

print "\nCurrent working directory is: $dir\n\n";
print "Program ended on $time\n";

