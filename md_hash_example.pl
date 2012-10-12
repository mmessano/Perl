#!/usr/local/bin/perl

#===============================
# Working with multidimensional 
# hashes in Perl
# Copyright 1999-2002, Emmie P. Lewis
# Created 06/19/99
# Modified 07/30/02
#===============================
# This script is designed to show 
# how to use multidimensional hashes
# in Perl, and print the results
#===============================

print "Content-type:text/html\n\n";

#=== Initialize $BREAK ===
# $BREAK is used to format the output so it's easy to read.
# If you're running this script from the command line,
# change it to "\n".
# If you're running it in a browser, leave it as is
$BREAK = "\n";

#===================================
# Creating a multidimensional hash

%MD_Hash = (
   'Key-0' => [ 'FirstValue_0', 'SecondValue_0', 'ThirdValue_0',
   'FourthValue_0' ],

   'Key-1' => [ 'FirstValue_1', 'SecondValue_1', 'ThirdValue_1',
   'FourthValue_1' ]
);

print "First row of \$MD_Hash: $BREAK";

$COLS = 4; 
for( $ThisCol = 0; $ThisCol < $COLS; $ThisCol++ )
{
   print "\$MD_Hash{Key-0}[$ThisCol] =
   $MD_Hash{ 'Key-0' }[$ThisCol] $BREAK";
}
print $BREAK;

#===================================
# Add a record to a multidimensional hash

$MD_Hash{'Key-2'} = [ 'FirstValue_2', 'SecondValue_2',
   'ThirdValue_2', 'FourthValue_2' ];

print "\$MD_Hash after adding a record: $BREAK";

foreach $KeyValue ( sort(keys(%MD_Hash)) ) 
{
   print "$KeyValue: ", join( "--",
   @{$MD_Hash{$KeyValue}} ), "$BREAK";
}

print "$BREAK";

#===================================
# Access a record of a hash

@TheRecord = @{$MD_Hash{'Key-1'}};

print "\$TheRecord is: ", join("--", @TheRecord),
   "$BREAK";
print "$BREAK";


#######################################################
#%HASH_NAME=(
#   KEY => ELEMENT,
#   KEY => ELEMENT,
#   KEY => ELEMENT
#);
#
#Initializing a multidimensional hash follows the same principle, but the syntax is a little different. You'll recognize it, though.
#
#%MD_Hash = (
#   'Key-0' => [ 'FirstValue_0',
#   'SecondValue_0', 'ThirdValue_0',
#   'FourthValue_0' ],
#
#   'Key-1' => [ 'FirstValue_1',
#   'SecondValue_1', 'ThirdValue_1',
#   'FourthValue_1' ]
#);
#
#As you can see, the ELEMENT is a scalar list surrounded by square brackets.
#How to access elements in a multidimensional hash
#
#Accessing an individual item in the hash looks a little strange, but it's just a matter of remembering the syntax.
#
#$ColumnValue = $MD_Hash{ 'Key-0' }[2];
#
#You're referencing a scalar value, so be sure and use '$'. The key value is surrounded by curly braces '{}' as it is normally, and the column value is surrounded by square brackets '[]' as it is for scalar lists. If you follow the logic it isn't that hard to remember.
#
#Adding a record to a multidimensional hash
#
#Adding a record to a multidimensional hash is pretty straightforward. The syntax is exactly the same as it is for a regular hash, except that the value is a scalar list surrounded by square brackets.
#
#$MD_Hash{'Key-2'} = [ 'FirstValue_2',
#   'SecondValue_2', 'ThirdValue_2',
#   'FourthValue_2' ];
#
#How to access a record in a multidimensional hash
#
#When you want to access a record in an multidimensional hash, remember that the value being returned is a scalar list, so be sure and use '@' instead of '$' for the variable to hold the results.
#
#@TheRecord = @{$MD_Hash{'Key-1'}};
#
#Also, notice the '@' and set of curly braces around the multidimensional hash.
#
#Other issues
#
#When you use hash functions, such as keys(), values(), each() and exists(), the value returned is a list, not a scalar. So printing the multidimensional hash, for example, would look like this:
#
#foreach $KeyValue ( sort(keys(%MD_Hash)) ) {
#   print "$KeyValue: ", join( "--",
#   @{$MD_Hash{$KeyValue}} ), "\n";
#}
#
#That's covers what you'll need to know to work with a multidimensional hash. I have included a short script that you can use for practice, and feel free to experiment with the code to help you understand how to use multidimensional hashes in Perl.

#######################################################
