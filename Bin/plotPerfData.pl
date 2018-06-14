#!/usr/bin/perl -w
                                # -*- coding: raw-text-dos -*-

=head1 NAME

plotPerfData.pl -- Generate data plots of performance data

=head1 SYNOPSIS

 plotPerfData.pl [--dev {postscript|windows|gif|png}]
    [--gtitle <graphTitle>]
    [--lmax <leftMax>] [--ltitle <title>]
    [--rmax <rightMax>] [--rtitle <title>]
    [--year <YYYY>]
    {-f <file>,<file>,... -x <col>
         [-l | -r] [-s <scale>] [-t <title>] [--ls <linestyle>]
         -y <col>,<col>,...}...

=head2 SAMPLE USE

 plotPerfData.pl --dev "gif size 600,300"
    --gtitle 'R2.0.3, before patch P, 3500 UM Review forms'
    --rmax 100 --ltitle Bytes
    -f perfdata_092709.csv
    -x 'Sample.*Time'
    --ls 2 -y 'Avail.*Bytes'
    -r --ls 1 -y 'Tot.*Proc.*Time'
    -l --ls 2 -y 'javaw.*Working.*Set'

 /usr/local/gp371w32/wgnupl32.exe
    'C:\DOCUME~1\j80lusk\LOCALS~1\Temp\L6ZVe6RWva.gnuplot'

 ----------------------------------------------------------------

 plotPerfData.pl
    -gtitle "Multi-app-server Stress Test, Devtest3, 18 Oct 2001"
    --ltitle Bytes --rtitle "Pages/sec, % Utilization"
    --dev "postscript color solid"
    -f Devtest3/perfdata_101810.csv -x 'Sample.*Time'
    -l --ls 2 -y 'Available Bytes'
    -r --ls 1 -y 'Tot.*Proc.*Time'
    -l -s 1000 --year 2001 -f Devtest3/jrun-metrics.txt
    -x 0 --ls 3 -t "JVM TotalMem" -y 1 -t "JVM FreeMem" -y 2


=head1 DESCRIPTION

Generate data plots of the given columns from the given files.

Files specified as I<file>,I<file>,... will be concatenated before data
columns are extracted, so they should contain similar data.  If you use a
regular expression to designate the column, the files may contain
different columns so long as the regexp will work across files.

Columns are specified numerically or by "name".  If not numeric,
I<col> is a Perl regular expression matching the title of the column as given
in the input file(s).

Data is expected to be either numeric (y-values) or date/time (x-values).  If
date/time, the format is expected to be MM/DD[/YY[YY]] HH:MM[:SS].

Files specified separately (e.g. "-f I<file> -c I<col> -f I<file> -c <col>")
will result in separate curves plotted.  

See GNUPLOT_{PRE,POST}AMBLE and LINESTYLES_*, defined in this script, for more
info on the gnuplot context in which the plots will be made.

To plot w/gnuplot, run gnuplot, giving the generated script file as a
command-line argument.

=head1 PARAMETERS

=over

=item --dev

Output device.  Default is 'windows'.  Unless output is 'windows', output will
be to a file named 'gnuplot.*' in the current working dir, where '*' is some
appropriate suffix (e.g., ps, gif, png).

=item --gtitle

Graph title.  No default.

=item --lmax

Positive number, max of left axis, or nothing, in which case GnuPlot will
determine a good max.

=item --llog

Make left axis logarithmic

=item --ltitle

Title of left axis.

=item --rmax

See --lmax.

=item --rlog

Make right axis logarithmic

=item --rtitle

Title of right axis.

=item --year I<YYYY>

The current year, to be added on to MM/DD dates that don't have years.

=item -o I<filename>

The basename of the image file to ultimately be generated, with no suffix.  If
not specified, defaults to "gnuplot".  The suffix will be implied by the
specified --dev option.

=item --gnuplotCmd I<executableName>

The name of the gnuplot command to be used.  Defaults to "wgnuplot".

=item -f

The CSV file(s) from which to draw the data.  This can be comma-delimited list
of filenames.

=item -x

The name or number of the column containing x-data.

=item --timefmt I<string>

The format of date/time data on the x-axis.  Use gnuplot specification:
      %d           day of the month, 1--31
      %m           month of the year, 1--12
      %y           year, 0--99
      %Y           year, 4-digit
      %j           day of the year, 1--365
      %H           hour, 0--24
      %M           minute, 0--60
      %S           second, 0--60

Embedded spaces will determine the number of columns that make up the
x-values (e.g., "%m/%d/%Y %H:%M:%S" implies two columns for the x-values).

B<NOTE: This applies to ALL data in this run, not a particular file.>

