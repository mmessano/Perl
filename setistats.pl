#!/usr/bin/perl
      use LWP::Simple;

      $|              = 1;
      $url            = "http://setiathome.ssl.berkeley.edu/cgi-bin/cgi?cmd=user_stats&email=";
      $email          = "mmessano@auraleyes.net";
      $res_okay       = 1;

      $email = $ARGV[0] if(defined $ARGV[0]);
      $email =~ s/@/%40/g;

      @html=get("$url$email");

      foreach (@html) {
              $_=~s/\cM//g;
              $_=~s/<(br|p)>/\n\n/ig;
              $_=~s/<(?:[^>'"]*|(['"]).*?\1)*>//gs
      }

      foreach (@html) {
              chomp($_);
              m/(.*@.*)/;
              $user = "$1";
              m/returned: (.*)/;
              $received = "$1";
              m/this rank: (\d*)/;
              $peers = "$1";
              m/rank out of (\d*).*is: (\d*)/;
              $rank = "$2/$1";
              m/ (\d*)\n(\d* hr \d* min)\n(\d* hr \d* min \d*?\.\d*)/;
              $results = "$1";
              $cputime = "$2";
              $avgworktime = "$3";
              m/(\d*?\.\d*%)/;
              $morework = $1;
              $res_okay = 0 if(/No user with that name was found/);
              }

      if($res_okay) {
              print "Seti stats ($user)\n";
              print "      Results: $results\n";
              print " Tot CPU Time: $cputime\n";
              print "Avg Work Time: $avgworktime\n";
              print "  Last Result: $received\n";
              print "         Rank: $rank (Peers $peers)\n";
              print "   \% Position: $morework\n";
      } else {
              print "No details for : $email\n";
      }
