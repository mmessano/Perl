use strict;

use Win32::OLE qw(in);
use Win32::OLE::Enum;
use Getopt::Std;

my $usage = <<END_USAGE;
Usage: $0 -p <path from IIS://localhost>
  for example: $0 -p W3svc/1/Root
END_USAGE

my %opts;
getopts('p:',\%opts);
die $usage unless exists $opts{p};

my $iisadsi = Win32::OLE->GetObject("IIS://localhost/$opts{p}")
              || die "Could not get object IIS://localhost/$opts{p}";

enum($iisadsi);

sub enum {
  my $node = shift;
  my $schema = Win32::OLE->GetObject($node->{schema});
  foreach my $i (@{$schema->{MandatoryProperties}}, 
@{$schema->{OptionalProperties}}) {

    my $value = $node->Get($i);
    if (ref($value) ne '') {
      print ref($value) . "--";
      local $_;
      $_ = ref($value);
      CASE: {
        /ARRAY/ && do { print $node->{ADsPath}."/$i=".join(', ',@$value)."\n";
                        last CASE;
                      };
        /Win32::OLE/ && do { enum($value);
                             last CASE;
                           };
        print "$i:\tUnknown value\n";
      }

    }
    else {
      print $node->{ADsPath}."/$i=".$value."\n";
    }
  }
}