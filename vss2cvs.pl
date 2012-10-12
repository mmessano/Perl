#!/usr/bin/perl
# Version: $Id: vss2cvs.pl,v 1.15 2002/03/05 19:36:19 laine Exp $
#

print ("vss2cvs - SourceSafe to CVS converter.\n");
# no buffer
$| = 1;


# Options:
#
# SSROOT=xxx - VSS repository location
#     - default: nothing (uses whatever is already in %ENV{'SSDIR'})
# CVSROOT=xxx - CVS repository location
#     - default: nothing (uses whatever is already in %ENV{'CVSROOT'})
# SSPROJ=xxx - VSS project name
#     - default: none - THIS IS A REQUIRED argument
#     - notes: if this string doesn't start with "$/", one will be appended
# CVSPROJ=xxx - CVS project name
#     - default: VSSPROJ with the leading "$/" removed
# CVSBRANCH=xxx - branch tag to use for CVS commits
#     - default: none - commits to the trunk
# SSUSERPASS=xxx - username,pass for VSS
#     - default: none - uses the current Windows login
# TAGUPDATE=xxx - updates tags even if version already in...
#     - default: no
# SHOWDEBUG=xxx - show debug print messages 
#     - default: no

# cycle through the commandline and process options
while ($opt = shift)
{
    ($field, $value) = split(/=/, $opt, 2);
    $ENV{uc($field)} = "$value";
}

$workdir = $ENV{'WORKDIR'};
$ssroot = $ENV{'SSROOT'};
$cvsroot = $ENV{'CVSROOT'};
$ssproj = $ENV{'SSPROJ'};
$cvsproj = $ENV{'CVSPROJ'};
$cvsbranch = $ENV{'CVSBRANCH'};
$ssuserpass = $ENV{'SSUSERPASS'};
$showdebug = $ENV{'SHOWDEBUG'};

# if $ssroot isn't empty set %ENV{'SSDIR'} to its value
$ENV{'SSDIR'} = backslashes($ssroot) if ($ssroot);

# if $cvsroot isn't empty, prepend "-d " to it
die "You *must* specify CVSROOT in environment or on commandline!\n"
    unless ($cvsroot);
$cvsroot = slashes($cvsroot);
$ENV{'CVSROOT'} = $cvsroot;

# if $ssproj is empty, print a usage message and quit
die "You *must* specify an SSPROJ!\n"
    unless ($ssproj);

# if $ssproj doesn't start with "$/", prepend it
$ssproj = slashes($ssproj);
$ssproj =~ s/^/\$\// unless ($ssproj =~ /\$\//);

# if $cvsproj is empty, copy in $ssproj, but without "$/"
$cvsproj = $ssproj unless ($cvsproj);
$cvsproj =~ s/^\$\///;

# replace all spaces and '.' in $cvsbranch with _, and if the
# first char is numeric, prepend a "b"
$cvsbranch =~ s/[\.\s]/_/g;
$cvsbranch =~ s/(^[\d])/b\1/;

# if $ssuserpass isn't empty, prepend "-y" to it
$ssuserpass =~ s/^/-y/ if ($ssuserpass);

$ENV{'TAGUPDATE'} = "0" unless ($ENV{'TAGUPDATE'});

if (not defined $workdir) {
    use Cwd;
    $workdir = cwd();
}

print("**********************************************************************\n");
print("WORKDIR=|$workdir|\n");
print("SSDIR=|$ENV{'SSDIR'}|\n");
print("SSPROJ=|$ssproj|\n");
print("CVSROOT=|$cvsroot|\n");
print("CVSPROJ=|$cvsproj|\n");
print("CVSBRANCH=|$cvsbranch|\n");
$ssuserpassprint = $ssuserpass;
$ssuserpassprint =~ s/,.*$/,***SECRET***/;
print("SSUSERPASS=|$ssuserpassprint|\n");
print("**********************************************************************\n\n");

$subdir = "convert"; # subdirectory within $workdir that we'll use
#
# Make an empty tree matching the vss project
#

