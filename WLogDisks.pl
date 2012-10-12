 # Script using WMI to query computers for Logical Disk info, compute the amount of
# free space in MB and percent.
# Output in HTML file option to display on screen or emails the HTML.
#
# This script is based on a script by Dave Roth on www.winscriptingsolutions.com
# InstantDoc #19828
#
# Yehoshua Resis (yresis@zahav.net.il)
# May, 2003
#
# Uses blat.exe (freeware command line emailer for NT) to email the summary.
# Must run "blat.exe -install <SMTP_server> <user-name> on machine running the script before using.

use strict;
use Win32::OLE qw( in );

sub htmlhdr(*);
sub html_tblhdr(*);
sub htmlcell(*;$;$);
sub htmlrow(*;$);
sub htmlline(*;$);
sub htmlftr(*);
sub setcolor($);

#========================
# Site-specific parameters
# email info
my ($sndto,        #comma separated list of recipients
    $subj,        #subject for email
    $svr,        #SMTP server
    $uname,        #user name for sending
    $blatpath);    #path to blat.exe
$sndto = 'recipients';
$subj = '"Free Disk Space Summary"';
$svr = 'bhexch';
$uname = 'administrator';
$blatpath = 'blat';

my $outfile = 'disk.htm';            #include path here

#========================

my $WMIServices;
my $Namespace = "\\root\\cimv2";
my $DriveCollection;
my $Drive;
my $Machine;
#$Machine = shift @ARGV || ".";        #Uncomment for testing, comment out next 2 lines and while statement
my $pct_free;
my $color = '111111';

if (@ARGV < 1) { die "Usage: WLogDisks.pl \<server-list-file\>\n"; }
unless (open (INFILE, "$ARGV[0]")) { die ("Can't open server list file $ARGV[0], $!.\n"); }

open (ASHTM, ">$outfile" ) || die ("Can't open output file, $!. \n");
htmlhdr(\*ASHTM);
my ($d, $m, $y) = (localtime) [3,4,5];     $m++; $y+=1900;
htmlline(\*ASHTM,"Run on $d $m $y");
html_tblhdr(\*ASHTM);

while ( chomp( $Machine = <INFILE>) )
{
    htmlrow(\*ASHTM,1); htmlcell(\*ASHTM," "); htmlrow(\*ASHTM,0);
    htmlrow(\*ASHTM,1); htmlcell(\*ASHTM," "); htmlrow(\*ASHTM,0);

    $WMIServices = Win32::OLE->GetObject( "winmgmts:{impersonationLevel=
        impersonate,(security)}//".$Machine.$Namespace );

    if (!defined($WMIServices))
    {
        htmlrow(\*ASHTM,1); htmlcell(\*ASHTM,"Cannot connect to $Machine, $!"); htmlrow(\*ASHTM,0);
        next;
    }

    $DriveCollection = $WMIServices->ExecQuery("SELECT * FROM Win32_LogicalDisk WHERE DriveType=3" );

    foreach $Drive ( in( $DriveCollection ) )
    {
        htmlrow(\*ASHTM,1);

        if (defined($Drive->{Size} ) ) { $pct_free = ($Drive->{FreeSpace} / $Drive->{Size}) * 100;}
        else {$pct_free = 0 ; }
        $color = setcolor($pct_free);

        htmlcell(\*ASHTM,"$Drive->{SystemName}",$color);
        htmlcell(\*ASHTM,"  $Drive->{Name}",$color);
        htmlcell(\*ASHTM,"$Drive->{FileSystem}",$color);
        htmlcell(\*ASHTM, sprintf( "%s" , &FormatNumber( $Drive->{Size} ) ),$color );
        htmlcell(\*ASHTM, sprintf( "%s" , &FormatNumber( $Drive->{FreeSpace} ) ),$color );
        htmlcell(\*ASHTM, sprintf( "  %2d" , $pct_free ),$color);

        htmlrow(\*ASHTM,0);
    }
}
htmlftr(\*ASHTM);

close ASHTM;
close INFILE;

my $status;
$status = system("$blatpath $outfile -html -s $subj -t $sndto -server $svr -f $uname -q");
warn "Mail not sent: $? " unless ($status==0);

#For on screen display, uncomment the exec statement
#exec ("disk.htm");


#========================

sub FormatNumber
{
    my($Number) = @_ ;
    $Number    /= 1024;
    while( $Number =~ s/^(-?\d+)(\d{3})/$1,$2/ ){};
    return( $Number );
}

#========================

sub htmlhdr(*)
{
    my $handle = shift;

    print $handle ('<html>

    <head>
    <meta http-equiv="Content-Type" content="text/html; charset=windows-1252">
    <title>Server Disk Space Report</title>
    </head>
    <body>
    <p> <align="left"><font size="4" color="#0000FF"><b><u>Free Disk Space Report</u></b></font></p>
    <dl>
<dt><font size="4"><u>Key:</u></font></dt>
<dt><font size="4">Black - > 40%, OK</font></dt>
<dt><font size="4"><font color="#008000">Green</font> - > 20%, OK if
not running SQL, Exchange, etc</font>.</dt>
<dt><font size="4"><font color="#0000FF">Blue</font> - >10%, Start
cleaning up</font></dt>
<dt><font size="4"><font color="#FF0000">Red</font> - <10%, Start
cleaning up <font color="#FF0000">NOW</font></font></dt>
</dl>
    ');
}

#========================

sub html_tblhdr(*)
{
    my $handle = shift;

    print $handle ('<html>
    <div align="left">

    <table border="1">
        <tr>
            <td><b><font size="4"> System Name </font></b></td>
            <td><b><font size="4"> Name </font></b></td>
            <td><b><font size="4"> File System </font></b></td>
            <td><b><font size="4"> Size MB </font></b></td>
            <td><b><font size="4"> Free Space MB </font></b></td>
            <td><b><font size="4"> Free Space % </font></b></td>
        </tr>
    ');
}


#========================

sub htmlcell(*;$;$)
{
    my $handle = shift;
    my $cell = shift;
    my $clr     = shift;
    if (!defined($cell)) {$cell=" "};

    print $handle ('<td><font color =#' , $clr , "\>$cell" . '</font></td>');
}

#========================

sub htmlrow(*;$)
{
    my $handle = shift;
    my $row = shift;
    if ($row) {print $handle ('<tr>');}
    else {print $handle ('</tr>');}
}

#========================

sub htmlline(*;$)
{
    my $handle = shift;
    my $line = shift;
    if (!defined($line)) {$line="";}
    print $handle ("$line ");
}

#========================

sub htmlftr(*)
{
    my $handle = shift;
    print $handle ('</body>

    </html>
');
}

#========================

sub setcolor($)
{
    my $clr = shift;
    if ($clr >= 40) {return '111111';}
    elsif ($clr >= 20) {return '008000';}
    elsif ($clr >= 10) {return '0000FF';}
    else {return 'FF0000';}
}

