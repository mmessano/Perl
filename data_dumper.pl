use strict;
use XML::Simple;
use Data::Dumper;

my $simple = XML::Simple->new();
my $struct = $simple->XMLin("../stage_queue_list.xml", forcearray => 1, keeproot => 1);

# Use Data::Dumper Dumper function to return a nicely 
# formatted stringified structure
print Dumper($struct);
