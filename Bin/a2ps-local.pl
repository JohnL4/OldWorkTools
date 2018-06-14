#!c:/perl/bin/perl
# "a2ps" text to PostScript filter written in perl by Gisle Aas, NCC 1990
# version 1.1
#
# Efforts have been made to produce nice and effective PostScript. The
# output conforms to Adobe's document structuring conventions version-2.1.
# 
# Whish list:  (this may become a feature some time)
#     Line number on the last line (in addition to each 5th line)
#     Marking (by some funny char) truncation and wrapping of lines
#     Faster execution (rewrite the hole thing in C?)
#     Parsing of backspace to produce bold and underlined fonts.

# Some configuration constants, meassured in points (1/72 inch)
sub a4_top        { 841; }
sub a4_right_edge { 595; }

# The next few entries are from the AFM file for Adobe's font Courier
sub cour_char_width     { 600; }   # The width of each char in 1000x1000 square
#sub underline_position  { -82; }   # Where underline goes relative to baseline
#sub underline_thickness {  40; }   # and it's thickness

# Parse command line for options and flags
do 'getopts.pl';
unless (&Getopts('nrth12s:b:l')) {
   print STDERR "Usage: a2ps [-<options>] [file]...\n";
   print STDERR "Options: -n       norwegian 7bit-ascii encoding\n";
   print STDERR "         -l       print with line numbers\n";
   print STDERR "         -r       rotated, landscape orientation\n";
   print STDERR "         -t       truncate long lines, " . 
                                  "default is to wrap lines\n";
   print STDERR "         -b\"text\" replaces the text in the page header\n";
   print STDERR "         -h       no page headers\n";
   print STDERR "         -2       set text in two columns\n";
   print STDERR "         -s<size> select new text fontsize, default 10pt\n";
   exit(1);
}

# Set default values, some based on command line options
$left_margin  = 80;
$right_margin = 40;
$tb_margin    = 45;
$font         = "Courier";
$font_size    = 10;		$font_size = $opt_s if ($opt_s > 0);
$header_font  = "Helvetica-Bold";
$header_font_size = 12;
$line_number_font = "Helvetica";
$line_number_size = 5;

$line_height = $font_size * 1.08;
$no_columns = defined($opt_2) ? 2 : 1;
$col_separation = 30;
$sep_bars = '';                 # false
$landscape = defined($opt_r);
$header_height = 30;
$show_header = !defined($opt_h);
$wrap_lines = !defined($opt_t);
$truncate_lines = !$wrap_lines; # don't change this
$norsk_ascii = defined($opt_n);

# Some initial values
$opt_b = &ps_string($opt_b) if ($opt_b);
$form_feed = ''; # false;
$page_no  = 0;
$line_no = 0;
if ($landscape) {
    $top = &a4_right_edge;
    $right_edge = &a4_top;
    $left_margin = $right_margin; # this is a dirty one
} else {
    $top = &a4_top;
    $right_edge = &a4_right_edge;
}
$home_pos = $top - $tb_margin - ($show_header ? $header_height : 0);
$col_width = ($right_edge - $left_margin - $right_margin
              - ($no_columns - 1) * $col_separation) / $no_columns;
$char_width = &cour_char_width * $font_size / 1000;
$chars_per_line = int ($col_width / $char_width + 1);

&prolog;

