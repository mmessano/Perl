#!C:\Perl\bin\perl.exe

use strict;
use warnings;
use Data::Dumper;
use Win32::OLE qw( in );


my $server = 'papp330';
#my $qs = Win32::OLE->new('Dexma.QueueStats.1') or die "Oops, can't start the object";
#my $names = $qs->GetAllQueueNames($server);


#while (my $names = $qs->GetAllQueueNames($server)) {
#  print Dumper($names);
#}

sub list_all_queues {
    my $qs = Win32::OLE->new('Dexma.QueueStats.1') or die "Oops, can't start the object";
    my @qnames = $qs->GetAllQueueNames($server);
      foreach (0..$#qnames) {
        print "$server , $_[0]\n";
      }
}

sub list_all_queues2 {
	my $qs = Win32::OLE->new('Dexma.QueueStats.1') or die "Oops, can't start the object";
#    my $qs = QueueStats->new() or die "Oops, can't start the object";
    my @qnames = $qs->GetAllQueueNames($server);
    print Dumper(@qnames);
      foreach (0..$#qnames) {
        print "$server , " . $qnames[0] . " \n";
      next
      }
}

sub list_all_queues3 {
	my $qs = Win32::OLE->new('Dexma.QueueStats.1') or die "Oops, can't start the object";
	my @qnames = $qs->GetAllQueueNames($server);
	my $enum = new Win32::OLE::Enum(@qnames);
	print Dumper($enum);
		  foreach my $qnames ($enum->All){
		  print "$server , " . $qnames->Name, "\n"; 
		  }
}


#&list_all_queues;
&list_all_queues2;
#&list_all_queues3;
