#!/usr/local/bin/perl -w
#
# ButtonFactory package
# by t0mas@netlords.net
#

package ButtonFactory;

use strict;
use GD;

# libgd should be compiled with TrueType support. The built-in fonts are
# pretty lame IMO (international characters work poorly).

######################################################################
# Config section start

# Location of my ttf fonts
# If set to "", the full path to the font file must be supplied. Windows
# users might want to set it to c:\\windows\\fonts\\ and *nix users to
# /my/path/to/the/ttf/fonts/
my $FONTDIR="c:\\windows\\fonts\\";

# Fonts will be black or white.
# This value is the breakpoint where it turns white. It is compared to the
# sum of baseR+baseG+baseB. Fonts turn white when this sum drops below
# the breakpoint.
my $FONTCOLORBREAKPOINT=255;

# Height and width of the sides (4 by default)
# Use a sane value > 1 or UltraBad(tm) things will happen
my $SIDE_X_WIDTH=4;
my $SIDE_Y_WIDTH=4;

# Config section end
######################################################################

######################################################################
# My view of a button.
#
# Based on a 4 pixel wide side on all sides :)
#
# Map of the four corners (1-M refers to factors to use)
#
# 69333 333EB
# 97A22 22GCF
# 3A7A2 2GCH5
# 32A83 3DH45
# 32231 15445
#
# 32231 15445
# 32GD5 5KM45
# 3GCH4 4MJM5
# ECH44 44MJL
# BF555 555LI
#
# Above is the map of the normal (up) state, the pressed state uses
# the same map rotated 180 degrees.
######################################################################

#
# Factors for colors                # on Map
#

my $dark_side_factor =                0.03;    # 4
my $lr_edge_bevel_factor =            0.03;    # M
my $lr_edge_factor =                0.04;    # J
my $llur_b_edge_bevel_factor =        0.24;    # H
my $lr_i_corner_factor =            0.31;    # K
my $dark_edge_factor =                0.44;    # 5
my $lr_o_corner_bevel_factor =        0.47;    # L
my $lr_o_corner_factor =            0.65;    # I
my $llur_edge_factor =                0.72;    # C
my $llur_b_o_corner_bevel_factor =    0.75;    # F
my $llur_i_corner_factor =            0.85;    # D
my $llur_o_corner_factor =            0.95;    # B
my $base_factor =                    1.00;    # 1
my $llur_l_o_corner_bevel_factor =    1.03;    # E
my $llur_l_edge_bevel_factor =        1.07;    # G
my $light_side_factor =                1.17;    # 2
my $light_edge_factor =                1.23;    # 3
my $ul_o_corner_factor =            1.26;    # 6
my $ul_edge_bevel_factor =            1.29;    # A
my $ul_o_corner_bevel_factor =        1.33;    # 9
my $ul_i_corner_factor =            1.39;    # 8
my $ul_edge_factor =                1.41;    # 7

######################################################################
sub new {

    #
    # Create new ButtonFactory
    #

    # Hello, this is me...
    my $self={};

    # Get class and parameters
    my $class=shift;

    # Set attributes or defaults
    $self->{sizeX}=shift    || 100;
    $self->{sizeY}=shift    || 20;
    $self->{baseR}=shift    || 70;
    $self->{baseG}=shift    || 82;
    $self->{baseB}=shift    || 157;
    $self->{text}=shift     || "Hello World";
    $self->{font}=shift     || "arial.ttf";
    $self->{fontsize}=shift || 8;

    # Create images for normal and pressed state
    $self->{imNormal}=new GD::Image($self->{sizeX},$self->{sizeY});
    $self->{imNormalPrinted}=0;
    $self->{imPressed}=new GD::Image($self->{sizeX},$self->{sizeY});
    $self->{imPressedPrinted}=0;

    # Bless and return
    bless $self, $class;
    return $self;
};

######################################################################
sub color {

    #
    # Allocate colors for GD::Image
    #

    # Me
    my $self=shift;

    # Which state
    my $stateName=shift || "imNormal";

    # Factor for this color
    my $factor=shift || 1;

    # Multiply base colors with factor
    my $Red=int($self->{baseR}*$factor);
    my $Green=int($self->{baseG}*$factor);
    my $Blue=int($self->{baseB}*$factor);

    # Validity check
    $Red=$Red>255 ? 255 : $Red;
    $Green=$Green>255 ? 255 : $Green;
    $Blue=$Blue>255 ? 255 : $Blue;

    # Return allocated color
    return $self->{$stateName}->colorAllocate($Red,$Green,$Blue);
};