chdir $workdir;
rmdirp("$subdir");
mkdirp("$subdir");
chdir $subdir;
# cvs import to create the toplevel of the tree in one step
exec_cmd("cvs -f import -m \"Directory structure from VSS\" \"$cvsproj\" fromVSS transfer");

# remove the directory we created ourselves, and check it out from CVS
# (so we have the CVS version info).

# As per Ephraim Ofir - If $cvsbranch is set, do the initial checkout
# onto the branch, and only checkout the toplevel directory, as the
# lower levels aren't really necessary (they'll automatically be
# filled in during the cvs update of the individual files). By doing
# the initial checkout onto the branch, we avoid having to switch the
# working directory back and forth between trunk and branch, as was
# previously done. Note that if the branch doesn't already exist, CVS
# will return an error; however, as of cvs 1.11, it does go ahead and
# create enough of a work directory to get us by (contains a CVS
# subdirectory, with Entries, Root, Repository, and Tag files)

chdir "$workdir";
rmdirp("$subdir");
$branchopt = "-r $cvsbranch" if $cvsbranch;
exec_cmd("cvs -f -r co $branchopt -l -d $subdir \"$cvsproj\"");

# Set the VSS project and working directory, and get a listing of all
# directories and files in the project
chdir "$workdir";
exec_cmd("ss cd \"$ssproj\" $ssuserpass");
exec_cmd("ss workfold \"$ssproj\" \"$workdir\\$subdir\" $ssuserpass");

# this makes this pattern more useable for matching
$ssprojpat = $ssproj;
$ssprojpat =~ s%\$%\\\$%;
$ssprojpat =~ s%\/%\\/%g;

# switch down to here, to make the mkdir and cvs add commands easier
chdir $subdir;

# create a CVS working directory, while also adding each directory
# into the CVS module.  Build a list of files & their type.
exec_cmd("ss dir -R \"$ssproj\" -Odirlist $ssuserpass");
open(PROJLIST, "< dirlist");
open(FILELIST,"> ssfiledump") or die "Couldn't open ssfiledump for writing!\n";
$incvsdir = 0;
foreach $dirline (<PROJLIST>) {
    if ($dirline =~ /\/CVS:/) {
        # skip any CVS directories in VSS
        $incvsdir = 1;
        next;
    } elsif ($dirline =~ /^$ssprojpat/i) {
        $incvsdir = 0;
        $currdir = $dirline;
        $dirline =~ s/^$ssprojpat//i;
        chomp $dirline;
        chomp $currdir;
        $currdir =~ s/\:$/\//;
        next if (!$dirline);
        $dirline =~ s/^([^\:]*)\:[\s]*$/\1/;
        $dirline =~ s/^\///;
        mkdirp("$dirline");
        cvsadddirp("$dirline");
   } else {
        chomp $dirline;
        next if ($incvsdir
                 ||(!$dirline)
                 || ($dirline =~ /^\$/)
                 || ($dirline =~ /^No\ items\ found\ under\ /)
                 || ($dirline =~ /item\(s\)/));
        $dirline =~ s/\;[0-9]*$//;      # pinned files
        $currfile = "$currdir$dirline";
        open(FILETYPE,"ss filetype \"$currfile\" $ssuserpass |");
        $type = lc(<FILETYPE>);
        close(FILETYPE);
        chomp $type;
        $type =~ s/^.*\ //;
        print FILELIST ("No $type $currfile\n");
    }
}
close PROJLIST;
close FILELIST;

print "\n";

# We have an empty directory tree in CVS, as well as an empty CVS
# working directory tree. Now we simply cycle through the list of all
# files, calling resync_file for each.

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
$today = ($mon+1).'-'.$mday.'-'.($year+1900);


open(FILELIST,"< ssfiledump") or die "Couldn't open ssfiledump for reading!\n";

foreach $fileline (<FILELIST>) {
        ($nohistory, $type, $file) = split(/\s/,$fileline,3);
        chomp $file;  # NOTE: contains complete vss project path!
        resync_file($file,$type,$nohistory,$cvsbranch);
    }

