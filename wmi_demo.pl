#! c:\perl\bin\perl.exe
# Script to demonstrate using WMI
# Requires that WMI core classes be installed
#   from http://www.microsoft.com/management/wmi
# Retrieves info from the local system

use strict;
use Win32::OLE qw(in with);

my $wmi = Win32::OLE->GetObject("winmgmts:");

print "Computer System\n";
print "-" x 20,"\n";
my $sys_set = $wmi->InstancesOf("Win32_ComputerSystem");
foreach my $sys (in($sys_set)) {
  print "Caption:  ".$sys->{'Caption'}."\n";
  print "PriOwner: ".$sys->{'PrimaryOwnerName'}."\n";
  print "SysType:  ".$sys->{'SystemType'}."\n";
  print "Domain:   ".$sys->{'Domain'}."\n";
}

print "\n";
print "Operating System\n";
print "-" x 30,"\n";
my $os_set = $wmi->InstancesOf("Win32_OperatingSystem");
foreach my $os (in($os_set)) {
  print "Caption:       ".$os->{'Caption'}."\n";
  print "Manuf:         ".$os->{'Manufacturer'}."\n";
  print "BootDevice:    ".$os->{'BootDevice'}."\n";
  print "System Dir:    ".$os->{'SystemDirectory'}."\n";
  print "Organization:  ".$os->{'Organization'}."\n";
  print "BuildNum:      ".$os->{'BuildNumber'}."\n";
  print "Build:         ".$os->{'BuildType'}."\n";
  print "Version:       ".$os->{'Version'}."\n";
  print "CSDVersion:    ".$os->{'CSDVersion'}."\n";
  print "Locale:        ".$os->{'Locale'}."\n";
  print "WinDir:        ".$os->{'WindowsDirectory'}."\n";
  print "TotMem:        ".$os->{'TotalVisibleMemorySize'}." bytes\n";
  print "SerNum:        ".$os->{'SerialNumber'}."\n";
}

print "\n";
print "PageFile Settings\n";
print "-" x 30,"\n";
my $pf_set = $wmi->InstancesOf("Win32_PageFile");
foreach my $pf (in($pf_set)) {
  print "Name:     ".$pf->{'Name'}."\n";
  print "Initial:  ".$pf->{'InitialSize'}." MB\n";
  print "Max:      ".$pf->{'MaximumSize'}." MB\n";
}

print "\n";
print "Services\n";
print "-" x 20,"\n";
my $serv_set = $wmi->InstancesOf("Win32_Service");
foreach my $serv (in($serv_set)) {
  print "Service == ".$serv->{'DisplayName'}."  [".$serv->{'Name'}."]\n";
  print "\tState:        ".$serv->{'State'}."\n";
  print "\tStatus:       ".$serv->{'Status'}."\n";
  print "\tExecuteable:  ".$serv->{'PathName'}."\n";
  print "\tStart Name:   ".$serv->{'StateName'}."\n";
  print "\tPID:          ".$serv->{'ProcessID'}."\n";
  print "\n";
}

print "\n";
print "Processes\n";
print "-" x 20,"\n";
my $proc_set = $wmi->InstancesOf("Win32_Process");
printf "%-10s %-40s\n","PID","Name";
printf "%-10s %-40s\n","-" x 5,"-" x 20;
foreach my $proc (in($proc_set)) {
  printf "%-10s %-40s\n",$proc->{'ProcessID'},$proc->{'Name'};
}

print "\n";
print "Print Jobs\n";
print "-" x 20,"\n";
my $print_set = $wmi->InstancesOf("Win32_PrintJob");
if ($print_set->{'Count'} eq 0) {
  print "No print jobs.\n";
}
else {
  foreach my $print (in($print_set)) {
    print "Name:  ".$print->{'Name'}."\n";
    print "\tJobID:        ".$print->{'JobID'}."\n";
    print "\tStatus:       ".$print->{'Status'}."\n";
    print "\tTotal Pages:  ".$print->{'TotalPages'}."\n";
    print "\n";
  }
}

print "\n";
print "Network Connections\n";
print "-" x 20,"\n";
my $conn_set = $wmi->InstancesOf("Win32_NetworkConnection");
foreach my $conn (in($conn_set)) {
  printf "%-40s %-10s\n",$conn->{'Name'},$conn->{'Caption'};
}

print "\n";
print "Logical Disks\n";
print "-" x 20,"\n";
my $disk_set = $wmi->InstancesOf("Win32_LogicalDisk");
foreach my $disk (in($disk_set)) {
printf "%-7s %-25s %-8s
%-5s\n",$disk->{'DeviceID'},$disk->{'Description'},$disk->{'FileSystem'},$disk->
{'DriveType'};
}

print "\n";
print "Network Adapters\n";
print "-" x 20,"\n";
my $adapt_set = $wmi->InstancesOf("Win32_NetworkAdapter");
foreach my $adapt (in($adapt_set)) {
  print $adapt->{'Name'}."\n";
  print "\tType:           ".$adapt->{'AdapterType'}."\n";
  print "\tDesc:           ".$adapt->{'Description'}."\n";
  print "\tDeviceID:       ".$adapt->{'DeviceID'}."\n";
  print "\tStatus:         ".$adapt->{'Status'}."\n";
  print "\tManuf:          ".$adapt->{'Manufacturer'}."\n";
  print "\tMAC:            ".$adapt->{'MACAddress'}."\n";
  print "\tInstall Date:   ".$adapt->{'InstallDate'}."\n";
  print "\n";
}

#print "\n";
#print "Desktop\n";
#print "-" x 20,"\n";
#my $dt_set = $wmi->InstancesOf("Win32_Desktop");
#foreach my $dt (in($dt_set)) {
#  print $dt->{'Name'}."\n";
#  print "\tScreenSave active:   ".$dt->{'ScreenSaverActive'}."\n";
#  print "\tScreenSaver .exe:    ".$dt->{'ScreenSaverExecutable'}."\n";
#  print "\tScreenSaver secure:  ".$dt->{'ScreenSaverSecure'}."\n";
#  print "\tScreenSaver timeout: ".$dt->{'ScreenSaverTimeout'}." sec\n";
#  print "\n";
#}

print "\n";
#print "User Accounts\n";
#print "-" x 20,"\n";
#my $user_set = $wmi->InstancesOf("Win32_UserAccount");
#foreach my $user (in($user_set)) {
#  print $user->{'Name'}."\n";
#  print "\tDomain:       ".$user->{'Domain'}."\n";
#  print "\tSID:          ".$user->{'SID'}."\n";
#  print "\tCaption:      ".$user->{'Caption'}."\n";
#  print "\tDescription:  ".$user->{'Description'}."\n";
#  print "\tDisabled:     ".$user->{'Disabled'}."\n";
#  print "\tStatus:       ".$user->{'Status'}."\n";
#  print "\tLockout:      ".$user->{'Lockout'}."\n";
#  print "\t***Password Settings***\n";
#  print "\t\tChangeable:  ".$user->{'PasswordChangeable'}."\n";
#  print "\t\tRequired:    ".$user->{'PasswordRequired'}."\n";
#  print "\t\tExpires:     ".$user->{'PasswordExpires'}."\n";
#  print "\n";
#}