######################################################################
sub printNormal {

    #
    # Wrapper to print and/or create Normal (up) state
    #

    # Me
    my $self=shift;

    # Check if image is already generated
    if ($self->{imNormalPrinted}) {
        return $self->{imNormal}->png;
    } else {
        return $self->print(1);
        $self->{imNormalPrinted}=1;
    }
};

######################################################################
sub printPressed {

    #
    # Wrapper to print and/or create Pressed (down) state
    #

    # Me
    my $self=shift;

    # Check if image is already generated
    if ($self->{imPressedPrinted}) {
        return $self->{imPressed}->png;
    } else {
        return $self->print(0);
        $self->{imPressedPrinted}=1;
    }
};

######################################################################
sub print {

    #
    # Print a button
    # (Please, don't use me, use printNormal or printPressed instead.)
    #

    # Me
    my $self=shift;

    # Normal or Pressed state?
    my $state=shift;
    my $stateName=$state ? "imNormal" : "imPressed";

    # Allocate colors
    my $base = $self->color($stateName,$base_factor);
    my $light_edge = $self->color($stateName,$light_edge_factor);
    my $ul_o_corner = $self->color($stateName,$ul_o_corner_factor);
    my $ul_edge = $self->color($stateName,$ul_edge_factor);
    my $ul_i_corner = $self->color($stateName,$ul_i_corner_factor);
    my $ul_o_corner_bevel = $self->color($stateName,
        $ul_o_corner_bevel_factor);
    my $ul_edge_bevel = $self->color($stateName,$ul_edge_bevel_factor);
    my $llur_o_corner = $self->color($stateName,$llur_o_corner_factor);
    my $llur_edge = $self->color($stateName,$llur_edge_factor);
    my $llur_i_corner = $self->color($stateName,$llur_i_corner_factor);
    my $llur_l_o_corner_bevel = $self->color($stateName,
        $llur_l_o_corner_bevel_factor);
    my $llur_b_o_corner_bevel = $self->color($stateName,
        $llur_b_o_corner_bevel_factor);
    my $llur_l_edge_bevel = $self->color($stateName,
        $llur_l_edge_bevel_factor);
    my $llur_b_edge_bevel = $self->color($stateName,
        $llur_b_edge_bevel_factor);
    my $dark_edge = $self->color($stateName,$dark_edge_factor);
    my $light_side = $self->color($stateName,$light_side_factor);
    my $dark_side = $self->color($stateName,$dark_side_factor);
    my $lr_o_corner = $self->color($stateName,$lr_o_corner_factor);
    my $lr_edge = $self->color($stateName,$lr_edge_factor);
    my $lr_i_corner = $self->color($stateName,$lr_i_corner_factor);
    my $lr_o_corner_bevel = $self->color($stateName,
        $lr_o_corner_bevel_factor);
    my $lr_edge_bevel = $self->color($stateName,$lr_edge_bevel_factor);

    # Set the color of the fonts based on the value of $FONTCOLORBREAKPOINT
    my $fontColor=($self->{baseR}+$self->{baseG}+$self->{baseB})>
        $FONTCOLORBREAKPOINT?$self->{$stateName}->colorAllocate(0,0,0):
        $self->{$stateName}->colorAllocate(255,255,255);

    # Fill everything with base color
    $self->{$stateName}->fill(int($self->{sizeX}/2),int($self->{sizeY}/2),
        $base);

    # Draw edge and center rectangles
    $self->{$stateName}->rectangle(0,0,$self->{sizeX}-1,$self->{sizeY}-1,
        $light_edge);
    $self->{$stateName}->rectangle($SIDE_X_WIDTH-1,$SIDE_Y_WIDTH-1,
        $self->{sizeX}-$SIDE_X_WIDTH,$self->{sizeY}-$SIDE_Y_WIDTH,
        $light_edge);

    # Draw upper left corner
    $self->{$stateName}->setPixel(0,0,$state?$ul_o_corner:$lr_o_corner);
    $self->{$stateName}->line(1,1,$SIDE_X_WIDTH-2,$SIDE_Y_WIDTH-2,$state?
        $ul_edge:$lr_edge);
    $self->{$stateName}->setPixel($SIDE_X_WIDTH-1,$SIDE_Y_WIDTH-1,$state?
        $ul_i_corner:$lr_i_corner);
    $self->{$stateName}->line(0,1,1,0,$state?$ul_o_corner_bevel:
        $lr_o_corner_bevel);
    $self->{$stateName}->line(2,1,$SIDE_X_WIDTH-1,$SIDE_Y_WIDTH-2,$state?
        $ul_edge_bevel:$lr_edge_bevel);
    $self->{$stateName}->line(1,2,$SIDE_X_WIDTH-2,$SIDE_Y_WIDTH-1,$state?
        $ul_edge_bevel:$lr_edge_bevel);

    # Draw lower left corner
    $self->{$stateName}->setPixel(0,$self->{sizeY}-1,$llur_o_corner);
    $self->{$stateName}->line(1,$self->{sizeY}-2,$SIDE_X_WIDTH-2,
        $self->{sizeY}-$SIDE_Y_WIDTH+1,$llur_edge);
    $self->{$stateName}->setPixel($SIDE_X_WIDTH-1,$self->{sizeY}-$SIDE_Y_WIDTH,
        $llur_i_corner);
    $self->{$stateName}->setPixel(0,$self->{sizeY}-2,$state?
        $llur_l_o_corner_bevel:$llur_b_o_corner_bevel);
    $self->{$stateName}->setPixel(1,$self->{sizeY}-1,$state?
        $llur_b_o_corner_bevel:$llur_l_o_corner_bevel);
    $self->{$stateName}->line(1,$self->{sizeY}-3,$SIDE_X_WIDTH-2,
        $self->{sizeY}-$SIDE_Y_WIDTH,$state?$llur_l_edge_bevel:
        $llur_b_edge_bevel);
    $self->{$stateName}->line(2,$self->{sizeY}-2,$SIDE_X_WIDTH-1,
        $self->{sizeY}-$SIDE_Y_WIDTH+1,$state?$llur_b_edge_bevel:
        $llur_l_edge_bevel);

    # Draw upper right corner
    $self->{$stateName}->setPixel($self->{sizeX}-1,0,$llur_o_corner);
    $self->{$stateName}->line($self->{sizeX}-2,1,
        $self->{sizeX}-$SIDE_X_WIDTH+1,$SIDE_Y_WIDTH-2,$llur_edge);
    $self->{$stateName}->setPixel($self->{sizeX}-$SIDE_X_WIDTH,$SIDE_Y_WIDTH-1,
        $llur_i_corner);
    $self->{$stateName}->setPixel($self->{sizeX}-2,0,$state?
        $llur_l_o_corner_bevel:$llur_b_o_corner_bevel);
    $self->{$stateName}->setPixel($self->{sizeX}-1,1,$state?
        $llur_b_o_corner_bevel:$llur_l_o_corner_bevel);
    $self->{$stateName}->line($self->{sizeX}-3,1,$self->{sizeX}-$SIDE_X_WIDTH,
        $SIDE_Y_WIDTH-2,$state?$llur_l_edge_bevel:$llur_b_edge_bevel);
    $self->{$stateName}->line($self->{sizeX}-2,2,$self->{sizeX}-$SIDE_X_WIDTH+1,
        $SIDE_Y_WIDTH-1,$state?$llur_b_edge_bevel:$llur_l_edge_bevel);

    # Draw lower right corner
    $self->{$stateName}->setPixel($self->{sizeX}-1,$self->{sizeY}-1,$state?
        $lr_o_corner:$ul_o_corner);
    $self->{$stateName}->line($self->{sizeX}-2,$self->{sizeY}-2,
        $self->{sizeX}-$SIDE_X_WIDTH+1,$self->{sizeY}-$SIDE_Y_WIDTH+1,
        $state?$lr_edge:$ul_edge);
    $self->{$stateName}->setPixel($self->{sizeX}-$SIDE_X_WIDTH,
        $self->{sizeY}-$SIDE_Y_WIDTH,$state?$lr_i_corner:$ul_i_corner);
    $self->{$stateName}->line($self->{sizeX}-1,$self->{sizeY}-2,
        $self->{sizeX}-2,$self->{sizeY}-1,$state?$lr_o_corner_bevel:
        $ul_o_corner_bevel);
    $self->{$stateName}->line($self->{sizeX}-3,$self->{sizeY}-2,
        $self->{sizeX}-$SIDE_X_WIDTH,$self->{sizeY}-$SIDE_Y_WIDTH+1,$state?
        $lr_edge_bevel:$ul_edge_bevel);
    $self->{$stateName}->line($self->{sizeX}-2,$self->{sizeY}-3,
        $self->{sizeX}-$SIDE_X_WIDTH+1,$self->{sizeY}-$SIDE_Y_WIDTH,$state?
        $lr_edge_bevel:$ul_edge_bevel);


    # Draw dark edges
    $self->{$stateName}->line(2,$state?$self->{sizeY}-1:0,$self->{sizeX}-3,
        $state?$self->{sizeY}-1:0,$dark_edge);
    $self->{$stateName}->line($state?$self->{sizeX}-1:0,2,$state?
        $self->{sizeX}-1:0,$self->{sizeY}-3,$dark_edge);
    $self->{$stateName}->line(
        $state?$self->{sizeX}-$SIDE_X_WIDTH:$SIDE_X_WIDTH-1,
        $SIDE_Y_WIDTH,
        $state?$self->{sizeX}-$SIDE_X_WIDTH:$SIDE_X_WIDTH-1,
        $self->{sizeY}-$SIDE_Y_WIDTH-1,
        $dark_edge);
    $self->{$stateName}->line(
        $SIDE_X_WIDTH,
        $state?$self->{sizeY}-$SIDE_Y_WIDTH:$SIDE_Y_WIDTH-1,
        $self->{sizeX}-$SIDE_X_WIDTH-1,
        $state?$self->{sizeY}-$SIDE_Y_WIDTH:$SIDE_Y_WIDTH-1,
        $dark_edge);

    # Fill sides
    $self->{$stateName}->fill(int($self->{sizeX}/2),1,
        $state?$light_side:$dark_side);
    $self->{$stateName}->fill(1,int($self->{sizeY}/2),
        $state?$light_side:$dark_side);
    $self->{$stateName}->fill($self->{sizeX}-2,int($self->{sizeY}/2),
        $state?$dark_side:$light_side);
    $self->{$stateName}->fill(int($self->{sizeX}/2),$self->{sizeY}-2,
        $state?$dark_side:$light_side);

    # Print text
    # The text must be able to be printed in a box of
    # @bounds[0,1]=5,$self->{sizeY}-7
    # @bounds[2,3]=$self->{sizeX}-7,$self->{sizeY}-7
    # @bounds[4,5]=$self->{sizeX}-7,5
    # @bounds[6,7]=5,5

    # Set wanted fontsize (could be smaller after TEXTRESIZE)
    my $textHeight=$self->{fontsize};
    my @bounds=[];

    # Loop to size text to button area
    TEXTRESIZE: while (1) {
        # See what bounds we get if we would print
        @bounds = GD::Image->stringTTF(
            $fontColor,
            $FONTDIR.$self->{font},
            $textHeight,
            0,
            ($SIDE_X_WIDTH+1),
            ($self->{sizeY}-($SIDE_Y_WIDTH+3)),
            $self->{text});
        if ($@) {
            # Some error (like no TTF support)
            last TEXTRESIZE;
        }

        # If text is out of bounds, try to resize it
        if ($bounds[4]>($self->{sizeX} - ($SIDE_X_WIDTH+3)) ||
            $bounds[4]<0 ||
            $bounds[5]<($SIDE_Y_WIDTH+1) ||
            $bounds[5]<0) {
            if (--$textHeight<1) {
                # Couldn't fit text in button
                last TEXTRESIZE;
            }
            next TEXTRESIZE;
        }

        # Set fontsize to the new? value
        $self->{fontsize}=$textHeight;

        # Print the text (centered on button)
        $self->{$stateName}->stringTTF(
            $fontColor,
            $FONTDIR.$self->{font},
            $textHeight,
            0,
            ($SIDE_X_WIDTH+1)+
                int(($self->{sizeX}-($bounds[4]-$bounds[6])-
                (($SIDE_X_WIDTH*2)+2))/2),
            $self->{sizeY}-($SIDE_Y_WIDTH+3)-
                int(($self->{sizeY}-($bounds[1]-$bounds[7])-
                (($SIDE_Y_WIDTH*2)+2))/2),
            $self->{text});
        last TEXTRESIZE;
    }

    # Convert the image to PNG and return it
    return $self->{$stateName}->png;
};