close FILELIST;

chdir "$workdir";
rmdirp("$subdir");

# end of main()

my (%label_comments, %label_warned);

my @linebuffer;

#
# resync-file() - reads through ss history of given file, compares to
#                 cvs history ("log") of the file, and adds anything
#                 new from ss to cvs. If ss history hasn't changed since
#                 last time it was run, it should be a NOP.
#
# Note: the *actual* timestamp and user are stored in the
#       comments, and moved into proper position later by
#       massagecomments.pl. This is because we are probably running
#       vss2cvs.pl on a remote machine, where we don't have the direct
#       access to the cvs *,v file that we need in order to manipulate
#       timestamps.
#
# Note2:if a branch has been requested, this function will first
#       attempt to match revisions on the trunk with SS revisions,
#       then create the branch at the point the two diverge. If the
#       named branch already exists, this will be skipped - the
#       timestamp of the last existing revision on the branch will be
#       compared to the timestamps of all the vss revisions, and those
#       that are later than that will be committed to the cvs branch.

sub resync_file
{
    my $file = shift; # NOTE: contains *complete* vss project path
    my $type = shift; # "binary", "text"
    my $nohistory = shift;
    my $cvsbranch = shift;
    my $savedrevs = ($nohistory eq "No");
    my $dir;

    $file = slashes($file);

    print "******** Syncing $file *************\n";
    # construct commandlines
    # rmdirp ("filehist.txt");
    # do labels first so start of 2nd history part of label comment that is ignored
    open(VSS,"ss history -L \"$file;d$today\" $ssuserpass |");
    open(FILT, "> filehist.txt");
    while (<VSS>) {
        chomp($_);
        s/^\*{17}( +Version (\d+) +\*{17})?/\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*/g;
        # Getrid of versions that are labels too, history below will put then back
        # in their proper order.
         print FILT "$_\n"; 
    }
    close(FILT);
    close(VSS);
    
    system("ss history -Ofilehist.txt \"$file\" $ssuserpass");
    $file =~ s/^$ssprojpat\///i;
    
    my $cvscmd = "cvs -f log \"$file\"";

    my $file_bs = backslashes($file);
    my $backslashpos = rindex($file_bs, "\\");
    if ($backslashpos eq -1) {
        $dir = ".";
    } else {
        # $dir is everything up to last '/' in filename
        $dir = substr($file_bs, 0, $backslashpos);
    }

    # construct associative arrays of labels and revisions already in
    # CVS. the labels will be indexed by label name, and the revisions
    # will be indexed by the *actual* date/time of the change

    my %cvslabels; # array holding revs of all known cvs labels
    my %cvsrevs;   # all known cvs revisions, indexed by date
    my $alreadyincvs;  # set to non-0 if file is found in cvs
    my $line;

    open(CVS,"$cvscmd |");

    # skip up to beginning of labels
    while ($line = <CVS>) {
        last if ($line =~ /^symbolic names:$/);
    }

    # now read all labels
    while ($line = <CVS>) {
        # each label line is started with a tab character
        last if (!($line =~ /^\t/));

        my $cvsrev;
        my $cvslabel;

        # strip tab
        $line =~ s/^\t//;
        # break "Label_Name: rev" into separate items
        ($cvslabel, $cvsrev) = split(/[\s\:]+/,$line);
        # add to %cvslabels
        $cvslabels{$cvslabel} = $cvsrev;
    }

    my %newlabels;
    my $earliestdate;
    
    $earliestdate = "0000";
    
    # now look for groups of:
    #
    #   ----------------------
    #   revision <x>
    #   date: <x>
    #   [comments]
    #   possibly another "date <x>" (note lack of :)
    #   ----------------------
    # followed by =================, which is EOF
    undef $cvsrev; undef $cvsdate;
    while ($line = <CVS>) {
        chomp($line);
        # NOTE: If any comments have lines of 20 - or =, this will
        # produce erroneous results! I can't think of a foolproof
        # way to get around that, though... :-(
        if ($line =~ /^[-=]{20,}$/) {
            if ($cvsrev && $cvsdate) {
                print "Existing rev $cvsrev on $cvsdate\n";
                $cvsrevs{$cvsdate} = $cvsrev;
                $earliestdate = $cvsdate;
                $alreadyincvs = 1;
                undef $cvsrev; undef $cvsdate;
            }
        } elsif ((!$cvsrev) && $line =~ /^revision /) {
            # revision <x> line
            $line =~ s/^revision //;
            $cvsrev = $line;
        } elsif ((!$cvsdate) && $line =~ /^date: /) {
            # CVS's "date: <x>" line
            $line =~ s/^date: //;    # chop off beginning of line
            $line =~ s/;.*$//;       # chop off everything past date
            $line =~ s/[\/ \:]/\./g; # replace all separators with "."
            $cvsdate = $line;
        } elsif (($cvsdate) && $line =~ /^date[\s]+/) {
            # a "date <x>" line previously added to comments by us
            $line =~ s/^date[\s]+//;   # chop off beginning of line
            $line =~ s/;.*$//;       # chop off everything past date
            # now see if we need to add 1900 to it (if yr is 2 digits)
            ($temp) = split(/\./, $line);
            $line =~ s/^/19/ if (length($temp) le 2);
            $cvsdate = $line;
        }

    } # foreach $line
    close(CVS);

    # Now start through the SS history, saving a command to execute for every
    # change or label

    open(SS,"< filehist.txt");
    read_comment(); # ignore everything up to the first data block
    # (previously I verified that it started with "History of $file ..."
    # except that MS word wraps long filenames with spaces so just hang it)
  
    my $highestssver; # the highest (first) version we found in VSS for this file
    my $matchrev;     # the CVS rev of the highest VSS rev we found in CVS.
    my $somethingtocommit = 0; # set non-0 if we find any rev we need to commit
    my (@pending_commands);


  ITEM:
    while($_=myread()) {

        if(!(/^\*{17}/)) {
            die "parsing messed up on '$_'\n";
        }

        my ($version,$user,$timestamp,$label,$comment);

        # history entry can be both label and version
        my ($islabeled, $isversion);
        $islabeled = 0;
        $isversion = 0;
        

        if(/^\*{17}( +Version (\d+) +\*{17})/) {
            $version = $2;
            $highestssver = $version unless ($highestssver > $version);
            $isversion=1;
        }

        
        $_=myread();
        if(/^Label: "(.+)"$/) {
            $label = $1;
            $_=myread();
            $islabeled = 1
        }
        ($user,$timestamp) = parse_user_and_timestamp($_);

        # make a "normalized" timestamp so we can search for it in
        # %cvsdates
        my $normaltime = $timestamp;
        ($temp) = split(/\./, $normaltime); # get year only
        $normaltime =~ s/^/19/ if (length($temp) le 2);

        $_=myread();
        if($islabeled) {
            
            my $vsslabel = $label;
            # this revision isn't really a revision - it's just a label
            if( $label =~ s%[^\w\-]+%_%g && !$label_warned{$label}) {
                print "@, #, /, ', spaces or unprintable characters in label \"$label\" were mapped to _\n" if($showdebug) ;
                $label_warned{$label} = 1;
            }
            if( $label =~ /^([^\w]).*$/ ) {
                $label = "A_$label";
                print "\"A_\" prepended to label starting with $1 \"$label\"\n" if($showdebug);
                $label_warned{$label} = 1;
            }
            if( $label =~ /^([\_\-\d]).*$/ ) {
                $label = "A$label";
                print "\"A\" prepended to label starting with $1 \"$label\"\n" if($showdebug);
                $label_warned{$label} = 1;
            }

            if (defined($cvslabels{$label})) {
                print "******* SKIPPING LABEL '$label', ALREADY THERE!.\n" if($showdebug);
            } elsif ($earliestdate gt $timestamp) {
                print "******* SKIPPING LABEL '$label' ($timestamp), Prior to first version ($earliestdate)\n" if($showdebug);
            } else {
                print "******* ADDING LABEL '$label' ('$vsslabel')\n" if($showdebug);
                $newlabels{$label} = $vsslabel;
            }
            # assume all the comments for a particular label are the same...
            $comment = read_comment();
            $label_comments{$label} = $comment
                if ! defined($label_comments{$label});

            next ITEM if (!$isversion);
        }                       # if label

        # this is a "real" revision - either "Checked in
        # projectname" or "Branched"

        if (!$islabel) {
        # comment already read
            $comment = read_comment();
        }

        undef $kflags;
        $kflags = "-kb " if ($type eq "binary");

        if (defined ($cvsrevs{$normaltime})) {
                if ((!$ENV{'TAGUPDATE'})
                   and (!$islabel)) {
                    print("Skip commit rev dated $normaltime (and prior) - ",
                          "already in cvs as $cvsrevs{$normaltime}.\n");
                    $matchrev = $cvsrevs{$normaltime};
                    last;               # skip all prev. revs, assume they're there (should be)
                } else {
                }
        } else {

            print "Will commit rev dated $normaltime to cvs.\n";

            push(@pending_commands,
                 "$comment\ndate\t$timestamp\;\tauthor $user\;\tstate Exp\;\n");
            # NOTE: -f is because, unfortunately, we must force all commits,
            # even if there isn't really any change. This is because CVS
            # won't notice that a file has changed if its timestamp is the same
            # (which can easily happen in a script that does many operations
            # in the space of a single second)
            push(@pending_commands,
                 "cvs -f -r commit -f -F commentfile \"$file\"");
            if ($savedrevs || !$somethingtocommit) {
                # do at least one get per file, even if there's no
                # history
                my $v = "-v$version" if ($savedrevs);
                push(@pending_commands,
                     "ss get \"$file_bs\" -GL\"$dir\" -I-Y $v $ssuserpass");
            }
            $somethingtocommit = 1;
        }                       # if this is a revision not already in CVS

        if ($version == 1) {
            # any labels beyond version 1 happened before the file
            # was created
            last;
        }
        next ITEM;
    }

    print "========\n";
    @trash = <SS>; # trying to flush out the rest of SS
    undef @linebuffer;
    close SS;

    if ($alreadyincvs) {
        # If the file is in cvs already, we need to do the following:
        #
        #     If we're on a branch and there's no $cvsbranch label
        #         create branch label at last rev in common with trunk
        #
        #     update the *file* tag to the end of the branch

        my $branchopt = "-r $cvsbranch" if $cvsbranch;
        if ($somethingtocommit) {
            # the rm is so that we can verify the upcoming "ss get"
            # was successful by checking for existence of the file
            push(@pending_commands, "rm -f \"$file\"");
            push(@pending_commands, "cvs -f -r update $branchopt \"$file\"");
        }

        if ($cvsbranch) {
        if (!$matchrev) {
            # if there was no match, it's just as if we're creating from scratch
            $alreadyincvs = 0;
        } elsif (!defined($cvslabels{$cvsbranch})) {
            # if branch isn't already there, create it.
            push(@pending_commands, "cvs -f tag -b $cvsbranch \"$file\"");
            push(@pending_commands, "cvs -f tag $cvsbranch"."-initial \"$file\"");
            push(@pending_commands, "cvs -f -r update -r $matchrev \"$file\"");
        }
        } # if $cvsbranch
    } # if $alreadyincvs

    my ($cmd, $comment);
    while ($cmd = pop @pending_commands) {

        if ( $cmd =~ /.* commit .*/ ) {
            $comment = pop @pending_commands;
            open (COMMENT, "> commentfile");
            print COMMENT "$comment\n";
            close COMMENT;
        }

        exec_cmd("$cmd");

        if ((!$alreadyincvs) && ($cmd =~ /^ss get/)) {

            # if the file doesn't exist in the work directory, that
            # means the ss get failed, so we need to try getting the
            # next higher revision. Iteratively do this until we get
            # one or until there are no more versions available in
            # VSS. This way we'll end up with the next version newer
            # than the desired version.

            # Note that, in the case a version somewhere in the middle
            # is missing (and earlier versions exist), you'll end up with
            # the next *older* version instead. In order to fix this, you'd need
            # to add an rm of the workfile after each cvs commit, which would
            # could have a noticeable impact on the time required to to
            # the conversion.
            if (! (-e $file)) {
                # first get the ver number from the failed ss commandline
                # it will be the number just past "-I-Y -v"
                $cmd =~ /-I-Y -v(\d+) /;
                my $ver = $1;
                print "****** no copy of $file;$ver found!\n";
                while ($ver && ($ver < $highestssver) && !(-e $file)) {
                    $ver++;
                    $cmd =~ s/-I-Y -v(\d+) /-I-Y -v$ver /;
                    exec_cmd($cmd);
                }
                    
            }

            # if the file isn't already in cvs, we need to do a cvs
            # add right after the 1st ss get (we couldn't put this
            # into pending_commands to begin with because we could
            # never know for sure which ss get was the first until we
            # were done - apparently the 1st revision of some VSS
            # files *isn't* revision 1 (which was previously used as
            # the cue to do the cvs add))
            $cmd = "cvs -f -r add $kflags -m\"Imported from VSS\" \"$file\"";
            $alreadyincvs = 1;
            exec_cmd("$cmd");
        } # if cvs add needed

    } # while more commands to process
    
    foreach my $cvslabel ( keys %newlabels) {
        open(LABELHIST, "ss history \"$file;L$newlabels{$cvslabel}\" $ssuserpass |");

        my $labelapplied = 0;

        while ($_ = <LABELHIST>) {        
            
            if(/^\*{17} +Version (\d+) +\*{17}/) {
            exec_cmd("cvs -f tag -r1.$1 -l $cvslabel \"$file\"");
            $labelapplied = 1;
            last;
            }
        } # while more lines 
        
        
        if ($labelapplied == 0) {
            print "Unable to locate version for label \"$newlabels{$cvslabel}\"\n";
        }
        
        close(LABELHIST);
    } # while newlabels
} # end of sub resync_file()

