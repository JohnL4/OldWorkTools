#!/perl/bin/perl -w
                                # -*- coding: raw-text-dos -*-

=head1 NAME

buckets.pl -- Distribute numeric data into buckets for plotting

=head1 SYNOPSIS

 buckets.pl [-c <columnNumber>]
    [-n <bucketCount> | -w <bucketWidth>] [<filename>...]

=head1 DESCRIPTION

Drop each datapoint into one of n buckets.  At EOF, print the size of each
bucket. 

=head2 OPTIONS

=item -c I<columnNumber>

The number of the column (1-based) containing the data whose distribution you
want to see.  Default: 1.

=item -n I<bucketCount>

The number of buckets you want to distribute your data into.  Default: 5.  You
cannot specify both -n and -w.

=item -w I<bucketWidth>

The width of each bucket.  Default:  determined by -n.  You cannot specify
both -n and -w.

=head1 AUTHOR

john.lusk@canopysystems.com

=head2 VERSION

$Header: v:/J80Lusk/CVSROOT/Tools/Bin/buckets.pl,v 1.5 2002/03/12 18:46:54 J80Lusk Exp $
    
=head1 SEE ALSO

L<perl>.

=head1 TODO

=cut

use 5.006;
use strict;
use warnings;
use Carp;
use Getopt::Long;
use File::Basename;

# ----------------------------------------------------------------------------
#  Globals
# ----------------------------------------------------------------------------

my $myname = basename( $0);

# ----------------------------------------------------------------------------
#  Static Methods
# ----------------------------------------------------------------------------

# Dump bucket sizes to stdout.
#
# $data -- Ref to list of numeric data values.
# $aNBuckets -- The number of buckets to distribute the data across.  May be
#     undef, in which case $aBucketWidth will be used.
# $aBucketWidth -- The width of each bucket, if $aNBuckets is undef. 
# $filename -- The name of the file the data came from.

sub dumpBucketSizes
{
    my ($data, $aNBuckets, $aBucketWidth, $filename) = @_;

                                # Special cases: 0 or 1 data point.
    if (@$data == 0)
    {
        warn "NO DATAPOINTS";
        return;
    }
    elsif (@$data == 1)
    {
        printf( "%g\t%g\n", $data->[0], 1);
        return;
    }
                                # End special cases.
    
    my @buckets;

    my $minDataValue = $data->[ 0];
    my $maxDataValue = $data->[ 0];
    map( { ($_ < $minDataValue) and ($minDataValue = $_);
           ($_ > $maxDataValue) and ($maxDataValue = $_); }
         @$data);

    my ($nBuckets, $bucketWidth);
    if (defined( $aNBuckets))
    {
        $bucketWidth = ($maxDataValue - $minDataValue) / $aNBuckets;
        $nBuckets = $aNBuckets;
    }
    else
    {
        $bucketWidth = $aBucketWidth;
        $nBuckets = ($maxDataValue - $minDataValue) / $aBucketWidth;
    }
    if ($nBuckets < 1)
    {
        $nBuckets = 1;
    }
    map( { $buckets[$_] = 0; } 0..$nBuckets-1);
    my $nDataPts = @$data;

    my $i;
    map( { if ($bucketWidth != 0)
           {
               $i = int( ($_ - $minDataValue) / $bucketWidth);

                                # If data point is exactly maxValue, $i will
                                # be one bucket off the end of the array.
               ($i >= $nBuckets) and ($i = $nBuckets - 1);
           }
           else
           {
               $i = 0;
           }
           $buckets[ $i]++; }
         @$data);
    
    printf( "\t\t# %s xrange=[%g:%g]\n", $filename,
            $minDataValue, $maxDataValue);
    for ($i = 0; $i < $nBuckets; $i++)
    {
                                # x: center of interval;
                                # y: count of data points in interval
        printf( "%g\t%g\n",
                $minDataValue + ($i + 0.5) * $bucketWidth, $buckets[$i]);
    }
}

# Returns count and value that are closest to the 90th percentile.
#
# $n -- Total # of datapoints.
# $countA -- # of datapoints having value <= $valueA
# $valueA
# $countB -- # of datapoints having value <= $valueB
# $valueB
#
# Return two-element list:  percentile closest to 90th and value corresponding
# to that percentile.

