use strict;
use Win32::OLE qw(in with);
use Win32::OLE::Const;
use Win32::OLE::Const 'Microsoft Excel';
$Win32::OLE::Warn = 3;        # die on errors...

my $filename = 'c:\\dexma\\test.xls';
my $filter = 'GIF';           # can be GIF, JPG, JPEG or PNG
my $count = 0;

my $Excel = Win32::OLE->GetActiveObject('Excel.Application')
    || Win32::OLE->new('Excel.Application', 'Quit');  # use the Excel application if it's open, otherwise open new
my $Book = $Excel->Workbooks->Open( $filename );      # open the file
foreach my $Sheet (in $Book->Sheets) {                # loop through all sheets
    foreach my $ChartObj (in $Sheet->ChartObjects) {  # loop through all chartobjects in the sheet
        my $savename = "$filename." . $count++ . ".$filter";
        $ChartObj->Chart->Export({
            FileName    => $savename,
            FilterName  => $filter,
            Interactive => 0});
    }
}
$Book->Close;
