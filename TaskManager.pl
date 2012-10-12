#! C:/perl/bin/perl -w
# TaskManager.pl 02/27/2002.
# This program will start an instance of the NT Task Manager and then
# minimize it.

# Declare pragmas.
use diagnostics;
use strict;
use warnings;

# Declare modules.
use Win32::GUI;
use Win32::Process;

# Declare all subroutines.
sub CheckForInstance();
sub ErrorReport();

# Declare global variables.
my $Desktop = GUI::GetDesktopWindow();
my $Window  = GUI::GetWindow($Desktop, GW_CHILD);
my $Title;

{
    # Check for an existing instance of the Task Manager.
    CheckForInstance();

    # Declare local variables.
    my $Process;

    # Start an instance of the NT Task Manager.
    Win32::Process::Create($Process, 'C:/WINDOWS/system32/taskmgr.exe', '', 0, CREATE_NO_WINDOW, 'C:/WINDOWS') || die ErrorReport();

    while ()
    {
        $Desktop = GUI::GetDesktopWindow();
        $Window  = GUI::GetWindow($Desktop, GW_CHILD);

        # Locate the Task Manager window and minimize it.
        while($Window)
        {
            $Title = GUI::Text($Window);
            goto NEXTWIN if (length($Title) < 17);
            if ($Title =~ /task manager/i) {GUI::Minimize($Window); exit(1)}
            NEXTWIN: $Window = GUI::GetWindow($Window, GW_HWNDNEXT);
        }
        sleep(1);
    }
    exit(1);
}

sub CheckForInstance()
{
    while($Window)
    {
        $Title  = GUI::Text($Window);
        goto NEXTWIN if (length($Title) < 17);
        if ($Title =~ /task manager/i) {print("An instance of Task Manager
already exists\n"); exit(1)}
        NEXTWIN: $Window = GUI::GetWindow($Window, GW_HWNDNEXT);
    }
    return(1);
}

sub ErrorReport()
{
    print(Win32::FormatMessage(Win32::GetLastError()));
    return(1);
}

__END__