sub closestTo90thPercentile
{
    my ($n, $countA, $valueA, $countB, $valueB) = @_;
    
    my ($percentile, $pctileValue); # return values
    my $valueAPctile = $countA/$n;
    my $valueBPctile = $countB/$n;
    if (abs( $valueAPctile - 0.90) < abs( $valueBPctile - 0.90))
    {
        $percentile = $valueAPctile;
        $pctileValue = $valueA;
    }
    else
    {
        $percentile = $valueBPctile;
        $pctileValue = $valueB;
    }
    return ($percentile, $pctileValue);
}

# Dump values from @$data and number of datapoints that have that value or
# lower.
#
# $data -- Ref to list of numeric data values.
# $filename -- The name of the file the data came from.

sub dumpCumulativeCounts
{
    my ($data, $filename) = @_;
    my $n = @$data;
    my $n90 = 0.9 * $n;
    my $printedCeiling90 = 0;
    my @sortedData = sort( { $a <=> $b } @$data);

    printf( "\t\t# %s n = %g\n", $filename, $n);
    my $count = 0;
    my $curValue = $sortedData[0];
    my ($oldCount, $oldValue) = (0, 0);
    foreach my $datum (@sortedData)
    {
        if ($datum != $curValue)
        {
            printf( "%g\t%g\n", $curValue, $count);
            if (! $printedCeiling90 and $count >= $n90)
            {
                my ($percentile, $pctileValue)
                    = &closestTo90thPercentile( $n, $oldCount, $oldValue,
                                                $count, $curValue);
                printf( "\t\t# %d%% <= %g\n",
                        (100 * $percentile + 0.5),
                        $pctileValue);
                $printedCeiling90 = 1;
            }
            $oldCount = $count;
            $oldValue = $curValue;
            $curValue = $datum;
        }
        $count++;
    }
    printf( "%g\t%g\n", $curValue, $count);
    if (! $printedCeiling90)
    {
        my ($percentile, $pctileValue)
            = &closestTo90thPercentile( $n, $oldCount, $oldValue,
                                        $count, $curValue);
        printf( "\t\t# %d%% <= %g\n",
                (100 * $percentile + 0.5),
                $pctileValue);
    }
}

# ----------------------------------------------------------------------------
#  Main
# ----------------------------------------------------------------------------

my $opt_c = 1;
my $opt_n;
my $opt_w;

GetOptions( "c=i" => \$opt_c,
            "n=i" => \$opt_n,
            "w=f" => \$opt_w)
    or die $!;

if (defined( $opt_n) and defined( $opt_w))
{
    die "Can't specify both -n and -w";
}
elsif (! defined( $opt_n) and ! defined( $opt_w))
{
    $opt_n = 5;
}


my $prevFilename;
my @fields;
my @data;

while (<>)
{
    chomp;
    s/\r//;
    (! $prevFilename) && ($prevFilename = $ARGV);
    ($prevFilename ne $ARGV) && do
    {
        &dumpBucketSizes( \@data, $opt_n, $opt_w, $prevFilename);
        print( "\n\n");         # two blanks ==> new index (new dataset in
                                #   same file).
        &dumpCumulativeCounts( \@data, $prevFilename);
        print( "\n\n");         # two blanks ==> new index (new dataset in
                                #   same file).
        undef @data;
        $prevFilename = $ARGV;
    };
    @fields = split( " ", $_);
    push( @data, $fields[ $opt_c - 1]);
}
&dumpBucketSizes( \@data, $opt_n, $opt_w, $prevFilename);
print( "\n\n");                 # two blanks ==> new index (new dataset in
                                #   same file).
&dumpCumulativeCounts( \@data, $prevFilename);
# ----------------------------------------------------------------------------
#  END
# ----------------------------------------------------------------------------

1;
__END__

=pod

=cut

# $Log: buckets.pl,v $
# Revision 1.5  2002/03/12 18:46:54  J80Lusk
# Add and use &closestTo90thPercentile().
#
# Revision 1.4  2001/12/15 20:15:09  J80Lusk
# Print 90th percentile (or as close to it as we can get) as gnuplot
# comment in output.
#
# Revision 1.3  2001/12/13 21:30:52  J80Lusk
# Add cumulative count dump.
#
# Revision 1.2  2001/12/13 18:20:32  J80Lusk
# Special cases of 0 or 1 datapoints.
#
# Revision 1.1  2001/12/11 17:00:29  J80Lusk
# Initial version.
