use Date::Calc qw/Today Delta_Days/;
use Net::SSLeay;

my $adr = "192.168.";
my @net = qw / 97. 100. 102. 104. 105. 32. 33. 34. /;
my ($i, $j, $host);
my ($page, $result, $headers, $server_cert);
my ($port, $path) = (443, "/");
my %subject;
my %monthnum = (
    "Jan" => "1",
    "Feb" => "2",
    "Mar" => "3",
    "Apr" => "4",
    "May" => "5",
    "Jun" => "6",
    "Jul" => "7",
    "Aug" => "8",
    "Sep" => "9",
    "Oct" => "10",
    "Nov" => "11",
    "Dec" => "12"
);

for ($i=0; $i<=7; $i++) {
  HOST: for ($j=16; $j<=250; $j++) {
		$host = $adr . $net[$i] . $j;
    ($page, $result, $headers, $server_cert)
      = &Net::SSLeay::get_https3($host, $port, $path);
	 if (!defined($server_cert) || ($server_cert == 0)) {
			next HOST;
	 } else {
		print $host;
		
		$subject = Net::SSLeay::X509_NAME_oneline(
			 Net::SSLeay::X509_get_subject_name($server_cert));
    	$expdate = Net::SSLeay::P_ASN1_UTCTIME_put2string(
			Net::SSLeay::X509_get_notAfter($server_cert));

		foreach $item (split m*/*, $subject) {
			  @element = split /=/,$item;
				$subject{@element[0]} = @element[1];
		}
		if ($subject{OU} =~ /verisign/) {
			  $subject{OU} = "Verisign"
		} else {
			  $subject{OU} = "InstantSSL";
		}
		print ",$subject{CN},$subject{O},$subject{OU},";

		($year, $month, $day) = Today();
		($expmonth, $expday, $expyear) = ($expdate =~ /(\w{3})\s+(\d+?)\s.*\b(\d{4})/);
		$Dd = Delta_Days($year,$month,$day,$expyear,$monthnum{$expmonth},$expday);
		print "$expmonth-$expday-$expyear,$Dd\n";
    }
  }
}
