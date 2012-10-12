#  CheckEventLog.pl
#  Example 5.4:
#  ----------------------------------------
#  From "Win32 Perl Programming: Administrators Handbook" by Dave Roth
#  Published by Macmillan Technical Publishing.
#  ISBN # 1-57870-215-1
#
#  This script checks the Win32 Event Log for various errors.

use Getopt::Long;
use Time::Local;
use Win32::EventLog;

$VERSION = 20020405;
$SEC = 1;
$MIN = 60 * $SEC;
$HOUR = 60 * $MIN;
$DAY = 24 * $HOUR;

%EVENT_TYPE = (
    eval EVENTLOG_AUDIT_FAILURE     =>  'AUDIT_FAILURE',
    eval EVENTLOG_AUDIT_SUCCESS     =>  'AUDIT_SUCCESS',
    eval EVENTLOG_ERROR_TYPE        =>  'ERROR',
    eval EVENTLOG_WARNING_TYPE      =>  'WARNING',
    eval EVENTLOG_INFORMATION_TYPE  =>  'INFORMATION',
);

%Config = (
    log     =>  'System',
);
Configure( \%Config );
if( $Config{help} )
{
    Syntax();
    exit;
}
if( defined $Config{date} )
{
    my( $Year, $Month, $Day ) = ( $Config{date} =~ /^(\d{4}).(\d{2}).(\d{2})/ );
    $TIME_LIMIT = timelocal( 0, 0, 0, $Day, $Month - 1, $Year - 1900 );
}
elsif( $Config{hour} || $Config{day} )
{
    $TIME_LIMIT = time() - ( $DAY * $Config{day} ) - ( $HOUR * $Config{hour} );
}

if( ! scalar @{$Config{machine}} )
{
    push( @{$Config{machine}}, Win32::NodeName );
}

if( defined( $Config{type} ) )
{
    foreach my $Mask ( @{$Config{type}} )
    {
        # Try referencing the EVENTLOG_xxxx_TYPE and EVENTLOG_xxxxx
        # constants. One of them is bound to work.
        $EVENT_MASK |= eval( "EVENTLOG_" . uc( $Mask ) . "_TYPE" );
        $EVENT_MASK |= eval( "EVENTLOG_" . uc( $Mask ) );
    }
}
else
{
    map
    {
        $EVENT_MASK |= 0 + $_;
    }( keys( %EVENT_TYPE ) );
}

# Tell the extension to always attempt to fetch the
# event log message table text
$Win32::EventLog::GetMessageText = 1;
$~ = EventLogFormat;
foreach my $Machine ( @{$Config{machine}} )
{
    my $EventLog;
    if( $EventLog = Win32::EventLog->new( $Config{log}, $Machine ) )
    {
        my %Records;
        local %Event;
        local $Count = 0;
        
        while( ( $EventLog->Read( EVENTLOG_BACKWARDS_READ
                                 | EVENTLOG_SEQUENTIAL_READ,
                                 0,
                                 \%Event ) )
                && ( $Event{TimeGenerated} > $TIME_LIMIT ) )
        {
            # Display the event if it is one of our requested
            # event types
            $Count++;
            write if( $Event{EventType} & $EVENT_MASK );
        }
    }
    else
    {
        print "Can not connect to the $Config{log} Event Log on $Machine.\n";
    }
}

sub Configure
{
    my( $Config ) = @_;

    Getopt::Long::Configure( "prefix_pattern=(-|\/)" );
    $Result = GetOptions( $Config, 
                            qw(
                                machine|s=s@
                                log|l=s
                                type|t=s@
                                hour|h=i
                                day|d=i
                                date=s
                                help|?
                            )
                        );
    $Config->{help} = 1 if( ! $Result );
    push( @{$Config->{machine}}, Win32::NodeName() ) unless( scalar @{$Config->{machine}} );
}

sub Syntax
{
    my( $Script ) = ( $0 =~ /([^\\]*?)$/ );
    my $Whitespace = " " x length( $Script );
    print<< "EOT";

Syntax:
    $Script [-m Machine] [-t EventType] [-l Log] 
    $Whitespace [-h Hours] [-d Days] [-date Date]
    $Whitespace [-help]
        -s Machine......Name of machine whose Event Log is to be examined.
                        This switch can be specified multiple times. 
        -t EventType....Type of event to display:
                            ERROR
                            WARNING
                            INFORMATION
                            AUDIT_SUCCESS
                            AUDIT_FAILURE
                        This switch can be specified multiple times.    
        -l Log..........Name of Event Log to examine. Common examples:
                            Application
                            Security
                            System
                        This switch can be specified multiple times.    
        -h Hours........Will consider events between now and the specified
                        number of hours previous.
        -d Days.........Will consider events between now and the specified
                        number of days previous.                        
        -date Date......Will consider events between now and the specified
                        date.  Date is in international time format
                        (eg. 2000.07.18)                        
EOT
}

format EventLogFormat =
--------------------------------
@>>>>> @<<<<<<<<<<<<<<<<<<<<<<<<<<<<  ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$Event{RecordNumber}, "\\\\" . $Event{Computer},     $Event{Message}
       @<<<<<<<<<<<<<<<<<<<<<<<<<<<<  ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
scalar localtime( $Event{TimeGenerated} ), $Event{Message}
       Type: @<<<<<<<<<<<<<<<<<<<<<<  ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$EVENT_TYPE{$Event{EventType}}, $Event{Message}
       Source: @<<<<<<<<<<<<<<<<<<<<  ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$Event{Source},                       $Event{Message}
~                                     ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                                      $Event{Message}
~                                     ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                                      $Event{Message}
~                                     ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                                      $Event{Message}
~                                     ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                                      $Event{Message}
~                                     ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
                                      $Event{Message}

.