Default is "%m/%d/%Y %H:%M:%S".

=item -l

Curves following this option are to be plotted against the lefthand y-axis.

=item -r

Curves following this option are to be plotted against the righthand y-axis.

=item -t

Title for following curve(s).

=item --ls

GnuPlot linestyle (integer) for following curve(s).  See the LINESTYLES_*
variables defined in this script.

=item -w I<gnuplot-'with'-style>

Specifies the gnuplot style to be applied to the following curve(s).  Try one
of these:
   lines
   points
   linespoints
   impulses
   dots
   steps -- over, then up
   fsteps -- up, then over
   histeps -- histogram, centered on x-value
   boxes -- boxes from x-axis, centered on x-value
   (see gnuplot docs for others)

=item -y

Name (regexp) or number of column(s) from which to draw y-data.  USE OF
MULTIPLE SELECTORS IN A COMMA-DELIMITED LIST IS DEPRECATED.  Just use multiple
-y options instead.

=item -as I<string>

Plot y-column as I<string> in graph legend.

=item --dupskip I<integer>

In case there are multiple columns that match the given spec in the data, skip
the first I<n> of them.

=back

=head1 AUTHOR

john.lusk@canopysystems.com

=head2 VERSION

$Header: v:/J80Lusk/CVSROOT/Tools/Bin/plotPerfData.pl,v 1.31 2003/02/14 19:09:14 J80Lusk Exp $
    
=head1 SEE ALSO

L<perl>.
L<perlre>.
    
=head1 TODO

=cut
                                # ' fool emacs
use 5.006;
use strict;
use warnings;
use Carp;
use Getopt::Long;

use Time::localtime;
use FileHandle;
use File::Temp qw/tempfile/;

# ----------------------------------------------------------------------------
#  Globals
# ----------------------------------------------------------------------------

my $GNUPLOT_PREAMBLE = <<_EOF;

# gnuplot preamble

set format x '%H:%M'

# set yrange [0:*]
set ytics nomirror
# set y2range [0:100]
set y2tics
set grid xtics ytics


set xdata time

# preamble ends

_EOF

# ----------------------------------------------------------------

my $LINESTYLES_POSTSCRIPT = <<_EOF;

set linestyle 1 linetype 1 linewidth 4 # red
set linestyle 2 linetype 3 linewidth 4 # blue
set linestyle 3 linetype 2 linewidth 4 # green
set linestyle 4 linetype 4 linewidth 4 # magenta
set linestyle 5 linetype 5 linewidth 4 # cyan
set linestyle 6 linetype 7 linewidth 4 # black
set linestyle 7 linetype 17 linewidth 4 # orange
set linestyle 8 linetype 6 linewidth 4 # yellow

_EOF

                                # Following doesn't seem to work completely
                                # right under windows -- the width value isn't
                                # honored. 
my $LINESTYLES_WINDOWS = <<_EOF;

set linestyle 1 linetype 1 linewidth 2 # red
set linestyle 2 linetype 3 linewidth 2 # blue
set linestyle 3 linetype 2 linewidth 2 # green
set linestyle 4 linetype 4 linewidth 2 # magenta
set linestyle 5 linetype 7 linewidth 2 # cyan
set linestyle 6 linetype 8 linewidth 2 # black
set linestyle 7 linetype 6 linewidth 2 # orange
set linestyle 8 linetype 15 linewidth 2 # yellow

_EOF

# ----------------------------------------------------------------

my $GNUPLOT_POSTAMBLE = <<_EOF;

# gnuplot postamble

                                # Return to defaults
set title
set noy2tics
set format x
set xdata
set yrange [*:*]
set ylabel
set y2label
set y2range [*:*]
set nogrid

# gnuplot postamble ends

_EOF

# ----------------------------------------------------------------

my $gb_year;                    # --year
my $gb_opt_files;               # -f opt
my $gb_fileopt_count = 0;       # How many times we've seen -f.
my $gb_opt_curveSpecs;          # Most-recently specified -y option.
my $gb_curveSpecs_count = 0;    # How many times we've seen -y.
my $gb_opt_axisAffinity = "l";
my $gb_scale = 1.0;
my $gb_opt_curveTitle;
my $gb_opt_linestyle;
my $gb_opt_withstyle;

my $gb_numColumnHeaders;        # The number of column headers found, in
                                #   &findColumns.  
my %gb_xCol;                    # Map from filename to x column.
my %gb_curves;                  # Map from filename to list of columns to
                                # plot.
my $gb_curves;                  # Ref to map: filelists -> curvelists
                                #   -> curveSettingTuples.
                                #   curveSettingTuples have keys
                                #   AXIS_AFFINITY, SCALE, TITLE, LINESTYLE,
                                #   DATAFILES.  

