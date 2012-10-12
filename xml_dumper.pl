use strict;
use diagnostics;
use warnings;
use XML::Dumper;

my $file = shift;
my $dump = new XML::Dumper;
my $data = $dump->xml2pl($file);
print $data . "\n";
