#!c:/perl/bin -w
#
# wmi.pl
#

#use strict;
use diagnostics;
use warnings;
use Win32;
use Win32::OLE qw (in);

 

$system = "apollo";

$classname = "Win32_Process";

@props = ("name");

%prop_value=();

$namespace = "root/cimv2";

$call = "instances";

$serial_no = 1;

 

sub list_instances {

       $serv = Win32::OLE->GetObject("winmgmts://$system/$namespace");

       $objs = $serv->InstancesOf("$classname");

       $i = 1;

       foreach $obj (in($objs)) {

              if($serial_no == 1){

                     $str = "$i ";

              }

              else {

                     $str = "";

              }

              if ($all_props) {

                     foreach $prop (in($obj->{Properties_})) {

                           $str = "$str\n $prop->{name} = $obj->{$prop->{name}}";

                     }

                     $str = "$str\n"

              }

              else{

                     foreach $prop (in(@props)) {

                           $str = "$str\t$obj->{$prop}";

                     }

              }

              $str = "$str\n";

              print $str;

              $i = $i + 1;

       }

}

 

sub list_classinfo {

       $obj = Win32::OLE->GetObject("winmgmts://$system/$namespace:$classname");

       print "$classname Properties : -----------------------------\n";

       $i = 1;

       foreach $prop (in($obj->{Properties_})) {

              print "$i\t$prop->{name}\n";

              $i = $i + 1;

       }

       print "$classname Methods : -----------------------------\n";

       $i = 1;

       foreach $m (in($obj->{Methods_})) {

              print "$i\t$m->{name}\n";

              $i = $i + 1;

       }

}

 

sub list_namespaceinfo {

       $serv = Win32::OLE->GetObject("winmgmts://$system/$namespace");

       print "$namespace Classes : -----------------------------\n";

       $i = 1;

       foreach $class (in($serv->SubClassesOf())) {

              $path = $class->{Path_}->{Path};

              print "$i\t$path\n";

              $i = $i + 1;

       }

       print "$classname Namespaces : -----------------------------\n";

       $i = 1;

       foreach $ns (in($serv->InstancesOf("__NAMESPACE"))) {

              print "$i\t$ns->{name}\n";

              $i = $i + 1;

       }

}

 

 

sub call_method {

       $serv = Win32::OLE->GetObject("winmgmts://$system/$namespace");

      

       if ((scalar keys (%prop_value)) == 0){

              $query="select * from $classname";

       } else{

              $query="select * from $classname where ";

              $and = "";

              for $key (keys %prop_value) {

                     $value = %prop_value->{$key};

                     $query = "$query $and $key=\'$value\'";

                     $and = "and";

              }

       }

      

       print "Query = $query\n";

       $objs = $serv->ExecQuery($query);

       $i = 0;

       foreach $obj (in ($objs)) {

              print "$i $obj->{name}->$methodname\n";

              $obj->{$methodname};

              $i = $i + 1

       }

}

 

 

 

foreach $arg (in(@ARGV)) {

       if ($arg =~ m#/sys:(.*)#) {

              $system = $1;

       } elsif ($arg =~ m#@(.*)#) {

              $system = $1;

       } elsif ($arg =~ m#\/class\:(.*)#) {

              $classname = $1;

       } elsif ($arg =~ m#\-\*#) {

              $all_props = 1;

       } elsif ($arg =~ m#\-(.*)=(.*)#) {

              %prop_value->{$1}=$2;

       } elsif ($arg =~ m#\-(.*)#) {

              @props[$#props+1]=$1;

       } elsif ($arg =~ m#^\?$#) {

              $call = "classinfo";

       } elsif ($arg =~ m#dir#) {

              $call = "dir";

       } elsif ($arg =~ m#(.*)\(.*\)#) {

              $methodname = $1;

              $call = "method";

       } elsif ($arg =~ m#\/ns\:(.*)#) {

              $namespace = $1;

       } elsif ($arg eq "/no_serial") {

              $serial_no = 0;

       } elsif (($arg eq "help") || ($arg eq '/?')) {

              print "WMI command line Tool (c)Roshan James, 2004\n\n";

              print "Help is available at:\n";

              print "http://pensieve.thinkingms.com/CommentView,guid,64df1ee9-a582-474c-960a-0063cd848609.aspx\n";

              print "Or mail spark\@mvps.org\n\n";

              exit 0

       } else {

              $classname = $arg;

       }

}

 

if ($call eq "instances") {

       list_instances();

} elsif ($call eq "dir") {

       list_namespaceinfo();

} elsif ($call eq "classinfo") {

       list_classinfo();

} elsif ($call eq "method") {

       call_method();

}