my %gb_linestyleInUse;          # Map from integer linestyle to "in-use"
                                # flag.
my $gb_curLinestyle = 0;

my %gb_order;                   # Use to order filespecs and curvespec in sub
                                #   'byOrder', below.

# ----------------------------------------------------------------------------
#  Functions
# ----------------------------------------------------------------------------

# Store given value as name of current file option.

sub fileOpt
{
    my ($aName, $aValue) = @_;
    
    print "\t$aName => $aValue\n";
    $gb_opt_files = $aValue;
    $gb_order{ $gb_opt_files} = $gb_fileopt_count++;
}

# Store given value as name of x-column for current file.

sub xOpt
{
    my ($aName, $aValue) = @_;
    if (! defined( $gb_opt_files))
    {
        die "-x must be preceded by -f";
    }
    if (defined( $gb_xCol{ $gb_opt_files}))
    {
        die "-x may only be specified once per -f";
    }
    $gb_xCol{ $gb_opt_files} = $aValue;
}

# Remember value for next -y opt.
    
sub axisAffinityLeftOpt
{
    my ($aName, $aValue) = @_;
    $gb_opt_axisAffinity = "l";
}

# Remember value for next -y opt.

sub axisAffinityRightOpt
{
    my ($aName, $aValue) = @_;
    $gb_opt_axisAffinity = "r";
}

# Remember value for next -y opt.

sub scaleOpt
{
    my ($aName, $aValue) = @_;
    if ($aValue)
    {
        $gb_scale = $aValue;
    }
    else
    {
        $gb_scale = 1.0;
    }
}

# Title for next curve(s).

sub curveTitleOpt
{
    my ($aName, $aValue) = @_;
    $gb_opt_curveTitle = $aValue;
}

# GnuPlot line style/type for next curve(s).

sub lineStyleOpt
{
    my ($aName, $aValue) = @_;
    $gb_opt_linestyle = $aValue;
}

# GnuPlot 'with' style.

sub wOpt
{
    my ($aName, $aValue) = @_;
    $gb_opt_withstyle = $aValue;
}

# Store given value as name of y-column for current file.

sub yOpt
{
    my ($aName, $aValue) = @_;
    
    print "\t$aName => $aValue\n";
    if (! defined( $gb_opt_files))
    {
        die "-y must be preceded by -f";
    }
    $gb_opt_curveSpecs = $aValue;
    $gb_order{ $gb_opt_curveSpecs} = $gb_curveSpecs_count++;
    my @curveTitles;
    push( @curveTitles, $gb_opt_curveTitle || split( /,/, $aValue));
    my %curveSettings = ( AXIS_AFFINITY => $gb_opt_axisAffinity,
                          SCALE => $gb_scale,
                          TITLE => \@curveTitles,
                          LINESTYLE => $gb_opt_linestyle || &nextUnusedStyle(),
                          WITHSTYLE => $gb_opt_withstyle
                          );
    $gb_linestyleInUse{ $curveSettings{LINESTYLE}} = 1;
    $gb_curves->{$gb_opt_files}->{$aValue} = \%curveSettings;
}

# Add curve titles to previously-specified curvespecs.

sub asOpt
{
    my ($aName, $aValue) = @_;

    if (! defined( $gb_opt_curveSpecs))
    {
        die "--as must be preceded by -y";
    }
    my @curveTitles;
    push( @curveTitles, $gb_opt_curveTitle || split( /,/, $aValue));
    if (scalar( @curveTitles) !=
        scalar( @{$gb_curves->{$gb_opt_files}->{$gb_opt_curveSpecs}->{TITLE}}))
    {
        die "new title list ($aValue) must have same cardinality as old title list ("
            . join( ",", @{$gb_curves->{$gb_opt_files}->{$gb_opt_curveSpecs}->{TITLE}})
                . ")";
    }
    $gb_curves->{$gb_opt_files}->{$gb_opt_curveSpecs}->{TITLE} = \@curveTitles;
}

# Add "duplicate-skip" count to previously-specified curvespecs

sub dupSkipOpt
{
    my ($aName, $aValue) = @_;

    if (! defined( $gb_opt_curveSpecs))
    {
        die "--dupskip must be preceded by -y";
    }
                                # Let's just assume only one col is specified
                                #   w/-y.
    $gb_curves->{$gb_opt_files}->{$gb_opt_curveSpecs}->{DUP_SKIP} = $aValue;
}

# Returns the next unused gnuplot linestyle.

sub nextUnusedStyle
{
    while ($gb_linestyleInUse{ ++$gb_curLinestyle}) {}
    return $gb_curLinestyle;
}