######################################################################
1;

__END__


=head1 NAME

ButtonFactory - A button factory

=head1 DESCRIPTION

A package that creates custom png buttons.

=head1 SYNOPSIS

A non-web example to generate buttons to files:

 #!/usr/local/bin/perl -w
 use ButtonFactory;

 my $x=new ButtonFactory(100,20,70,82,157,"Hello World","arial.ttf",8);

 open (FILE,">Normal.png") or die $!;
 binmode FILE;
 print FILE $x->printNormal();
 close (FILE);

 open (FILE,">Pressed.png") or die $!;
 binmode FILE;
 print FILE $x->printPressed();
 close (FILE);

A web example (let's call it getbutt.cgi :) to print buttons to a browser:

 #!/usr/local/bin/perl -w
 use ButtonFactory;
 use CGI qw(:standard);

 # Get query parameters
 my $query = new CGI;
 $x = $query->param('x');
 $y = $query->param('y');
 $r = $query->param('r');
 $g = $query->param('g');
 $b = $query->param('b');
 $txt = $query->param('txt');
 $ttf = $query->param('ttf');
 $fs = $query->param('fs');
 $state = $query->param('state');

 # Create the button
 my $butt=new ButtonFactory($x,$y,$r,$g,$b,$txt,$ttf,$fs);

 # Calculate size of button and pour it out to the user
 print "Content-Type: image/png\n\n";
 binmode STDOUT;
 print $state?$butt->printNormal():$butt->printPressed();

And a sample (pretty_silly.html) html page for it:

 <html>
 <head><title>Buttons</title>
 <script language="JavaScript">
     // browser detection
     var OK = ((navigator.appName.charAt(0)=='N' &&
         navigator.appVersion.charAt(0)=='3') ||
         navigator.appVersion.charAt(0)=='4');
     // Preload clicked image
     if (OK) {
         preload = new Image();
         preload.src ='cgi-bin/getbutt.cgi?x=100&y=20&r=70&g=82&b=157&' +
             'txt=Hello+World&ttf=arial.ttf&fs=8&state=0';
     }
     // mouseclick f/x
     function click(i) {if (OK) {document['butt'+i].src =
         'cgi-bin/getbutt.cgi?x=100&y=20&r=70&g=82&b=157&txt=Hello+World&' +
         'ttf=arial.ttf&fs=8&state=0';}}
     function out(i) {if (OK) {document['butt'+i].src =
         'cgi-bin/getbutt.cgi?x=100&y=20&r=70&g=82&b=157&txt=Hello+World&' +
         'ttf=arial.ttf&fs=8&state=1';}}
 </script>
 </head>
 <body bgcolor=#ffffff>
 A button test...<br>
 <a href="helloworld.html" onClick="click(0);alert('Click...');out(0);">
 <img name="butt0" src=
 "cgi-bin/getbutt.cgi?x=100&y=20&r=70&g=82&b=157&txt=Hello+World&ttf=arial.ttf&fs=8&state=1"
 alt="Hello World" width=100 height=20 border=0></a><br>
 </body>
 </html>

=head1 Methods

=over 4

=item new(sizeX,sizeY,red,green,blue,text,font,fontsize)

Creates a new ButtonFactory object with sizeX*sizeY pixel size. Values for red,
green and blue in decimal range 0-255. ButtonFactory will try its best to size
the font to make the text fit on the button, so the fontsize supplied is the
largest size the text can have.
The font should be a TrueType font with its .ttf extension, 'arial.ttf'. In the
configuration section of ButtonFactory you may set $FONTDIR to the directory
where you store your TrueType fonts. If $FONTDIR is set to '' (empty string)
you must supply the whole path to the font you want to use.

=item printNormal()

Prints the button in its up state. The GD image is stored internaly so the
second time you use printNormal, ButtonFactory can use the stored image. This
improves speed if you need to get the size of the printed button before printing
it. Useful when you need to print Content-length before the image on a
multipart/x-mixed-replace HTML documet.

=back

=head1 SEE ALSO

L<GD>

=head1 DISCLAIMER

I do not guarantee B<ANYTHING> with this package. If you use it you
are doing so B<AT YOUR OWN RISK>! I may or may not support this
depending on my time schedule...

=head1 AUTHOR

t0mas@netlords.net

=head1 COPYRIGHT

Copyright 1999-2000, t0mas@netlords.net

This package is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


com
