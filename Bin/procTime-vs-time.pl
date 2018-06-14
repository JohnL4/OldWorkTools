#!/perl/bin/perl -w
                                # -*- coding: raw-text-dos -*-

=head1 NAME

procTime-vs-time.pl -- processing time per transaction and time interval

=head1 SYNOPSIS

    procTime-vs-time.pl -g <granularity> [-d <outputDir>] [<iisLog>]

    mkdir procTimes
    procTime-vs-time.pl -g 3 iis.log

=head1 DESCRIPTION

Dumps out processing time for each screen (url stem) averaged over intervals
of the specified granularity (in minutes).  For each url, a separate file is
written containing x-y data (processing time vs. wall clock time).

=head1 AUTHOR

john.lusk@canopysystems.com

=head2 VERSION

$Header: v:/J80Lusk/CVSROOT/Tools/Bin/procTime-vs-time.pl,v 1.1 2001/11/09 19:27:23 J80Lusk Exp $
    
=head1 SEE ALSO

L<perl>.

=head1 TODO

=cut

use 5.006;
use strict;
use warnings;
use Carp;
use Getopt::Long;

use FileHandle;
use File::Basename;

use WebServer::Log::Entry;

# Preloaded methods go here.

# ----------------------------------------------------------------------------
#  Globals
# ----------------------------------------------------------------------------

my $DEFAULT_OUTPUT_DIR = ".";
my $DEFAULT_GRANULARITY = 3;    # minutes

my $gb_opt_outputDir   = $DEFAULT_OUTPUT_DIR;
my $gb_bucketStartTime;         # The beginning of the time interval for which
                                #   bucket data is currently being gathered.

my %gb_procTime;                # Processing time for each bucket
my %gb_count;                   # Count of items in each bucket (for
                                #   averaging).
my %gb_fh;                      # Filehandle for each bucket.

# ----------------------------------------------------------------------------
#  Static Methods
# ----------------------------------------------------------------------------

# Increment the appropriate bucket with the entry's processing time; also
# increment the count of data points in that bucket.

sub incrBucket
{
    my( $anEntry) = @_;

    $gb_procTime{ $anEntry->getUriStem()} += $anEntry->getProcessingTime();
    $gb_count{ $anEntry->getUriStem()}++;
}

# Dump all bucket processing-time averages to the file opened for each bucket.

sub dumpBuckets
{
    foreach my $uri (keys %gb_procTime)
    {
        if (! $gb_fh{ $uri})
        {
            $gb_fh{ $uri} = FileHandle->new();
            my $dir = "$gb_opt_outputDir/" . dirname( $uri);
            if (! -e $dir)
            {
                my @dirs = split( /[\/\\]/, $dir);
                $dir = "";
                foreach my $d (@dirs)
                {
                    $dir .= ($dir ? "/" : "") . $d;
                    if (! -e $dir)
                    {
                        mkdir( "$dir")
                            || die "mkdir( $dir): $!";
                    }
                }
            }
            $gb_fh{ $uri}->open( "> $gb_opt_outputDir/$uri.dat")
                || warn "open( $gb_opt_outputDir/$uri.dat): $!";
        }
        if ($gb_count{ $uri} != 0)
        {
            $gb_fh{ $uri}->
                printf( "%s\t%g\n",
                      POSIX::strftime( "%m/%d/%Y %H:%M",
                                       localtime( $gb_bucketStartTime)),
                        $gb_procTime{ $uri} / $gb_count{ $uri});
        }
    }
}

# Reset bucket statistical data for data-gathering over another time
# interval.

sub resetBuckets
{
    foreach my $uri (keys %gb_procTime)
    {
        $gb_procTime{ $uri} = 0;
        $gb_count{ $uri}    = 0;
    }
}

# Close all bucket file handles (flushing final output).

sub closeBuckets
{
    foreach my $uri (keys %gb_procTime)
    {
        $gb_fh{ $uri}->close();
    }
}

# ----------------------------------------------------------------------------
#  Main
# ----------------------------------------------------------------------------

my $opt_granularity = $DEFAULT_GRANULARITY;

GetOptions( "g=s" => \$opt_granularity,
            "d=s" => \$gb_opt_outputDir)
    or die $!;

my $iisLogName = "-";
if (@ARGV)
{
    $iisLogName = shift @ARGV;
}

my $fh = FileHandle->new();
$fh->open( "< $iisLogName") || die "open( $iisLogName): $!";

if (! -e $gb_opt_outputDir)
{
    mkdir( $gb_opt_outputDir) || die "mkdir( $gb_opt_outputDir): $!";
}

my $logStartTime;

my $granularitySec = 60 * $opt_granularity;

while (<$fh>)
{
    print ".";
    chomp;
    s/\r$//;                    # Stupid perl implementation (cygwin?) may not
                                # have recognized end-of-line chars.
    
    /^\#Fields:/ && WebServer::Log::Entry->setFieldNames( $_);
    /^\#/ && next;              # comments
    /^\s*$/ && next;            # blank lines

    my $entry = WebServer::Log::Entry->new( $_);

    if (! $logStartTime)
    {
        $logStartTime = $entry->getInternalTime();
        $gb_bucketStartTime = $logStartTime;
    }

    if (POSIX::difftime( $entry->getInternalTime(), $gb_bucketStartTime)
        >= $granularitySec)
    {
        &dumpBuckets();
        &resetBuckets();
        $gb_bucketStartTime += $granularitySec; # NOT $entry->getInternalTime()
    }

    &incrBucket( $entry);
}
print "\n";
$fh->close();
&dumpBuckets();
&closeBuckets();

exit;

# ----------------------------------------------------------------------------
#  END
# ----------------------------------------------------------------------------

__END__

=pod

=cut

# $Log: procTime-vs-time.pl,v $
# Revision 1.1  2001/11/09 19:27:23  J80Lusk
# Initial version
#