# Ensure $x has a 4-digit year, if it has a date.  Dates are assumed to be in
# month, day, year order.  If $x contains a date, it is assumed by separated
# from other stuff in $x by whitespace, and it is further assumed that the
# whitespace can be replaced with a single space.
#
# $x is string to be checked for date and fixed, if necessary
# $year is the year to be added, if date doesn't have a year at all.

sub ensureGoodDateFmt
{
    my ($aPossibleDate,
        $aYear
        ) = @_;

    my $me = "&ensureGoodDateFmt: ";
    my $retval;
    my ($prefix, $mmdd, $yy, $suffix);
    my $dateSeparator;
    
    if ($aPossibleDate =~ m{\b\d\d?[-/]\d\d?[-/]\d\d\d\d\b}
        || $aPossibleDate !~ m{\d\d?[-/]\d\d?}
        )
    {
        return $aPossibleDate;  # no fix needed, has 4-digit year or isn't a
                                #   date at all.
    }

    my @components = split( /\s+/, $aPossibleDate);
    my $fixed = "";
    for (my $i = 0; $i < @components; $i++)
    {
        my ($mmdd, $yy, $dateSeparator);
        my $isDate = 0;
                                # Assume mm/dd/yy, not yy/mm/dd.  Can't
                                #   programatically detect the difference.
        if ($components[$i] =~ m{\b(\d\d\d\d)[-/](\d\d?)[-/](\d\d?)\b})
        {
            my ($yyyy, $mm, $dd) = ($1, $2, $3);
            $components[$i] = sprintf( "%02d/%02d/%d", $mm, $dd, $yyyy);
            $fixed = "switched order";
        }
        elsif ($components[$i] =~ m{\b(\d\d?([-/])\d\d?)([-/])?(\d\d)?\b})
        {
            ($mmdd, $dateSeparator, $yy) = ($1, "/", $4);
            $isDate = 1;
        }
#         if ($isDate)
#         {
#             printf( "%s Is date: \"%s\", mmdd=%s dateSeparator=%s yy=%s\n",
#                     $me, $components[$i], $mmdd, $dateSeparator, $yy);
#         }
        if ($isDate && (! defined( $yy)
                        || $yy < 100))
        {
            if (! defined( $yy))
            {
                if (! defined( $aYear))
                {
                    croak "Need year supplied by caller to fix date \"$aPossibleDate\"";
                }
                $yy = $aYear;
            }
            if ($yy <= 50)
            {
                $yy += 2000;
            }
            elsif ($yy < 100)
            {
                $yy += 1900;
            }
            $components[$i] = $mmdd . $dateSeparator . $yy;
            $fixed = "two-digit year";
        }
    }
    if ($fixed)
    {
        $retval = join( " ", @components);
#         printf( "%s Fixed: \"%s\" (%s)\n", $me, $retval, $fixed);
    }
    else
    {
        $retval = $aPossibleDate;
        printf( "%s Not fixed: \"%s\"\n", $me, $aPossibleDate);
    }
    return $retval;
}

# $aFileList is comma-separated list of files to concatenate.
# $anXColSpec is colum containing x-data (date/time values for perf data).
# $aCurveList is comma-separated list of columns to extract (curveSpecs).
#
# Return value is ref. to list of datafile names for each curve.  (Comment
# added long after this was written:  looks like all it does is generate a
# temp. file for each curve, which temp. file contains only x-y tab-delimited
# data (no headers or other crap, like comments).