sub parse_user_and_timestamp
{
    $_=shift;
    if (m@^History.*@) {
        read_comment();
    }

# *** DATE FORMAT CHANGE HERE ***
#
# For U.S. format dates: mm/dd/yy, time as hh:mm[am or pm indicator]
#
    die "can't parse timestamp $_"
        unless(m@^User:[\s]*(.*)\s+Date:\s+(\d+)/(\d+)/(\d+)\s+Time:\s+(\d+):(\d+)([ap])@);
    my ($user, $mo, $day, $yr, $hr, $min, $sec) = ($1, $2, $3, $4, $5, $6, 0);

#
# For U.K (and other) format dates: dd.mm.yy hh:mm (no am or PM):
#
#    unless(m@^User:[\s]*([^\s]+)\s+Date:\s+(\d+)/(\d+)/(\d+)\s+Time:\s+(\d+):(\d+)([ap]*)@);
#    my ($user, $day, $mo, $yr, $hr, $min, $sec) = ($1, $2, $3, $4, $5, $6, 0);
#

    # gmtime returns and
    # timelocal takes  second, minute,  hour,   day, month,  year
    # in the range      0..59,  0..59, 0..23, 1..31, 0..11, 0..137
    # The two digit year has assumptions made about it such that
    # any time before 2037 (when the 32-bit seconds-since-1970 time
    # will run out) is handled correctly.  i.e. 97 -> 1997, 101 -> 2001

    $hr = $hr % 12;
    if($7 eq 'p') { $hr += 12; }
    $mo = $mo - 1;
    if ( $yr < 38 ) { $yr += 100; }

    use Time::Local;
    $totalsec = timelocal($sec, $min, $hr, $day, $mo, $yr);
    ($sec, $min, $hr, $day, $mo, $yr, $unused) = gmtime($totalsec);

    $mo += 1;
    if ($yr > 99) { $yr -= 100; }
    for $timething ($sec, $min, $hr, $day, $mo, $yr) {
        if ($timething !~ /../) {
            $timething = "0" . $timething;
        }
    }
    if ($yr < 34) { $yr += 2000; }
    my $timestamp="$yr.$mo.$day.$hr.$min.$sec";

#******later: how do I handle the local date and time formatting settings?
## Is there a way to figure out what they are, so that I can parse 'em?
## output when "English, Australia" selected: dd/mm/yy hh:mm

    $user=lc($user);
    return ($user,$timestamp);
} # parse_user_and_timestamp