$cur_pos = -1;
$cur_col = 100;
$file_name = &ps_string($ARGV[0]);
LINES:
while (<>) {
   chop;
   $line_no++;
   if (ord == 014) {		# form feed
       s/.//;	# chop off first char
       $cur_pos = -1; 
       next LINES if (length == 0);
   }
   while (s/\t/' ' x (8 - length($`) % 8)/e) {}   # expand tabs
   do {
      if ($cur_pos < $tb_margin) {
          $cur_pos = $home_pos;
          if ($cur_col < $no_columns) {
              $cur_col++;
          } else {
              $cur_col = 1;
              &new_page;
          }
      }
      $text = substr($_,0,$chars_per_line);
      $_ = $truncate_lines ? '' : substr($_,$chars_per_line,10000);
      if ($text =~ s/^ +//) {			# suppress leading blanks
          $indent = $char_width * length($&);
      } else {
          $indent = 0;
      }
      # Make suitable as a postscript string
      $text =~ s/[\\\(\)]/\\$&/g;
      $text =~ s/[\000-\037\177-\377]/sprintf("\\%03o",ord($&))/ge;
      # Calculate position
      $x = $left_margin + ($cur_col - 1) * ($col_width + $col_separation);
      $cur_pos -= $line_height;
      printf "(%s)%.1f %.1f S\n", $text, $x + $indent, $cur_pos 
             if (length($text));
      if ($opt_l && ($line_no % 5) == 0) { # print line numbers
          print "F2 SF ";
          printf "($line_no) dup stringwidth pop neg %.1f add %.1f M show ",
                  $x - 10, $cur_pos;
          print "F1 SF\n";
      }
      if (eof) {
         $file_name = &ps_string($ARGV[0]);
         $cur_pos = -1;  # will force a new column next time
         $cur_col = 100; # will force a new page next time
         $line_no = 0;
      }
   } while (length($_));
}
&end_page;
print "%%Trailer\n";
print "%%Pages: $page_no\n";

#--end of main-------------------------------------------------------


sub prolog {
   local($user) = getlogin || "(unknown)";
   local($sec,$min,$hour,$mday,$mon,$year) = localtime;
   $date = sprintf("(%d. %s %d) (%2d:%02d)",$mday,
                    ('Januar','Februar','Mars','April','Mai','Juni',
                     'Juli','August','Oktober','November','Desember')[$mon],
                     $year+1900, $hour,$min);
#   open(LOG,">>/home/boeygen/aas/.a2ps-log");
#   print LOG "$user, $date\n";
#   close(LOG);

   print "%!PS-Adobe-2.0\n";
   print "%%Title: @ARGV\n" if (@ARGV);
   print <<"EOT";
%%Creator: a2ps, Text to PostScript filter in perl, (C) 1990 Gisle Aas, NCC
%%CreationDate: $date
%%For: $user
%%Pages: (atend)
%%DocumentFonts: $font
EOT
   print "%%+ $line_number_font\n" if ($opt_l);
   print "%%+ $header_font\n" if ($show_header);
   print <<"EOT";
%%EndComments
/S{moveto show}bind def
/M{moveto}bind def
/L{lineto}bind def
/SF{setfont}bind def
%%BeginProcSet: reencode 1.0 0
/RE { %def
   findfont begin
   currentdict dup length dict begin
        { %forall
             1 index/FID ne {def} {pop pop} ifelse
         } forall
         /FontName exch def dup length 0 ne { %if
            /Encoding Encoding 256 array copy def
            0 exch { %forall
                dup type /nametype eq { %ifelse
                    Encoding 2 index 2 index put
                    pop 1 add
                 }{%else
                    exch pop
                 } ifelse
          } forall
       } if pop
    currentdict dup end end
    /FontName get exch definefont pop
} bind def
%%EndProcSet: reencode 1.0 0
%%EndProlog
%%BeginSetup
0.15 setlinewidth
EOT
   if ($norsk_ascii) {
      print "[8#133 /AE/Oslash/Aring 8#173 /ae/oslash/aring] dup\n";
      print "/Body-Font/$font RE\n";
      print "/Header-Font/$header_font RE\n" if ($show_header);
   } else {
      print "ISOLatin1Encoding /Body-Font/$font RE\n";
      print "ISOLatin1Encoding /Header-Font/$header_font RE\n"
         if ($show_header);
   }
   print "/F1/Body-Font findfont $font_size scalefont def\n";
   print "/F2/$line_number_font findfont $line_number_size scalefont def\n"
        if ($opt_l);
   print "/F3/Header-Font findfont $header_font_size scalefont def\n"
        if ($show_header);
   print "F1 SF\n";
   if ($landscape) {
      printf "90 rotate 0 -%d translate %% landscape mode\n",&a4_right_edge;
   }
   print "%%EndSetup\n";
}



sub new_page {
   &end_page unless ($page_no == 0);
   $page_no++;
   print "%%Page: $page_no $page_no\n";
   print "/my_save save def\n";
   if ($show_header) {
      # First print a box
      local($llx,$lly,$urx,$ury) = ($left_margin - 10,
            $top - $tb_margin - $header_font_size * 1.3,
            $right_edge - $right_margin + 10, $top - $tb_margin);
      printf "%.1f %.1f M %.1f %.1f L %.1f %.1f L ",
             $llx,$lly, $urx,$lly, $urx, $ury;
      printf "%.1f %.1f L closepath \n",$llx,$ury;
      print  "gsave .95 setgray fill grestore stroke\n";
      # Then the banner or the filename
      print "F3 SF\n";
      if ($opt_b) {
         printf "($opt_b)%.1f %.1f S\n",
                $left_margin,$top - $tb_margin - $header_font_size;
      }
      elsif ($file_name) {
         printf "(%s)%.1f %.1f S\n", $file_name, 
                      $left_margin,
                      $top - $tb_margin - $header_font_size;
      }
      # Then print page number
      printf "%.1f %.1f M($page_no)dup stringwidth pop neg 0 rmoveto show\n",
                 $right_edge - $right_margin, 
                 $top - $tb_margin - $header_font_size;
      print  "F1 SF\n";
   }
   if ($sep_bars) {
      print "% Some postscript code to draw horizontal bars.\n";
      print "% Not implemented yet\n";
   }
}

sub end_page {
   unless ($page_no == 0) {
      print "showpage\n";
      print "my_save restore\n";
   }
}

sub ps_string
{
   # Prepare text for printing
   local($_) = shift;
   s/[\\\(\)]/\\$&/g;
   s/[\001-\037\177-\377]/sprintf("\\%03o",ord($&))/ge;
   $_;    # return string
}