sub extractCurves
{
    my ($aFileList, $anXColSpec, $aCurveList) = @_;
    my @files = split( /,/, $aFileList);
    my @curveSpecs = split( /,/, $aCurveList);
    my $curveSpec;
    my $fh = FileHandle->new();
    my %plotdata;               # Map from curve spec to [FH, FILENAME,
                                #   OFFSET] tuple. 
    
    foreach $curveSpec (@curveSpecs)
    {
        my @plotdata = tempfile( SUFFIX => ".xy")
            or die "tempfile(): $!";
        $plotdata{ $curveSpec}->{FH}       = $plotdata[0];
        $plotdata{ $curveSpec}->{FILENAME} = $plotdata[1];
        $plotdata{ $curveSpec}->{OFFSET}   = undef;
        $plotdata{ $curveSpec}->{DUP_SKIP} =
            $gb_curves->{$aFileList}->{$curveSpec}->{DUP_SKIP};
    }

    while (@files)
    {
        my $curFile = $files[0];
        $fh->open( "< $curFile")
            or die "open input $curFile: $!";

        my $xCol;           # Offset of x column.

        while( <$fh>)
        {
            chomp;
            s/\r$//;            # Stupid perl implementation (cygwin?) may not
                                # have recognized end-of-line chars.

                                # if x-col is numeric, easy answer.  Else,
                                # scan for column name. 

            my $skip;
            if (! defined( $xCol))
            {
                $skip = &findColumns( $_, $anXColSpec, \$xCol, \%plotdata);
#                 printf( "Column offsets for file \"%s\":\n\t%s\n",
#                         $curFile,
#                         join( "\n\t", map { $_ . " => "
#                                                 . $plotdata{ $_}->{OFFSET} }
#                               (sort keys %plotdata)));
            }
            if ($skip)
            {
                next;           # maybe we didn't find the header, maybe we
                                # found a header line (i.e., not data)
            }
            my @fields = split( /,/, $_);
            if (scalar( @fields) != $gb_numColumnHeaders)
            {
                warn "Number of data fields (" . scalar( @fields)
                    . ") != number of column headers (" . $gb_numColumnHeaders
                    . ") in file $curFile, line # " 
                    . $fh->input_line_number()
                    . ", data line >$_<";
                next;
            }
            my $x = &stripQuotes( $fields[ $xCol]);
            $x = &ensureGoodDateFmt( $x, $gb_year);
            foreach $curveSpec (keys %plotdata)
            {
                my $field = $fields[ $plotdata{ $curveSpec}->{OFFSET}];
                if (defined( $field))
                {
                    my $y = &stripQuotes( $field);
                    my $scale
                        = $gb_curves->{$aFileList}->{$aCurveList}->{SCALE};
                    if (($y !~ m/-?\d+(\.\d*)?/)
                        || ($scale !~ m/-?\d+(\.\d*)?/))
                    {
                        carp "One of \$y, \$scale not numeric;\n\t\$curveSpec = $curveSpec,\n\t\$plotdata{ \$curveSpec}->{OFFSET} = $plotdata{ $curveSpec}->{OFFSET},\n\t\$field = $field,\n\t\$scale = $scale,\n\t\$y = $y\n\t\$_ = $_\n\t";
                    }
                    $y *= $scale;
                    $plotdata{ $curveSpec}->{FH}->printf( "%s\t%s\n", $x, $y);
                }
                else
                {
                    $plotdata{ $curveSpec}->{FH}->printf( "\n");
                    carp( "Field " . $plotdata{ $curveSpec}->{OFFSET}
                          . " undefined in file " . $curFile
                          . " line " . $fh->input_line_number());
                }
            }
        }
        $fh->close();
        shift( @files);
    }

    my @retval;
    
    foreach $curveSpec (@curveSpecs)
    {
        $plotdata{ $curveSpec}->{FH}->close();
        push( @retval, $plotdata{ $curveSpec}->{FILENAME});
    }
    return \@retval;
}

# Given a line of input which might define the columns in a file, set the
# x-column and y-columns (global data).  Also sets the number of column
# headers found, because PerfDataLog sometimes writes more headers than data
# fields (bug, I think).
#
# $anInputLine is a line of input (sans newline) from the input file
# $anXColSpec is the specification of the x column.
# $anXCol is reference to a scalar that will be updated w/the offset of the
#     x-column. 
# $aPlotdataMapRef is a ref. to a map from curve spec to curve data (including
#     OFFSET data member).
# Return value is true if the input line should be skipped (because it
#     contains no data).
sub findColumns
{
    my ($anInputLine, $anXColSpec, $anXCol, $aPlotdataMapRef) = @_;

    my @fields = split( /,/, $anInputLine);
    my $i;
    my $skip;                   # return value
    
    $gb_numColumnHeaders = @fields;
    if ($anXColSpec =~ m/^\d+$/)
    {
        $$anXCol = $anXColSpec; # numeric, no regexp scanning required.
    }
    else
    {
                                # anXColSpec is *name* of x-column.
        my $found = 0;
        for ($i = 0; $i < @fields and ! $found; $i++)
        {
            if ($fields[$i] =~ m/$anXColSpec/)
            {
                $found = 1;
                $$anXCol = $i;
            }
        }
    }
    if (! defined( $$anXCol))
    {
        die "Couldn't find x-column \"$anXColSpec\" in columns "
            . join( ", ", map( "\"$_\"", @fields));
    }
    
                                # TODO: allow numeric x (e.g., count
                                # non-numeric, non-date/time x as header
                                # (non-data)). 

    if (&stripQuotes( $fields[ $$anXCol])
        =~ m|^\d\d?/\d\d?(/\d\d(\d\d)?)?\s+\d\d?:\d\d(:\d\d)?|)
    {
                                # value in x-column looks like real data
                                # (date/time).
        $skip = 0;
    }
    else
    {
        $skip = 1;
    }
    
    my $curveSpec;
    foreach $curveSpec (keys %{$aPlotdataMapRef})
    {
        my ($col, $spec) = split( /=/, $curveSpec);
        if ($col =~ m/^\d+$/)
        {
            $aPlotdataMapRef->{$curveSpec}->{OFFSET} = $col;
        }
        else
        {
            my $found = 0;
            my $colCount = 0;   # Number of occurrences of $col found so far.
            for ($i = 0; $i < @fields and ! $found; $i++)
            {
                if ($fields[$i] =~ m/$col/)
                {
                    if ($aPlotdataMapRef->{$curveSpec}->{DUP_SKIP})
                    {
                        $colCount++;
                        if ($colCount
                            <= $aPlotdataMapRef->{$curveSpec}->{DUP_SKIP})
                        {
                            printf( "Skipping duplicate column \"%s\"\n",
                                    $fields[$i]);
                            next; # Skip duplicate column, don't match so
                                #   eagerly. 
                        }
                    }
                    $aPlotdataMapRef->{$curveSpec}->{OFFSET} = $i;
                    $found = 1;
                }
            }
            if (! $found)
            {
                warn "Column for curve spec. '$curveSpec' not found in\n\t"
                    . join( "\n\t", @fields) . "\n    ";
            }
        }
    }
    return $skip;
}

