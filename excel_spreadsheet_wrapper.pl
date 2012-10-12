#!c:/perl/bin -w
#
# excel_spreadsheet_wrapper.pl
#


use strict;
use warnings;
use diagnostics;
use Spreadsheet::WriteExcel;
package Excel;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    bless ($self, $class);
    $self->init(@_);
    return $self;
}

sub init {
    my ($self, $fname) = @_;
    $self->{workbook} = Spreadsheet::WriteExcel->new($fname);
}

sub getformat {
    my ($self, @fmts) = @_;
    my $format = $self->{workbook}->addformat();
    # metafmts allows you define combinations of formats, like CSS
    # may be nested, may not be circular
    my %metafmts = (
            header => [qw(bold blue)]
            );
    while (@fmts) {
    $_ = shift @fmts;
    if ($metafmts{$_}) {push(@fmts, @{$metafmts{$_}}); delete $metafmts{$_}; next;}
    if (/default/) {
        $format->set_format(3); # commas, no decimals
    } elsif (/bigmoney/) {
        $format->set_format(5); # dollar sign, commas, no decimals
    } elsif (/money/) {
        $format->set_format(7); # dollar sign, commas, pennies
    } elsif (/pct/) {
        $format->set_format(10); # percent, two digit
    } elsif (/bold/) {
        $format->set_bold(1); # bold on
    } elsif (/sumline/) {
        $format->set_bottom(6); # double underline
    } elsif (/border/) {
        $format->set_border(1); # border all around
    } elsif (/size(\d+)/) {
        $format->set_size(0+$1); # size
    } elsif (/italic/) {
        $format->set_italic(1); # italic
    } elsif (/underline/) {
        $format->set_underline(1); # text underline
    } elsif (/left|right|center/) {
        $format->set_align($_); # alignment
    } elsif (/black|blue|red|green|purple|silver|yellow|gray|orange/) {
        $format->set_color($_); # colors
    } else {
        die "unknown or circular format string: $_";
    }
    }
    return $format;
}

sub writecell {
    my ($self, $worksheet, $row, $col, $value) = @_;
    my ($val, @formats);
    if (!ref($value)) {
    $val = $value; @formats = qw(default);
    } elsif (ref($value) eq 'ARRAY') {
    $val = shift(@{$value});  @formats = @{$value};
    } else {die ref($value);}
    my $fmtobj = $self->getformat(@formats);
    $self->{worksheet}{$worksheet}{ptr}->write($row,$col, $val, $fmtobj);

}

sub write {
    my ($self, $worksheet, @vals) = @_;
    # if this is a new tab, create it
    if (!defined($self->{worksheet}{$worksheet}{ptr})) {
    $self->{worksheet}{$worksheet}{ptr} =
        $self->{workbook}->addworksheet($worksheet);
    $self->{worksheet}{$worksheet}{row} = 0;
    $self->{worksheet}{$worksheet}{col} = 0;
    }
    my $row = $self->{worksheet}{$worksheet}{row};
    my $col = $self->{worksheet}{$worksheet}{col};
    foreach (@vals) {
    $self->writecell($worksheet,$row,$col,$_);
    $col++;
    }
    $self->{worksheet}{$worksheet}{col} = $col;
}

sub writeln {
    my ($self, $worksheet, @vals) = @_;
    $self->write($worksheet, @vals);
    $self->{worksheet}{$worksheet}{row}++;
    $self->{worksheet}{$worksheet}{col} = 0;
}

1;