sub read_comment
{
  my $comment="";

  while($_=myread()) {
    # SAB 980503 - Comment can be terminated either by a new version
    # banner or by a Label separator...
##      *****************  Version 28  *****************
##      User: User1        Date:  3/19/98   Time:  2:16p
##      Checked in $/Projects/Common/AppUtils
##      Comment: setup CoffFormat build configuration
##      
##      **********************
##      Label: "demo #1"
##      User: User2        Date:  3/16/98   Time:  4:23a
##      Labeled
##      Label comment: Proposed demo.
##      
##      **********************
##      Label: "demo."
##      User: User2        Date:  3/13/98   Time:  2:35a
##      Labeled
##      Label comment: Project ready for demo.
##      
##      *****************  Version 27  *****************
##      User: User2        Date:  2/17/98   Time: 10:27p
##      Checked in $/Projects/Common/AppUtils
##      Comment: Fixed location of output .lib/.bsc files.
##      

    if(/^\*{17}/) {
      $comment =~ s/^(Label comment|Comment): //;
      # strip trailing blank lines & final newline
      $comment =~ s/[\s\r\n]*$//;
      pushback($_);
      return $comment;
    }
    $comment .= $_;
  }
  $comment =~ s/^(Label comment|Comment): //;
  $comment =~ s/[\s\r\n]*$//;
  return $comment;
} # read_comment


