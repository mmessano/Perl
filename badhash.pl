#!/usr/bin/perl
#
# badhash.pl
#
# Exercise worst-case behavior for Perl hashes.
# Copyright relinquished 1997 M-J. Dominus (mjd-perl-badhash@plover.com)
# This program is in the public domain.
#
# Thanks to Anthony Foiani (tkil@scrye.com) for suggestions and inspirations.

$HOW_MANY = shift || 10_000;

$TARGET = 2**16;
$MASK = $TARGET-1;

my ($s, $e1, $e2);
$s = time;
for ($i=0; $i<$HOW_MANY; $i++) {
  $q{$i}=1;
}
$e1 = time - $s;
print qq{
Normally, it takes me about $e1 second(s) to put $HOW_MANY items into a
hash.  Now I'm going to construct $HOW_MANY special keys and see 
how long it takes to put those into a hash instead.
};
undef %q;

for ($i=1; $i< $HOW_MANY; $i++) {
  my $prefix = randomstring();
  my $h = hashval($prefix);
  my $hh = $TARGET - ((35937*$h&$MASK)&$MASK);
  
  # We want to make $hh == 0
  my @suffix;
  for ($j =0; $j < 3; $j++) {
    my $c = 33**(2-$j);
    my $q =  int($hh / $c);
    $suffix[$j] = $q;
    $hh -= $q * $c;
  }
  my $suffix = join('', map {chr $_} @suffix);
  
  my $key = $prefix . $suffix;
  unless ((hashval($key) & $MASK) == 0) {
    warn "Something went wrong: bad hash value for `$prefix'.\n";
  }
  push @keys, $key;
  print "Constructed $i special keys.\n" if $i % 1000 == 0;
}

print "Putting the $HOW_MANY special keys into the hash.\n";
$i = 0;
$lasttime = $s = time;
foreach $key (@keys) {
  $h{$key} = 1;
  
  $i++;
  
  if (time() - $lasttime  > 5) {
    my $h = %h + 0;
    print "I have put $i keys into the hash, using $h bucket(s)\n" ;
    $lasttime = time;
  }
}

$e2 = time - $s;
print qq{
The $HOW_MANY special keys took $e2 seconds to put into the hash,
instead of $e1 seconds.
};

1;
1;
1;
1;



sub hashval {
  my $s = shift;
  my $h = 0;
  foreach $c (split //, $s) {
    $h = $h * 33 + ord($c);
    $h = $h & $MASK if $h > $TARGET;
  }
  $h;
}


sub randomstring {
  my $LEN = int(4 + rand(3));
  my $s = '';

  foreach $i (0 .. $LEN) {
    $s .= chr(rand(256));
  }

  $s;
}
