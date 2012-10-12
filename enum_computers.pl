#!c:/perl/bin -w
#
# enum_computers.pl
#


#Const ADS_SCOPE_SUBTREE = 2

#Set objConnection = CreateObject("ADODB.Connection")
#Set objCommand =   CreateObject("ADODB.Command")
#objConnection.Provider = "ADsDSOObject"
#objConnection.Open "Active Directory Provider"

#Set objCOmmand.ActiveConnection = objConnection
#objCommand.CommandText = _
#    "Select Name, Location from 'LDAP://DC=dexma,DC=auth' " & "Where objectClass='computer'"
#objCommand.Properties("Page Size") = 1000
#objCommand.Properties("Searchscope") = ADS_SCOPE_SUBTREE
#Set objRecordSet = objCommand.Execute
#objRecordSet.MoveFirst

#Do Until objRecordSet.EOF
#    Wscript.Echo "Computer Name: " & objRecordSet.Fields("Name").Value
#'    Wscript.Echo "Location: " & objRecordSet.Fields("Location").Value
#    objRecordSet.MoveNext
#Loop


use Win32::OLE;
$Win32::OLE::Warn = 3;
my $objRootDSE = Win32::OLE->GetObject("LDAP://RootDSE");
my $strBase    =  "<LDAP://cn=Partitions," .
                   $objRootDSE->Get("ConfigurationNamingContext") . ">;";
my $strFilter  = "(&(objectcategory=crossRef)(systemFlags=5));";
my $strAttrs   = "cn,ncName;";
my $strScope   = "onelevel";

my $objConn = Win32::OLE->CreateObject("ADODB.Connection");
$objConn->{Provider} = "ADsDSOObject";
$objConn->Open;
my $objRS = $objConn->Execute($strBase . $strFilter . $strAttrs . $strScope);
$objRS->MoveFirst;
while (not $objRS->EOF) {
   print $objRS->Fields("nCName")->Value,"\n";
   $objRS->MoveNext;
}