# Return the given string sans outer double quotes and leading/trailing
# spaces.

sub stripQuotes
{
    my ($s) = @_;
    $s =~ s/^[\" \t]*([^\"]*)[\" \t]*$/$1/;
    return $s;
}

sub byOrder
{
    return $gb_order{ $a} <=> $gb_order{ $b};
}

# Generate gnuplot instruction to plot extracted curves.  Returns name of
# generated gnuplot script.

sub plot
{
    my ( $aDevice,
         $aGTitle,
         $anLMax, $anLLog, $anLTitle,
         $anRMax, $anRLog, $anRTitle,
         $anOutputName,
         $aCurveMap,
         $aTimeFmt) = @_;
    my ($filelist, $curvelist);
    
    my $nXCols = scalar( split( /\s+/, $aTimeFmt));
    my $usingCols = "1:" . ($nXCols + 1);

    print( "Will plot...\n");
    print( "\t(using $usingCols)\n");
    foreach $filelist (sort byOrder keys %$aCurveMap)
    {
        foreach $curvelist (sort byOrder keys %{$aCurveMap->{ $filelist}})
        {
            print( "\t$filelist\t$curvelist\t",
                   join( ", ",
                         map( { my $x = $aCurveMap->{$filelist}->{$curvelist}->{$_};
                                $_ . " => " . (defined( $x) ?
                                               (ref $x eq "ARRAY" ?
                                                ("(" . join( ", ", @$x) . ")")
                                                : $x)
                                               : "(undef)")}
                              keys( %{$aCurveMap->{$filelist}->{$curvelist}}))),
                   "\n");
        }
    }

    my ($fh, $gnuplotScriptName) = tempfile( SUFFIX => ".gnuplot");
    $fh->print( $GNUPLOT_PREAMBLE);
    $fh->print( "set timefmt '$aTimeFmt'\n");
    $fh->print( "set yrange [0:", ($anLMax ? $anLMax : "*"), "]\n");
    $fh->print( "set y2range [0:", ($anRMax ? $anRMax : "*"), "]\n");
    if ($anLLog) {
        $fh->print( "set logscale y\n");
        $fh->print( "set yrange [*:*]\n");
    }
    if ($anRLog) {
        $fh->print( "set logscale y2\n");
        $fh->print( "set y2range [*:*]\n");
    }
    if ($anLTitle) { $fh->print( "set ylabel '$anLTitle'\n");}
    if ($anRTitle) { $fh->print( "set y2label '$anRTitle'\n"); }
    if ($aGTitle) { $fh->print( "set title '$aGTitle'\n"); }
    if ($aDevice =~ m/postscript|gif|png/)
    {
        $fh->print( $LINESTYLES_POSTSCRIPT);
        my @deviceWords = split( ' ', $aDevice);
        my $fileSuffix = ($deviceWords[0] eq "postscript"
                          ? "ps" : $deviceWords[0]);
        if (@deviceWords == 1 and $deviceWords[0] ne "gif")
        {
            $fh->print( "set term $aDevice color\n");
        }
        else
        {
            $fh->print( "set term " . join( " ", @deviceWords) . "\n");
        }
        $fh->print( "set output '$anOutputName.$fileSuffix'\n");
    }
    else
    {
        $fh->print( $LINESTYLES_WINDOWS);
    }
    $fh->print( "plot \\\n");
    my $first = 1;
    my $curveSettings;          # tuple
    my $datafile;
    foreach $filelist (sort byOrder keys %$aCurveMap)
    {
        foreach $curvelist (sort byOrder keys %{$aCurveMap->{$filelist}})
        {
            $curveSettings = $aCurveMap->{$filelist}->{$curvelist};
            my $i = 0;
            foreach $datafile (@{$curveSettings->{DATAFILES}})
            {
                if (! $first) { $fh->print( ", \\\n"); }

                $fh->print( "\t'$datafile' using $usingCols "
                            . " axes "
                            . ($curveSettings->{AXIS_AFFINITY} eq "l"
                               ? "x1y1" : "x1y2")
                            . " title '$curveSettings->{TITLE}->[$i]' "
                            . " with ");
                $fh->print( ($curveSettings->{WITHSTYLE} || "lines") . " ");
                if ($curveSettings->{LINESTYLE})
                {
                    $fh->print( " linestyle $curveSettings->{LINESTYLE} ");
                }
                $first = 0;
                $i++;
                if ($i >= @{$curveSettings->{TITLE}})
                {
                    $i = @{$curveSettings->{TITLE}} - 1;
                }
            }
        }
    }
    $fh->print( "\n");
    if ($aDevice =~ m/postscript|gif|png/)
    {
        $fh->print( "set output\n");
        $fh->print( "set term windows\n");
    }
    else
    {                           # Assume 'windows'.
        $fh->print( "pause -1 'Press Ok or Cancel to continue...'\n");
    }
    $fh->print( $GNUPLOT_POSTAMBLE);
    $fh->close();
    print( "Final script is '$gnuplotScriptName'\n");
    return $gnuplotScriptName;
}

# ----------------------------------------------------------------------------
#  Main
# ----------------------------------------------------------------------------

my ($opt_device,
    $opt_gtitle,
    $opt_lmax,
    $opt_rmax,
    $opt_ltitle,
    $opt_rtitle,
    $opt_llog,
    $opt_rlog,
    $opt_timefmt,
    $opt_o,                     # output file, -o
    $opt_gnuplotCmd
    );

$opt_device = "windows";
$opt_gnuplotCmd = "C:/usr/local/gp371w32/wgnupl32.exe";

GetOptions( "dev=s"        => \$opt_device,
            "gtitle=s"     => \$opt_gtitle,
            "lmax=s"       => \$opt_lmax,
            "llog!"        => \$opt_llog,
            "ltitle=s"     => \$opt_ltitle,
            "rmax=s"       => \$opt_rmax,
            "rlog!"        => \$opt_rlog,
            "rtitle=s"     => \$opt_rtitle,
            "o=s"          => \$opt_o,
            "gnuplotCmd:s" => \$opt_gnuplotCmd,
            "year=s"       => \$gb_year,
            "f=s"          => \&fileOpt,
            "x=s"          => \&xOpt,
            "timefmt=s"    => \$opt_timefmt,
            "l"            => \&axisAffinityLeftOpt,
            "r"            => \&axisAffinityRightOpt,
            "s:f"          => \&scaleOpt,
            "t:s"          => \&curveTitleOpt,
            "ls:s"         => \&lineStyleOpt,
            "y=s"          => \&yOpt,
            "w=s"          => \&wOpt,
            "as=s"         => \&asOpt,
            "dupskip=i"    => \&dupSkipOpt
            )
    or die $!;

if (! $gb_year)
{
    $gb_year = localtime->year() + 1900;
}
if (! $opt_o)
{
    $opt_o = "gnuplot";
}
if (! $opt_timefmt)
{
    $opt_timefmt = "%m/%d/%Y %H:%M:%S";
}

if (! ($opt_device =~ m/postscript|windows|gif|png/))
{
    warn "Unexpected --dev ($opt_device)";
    system( "pod2text $0");
    exit 1;
}

foreach my $file (keys %$gb_curves)
{
    print( "For $file, will plot columns:\n");
    foreach my $curve (keys %{$gb_curves->{ $file}})
    {
        print( "\t$curve\n");
    }
}

foreach my $filelist (keys %$gb_curves)
{
    foreach my $curvelist (keys %{$gb_curves->{ $filelist}})
    {
        $gb_curves->{$filelist}->{$curvelist}->{DATAFILES} 
        = &extractCurves( $filelist,
                          $gb_xCol{ $filelist},
                          $curvelist);
    }
}

my $plotScript = &plot( $opt_device,
                        $opt_gtitle,
                        $opt_lmax,
                        $opt_llog,
                        $opt_ltitle,
                        $opt_rmax,
                        $opt_rlog,
                        $opt_rtitle,
                        $opt_o,
                        $gb_curves,
                        $opt_timefmt);

if ($opt_gnuplotCmd)
{
    my $rc = system( $opt_gnuplotCmd, $plotScript);
    if ($rc > 0)
    {
        $rc /= 256;
        carp "$opt_gnuplotCmd exit code = $rc";
    }
    elsif ($rc < 0)
    {
        carp "Failed to start $opt_gnuplotCmd: $!";
    }
}    

# ----------------------------------------------------------------------------
#  END
# ----------------------------------------------------------------------------

1;
__END__


# $Log: plotPerfData.pl,v $
# Revision 1.31  2003/02/14 19:09:14  J80Lusk
# *** empty log message ***
#
# Revision 1.30  2002/11/22 19:13:59  J80Lusk
# Better diagnostics.
#
# Revision 1.29  2002/10/10 21:43:38  J80Lusk
# Docs for recent options (--as, --dupskip).
#
# Revision 1.28  2002/10/10 21:41:49  J80Lusk
# Add --dupskip option.
#
# Revision 1.27  2002/10/10 20:46:40  J80Lusk
# Logarithmic axes.
# More tolerant of header/data column count mismatch (skips line).
#
# Revision 1.26  2002/09/25 01:52:27  J80Lusk
# Plot curves in same order that they were entered on the command line.
#
# Revision 1.25  2002/09/25 00:54:14  J80Lusk
# Add -w (gnuplot-with-stle) option.
#
# Revision 1.24  2002/08/30 17:49:17  J80Lusk
# Remove debugging verbosity.
#
# Revision 1.23  2002/08/30 17:45:47  J80Lusk
# Expanded intelligence of ensureGoodDateFmt() (renamed from
# ensure4DigitYear()).
#
# Revision 1.22  2002/08/29 23:00:54  J80Lusk
# Added &ensure4DigitYear.
#
# Revision 1.21  2002/08/29 22:03:34  J80Lusk
# Add -o (output) option.
#
# Revision 1.20  2002/08/23 16:43:40  J80Lusk
# Better diagnostics for error "Number of data fields != number of
# column headers"
#
# Revision 1.19  2002/08/23 15:20:30  J80Lusk
# Much noise on non-numeric data from input file.
#
# Revision 1.18  2002/08/21 20:52:19  J80Lusk
# Add "-as" option.
#
# Revision 1.17  2002/08/21 17:45:21  J80Lusk
# Add --timefmt option.
#
# Revision 1.16  2002/02/20 23:28:33  J80Lusk
# Add error-checking for invalid x-column regexp.
#
# Revision 1.15  2001/12/07 18:10:47  J80Lusk
# *** empty log message ***
#
# Revision 1.14  2001/11/07 21:55:34  J80Lusk
# Better quote-stripping.
# Better handling of missing data points (missing fields).
#
# Revision 1.13  2001/11/07 21:18:09  J80Lusk
# Minor bug fixes.
#
# Revision 1.12  2001/11/07 20:07:34  J80Lusk
# More online help.
#
# Revision 1.11  2001/10/18 18:18:21  J80Lusk
# "year" global for mm/dd dates.
# "scale" option for data that doesn't fit on either axis
# more-flexible device "naming"
#
# Revision 1.10  2001/09/27 16:42:37  J80Lusk
# Doc updates.
#
# Revision 1.9  2001/09/27 16:34:40  J80Lusk
# Doc changes, "Ok to continue" for windows terminals.
#
# Revision 1.8  2001/09/27 15:36:54  J80Lusk
# gif, png output
#
# Revision 1.7  2001/09/27 15:19:00  J80Lusk
# gnuplot postamble
#
# Revision 1.6  2001/09/27 14:46:54  J80Lusk
# cygwin line-ending hack.
# make some option values optional (curve title, linestyle)
#
# Revision 1.5  2001/09/27 13:59:29  J80Lusk
# Add ability to print to postscript or windows.
# Add linestyles for each, based on default .ini file.
#
# Revision 1.4  2001/09/27 00:07:20  J80Lusk
# Bugs worked out.  Now I just need to be able to make it write
# postscript output and print automatically.
#
# Revision 1.3  2001/09/26 23:46:22  J80Lusk
# Moderately improved in flexibility.  Not quite right, though.
#
# Revision 1.2  2001/09/25 04:02:48  J80Lusk
# *** empty log message ***
#
# Revision 1.1  2001/09/25 03:10:00  J80Lusk
# *** empty log message ***
#