# functions to read from SS with pushback
# my @linebuffer;

sub myread
{
  my $line;
  $line = pop @linebuffer if(defined(@linebuffer));
  if (! defined($line)) {
    $line = <SS>;
  }
  return $line;
}

sub pushback
{
  push @linebuffer,shift;
}

sub exec_cmd
{
    my $cmd = shift;
    system("$cmd");
    $cmd =~ s/$ssuserpass/-y**SECRET**/;
    print("++++ $cmd ++++\n");
} # exec_cmd

sub slashes
{
    my $ret = shift;
    $ret =~ s%\\%\/%g;
    return $ret;
} # slashes

sub backslashes
{
    my $ret = shift;
    $ret =~ s%\/%\\%g;
    return $ret;
} # backslashes

# mkdirp - make a directory, including all parents if needed,
#          like "mkdir -p"
sub mkdirp
{
    my $fulldir = shift;
    $fulldir = slashes($fulldir);
    my $curdir = "";

    for my $thisdir (split(/\//,$fulldir)) {
        $curdir = "$curdir$thisdir/";
        mkdir "$curdir", 0700;
    }
} # mkdirp

# iteratively do a cvs add of each component of a directory.
sub cvsadddirp
{
    my $fulldir = shift;
    $fulldir = slashes($fulldir);
    my $curdir = "";

    # print ("*** Adding directory $fulldir to CVS\n");
    for my $thisdir (split(/\//,$fulldir)) {
        $curdir = "$curdir$thisdir/";
        exec_cmd("cvs -f -r add \"$curdir\"") unless -d "$curdir/CVS";
    }
} # cvsadddirp

# rmdirp - like "rm -rf", but does a chmod +w of everything first, so
#          that it works on braindead WinNT.
sub rmdirp
{
    my $subdir = shift;

    system("chmod -R +w $subdir");
    system("rm -rf $subdir");
} # rmdirp
