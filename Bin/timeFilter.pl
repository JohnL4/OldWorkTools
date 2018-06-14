#!/usr/bin/perl -w
                                # -*- coding: raw-text-dos -*-


=head1 NAME

timeFilter.pl -- Filter out text records not in a given time interval

=head1 SYNOPSIS

    timeFilter.pl -b <time> -e <time> [-y <year>]

=head1 DESCRIPTION

Filter records from a text log of some sort such that only records with a
given time interval are passed through.  The column containing the timestamps
is identified by <columnId>, either a regexp or a nonnegative integer.  The
column delimiter is assumed to be whitespace (space, tab), but may be
specified as any perl regular expression.

Times are expected to be in either IIS format (YYYY-MM-DD HH:MM:SS) or
PerfDataLog format (MM/DD/YYYY HH:MM:SS) or JRun format (MM/DD HH:MM:SS).  If
JRun format is used, you must also supply the year separately (since it's not
part of the JRun log info).
    
=head1 AUTHOR

john.lusk@canopysystems.com

=head2 VERSION

$Header: v:/J80Lusk/CVSROOT/Tools/Bin/timeFilter.pl,v 1.3 2001/12/07 18:10:47 J80Lusk Exp $
    
=head1 SEE ALSO

L<perl>.

=head1 TODO

=cut
                                # ') emacs font-lock
    
use 5.006;
use strict;
use warnings;
use Carp;
use Getopt::Long;

use POSIX;

# ----------------------------------------------------------------------------
#  Globals
# ----------------------------------------------------------------------------

my $gb_year;                    # 4-digit year, given by user.

# ----------------------------------------------------------------------------
#  Static Methods
# ----------------------------------------------------------------------------

# Attempt to find a timestamp in the given string.  If found, convert to
# POSIX::mktime and return that value.  Else return undef.

sub matchTime
{
    my ($s) = @_;
    # IIS:  YYYY-MM-DD HH:MM:SS
    if ($s =~ m/(\d\d(\d\d)?)-(\d\d?)-(\d\d?) (\d\d?):(\d\d)(:(\d\d))?/)
    {
        return POSIX::mktime( $8 ? $8 : 0, # sec
                              $6, # min
                              $5, # hrs
                              $4, # mday
                              $3 - 1, # mon
                              ($2 ? $1 - 1900 : $1)); # yr
    }
    # PerfLog:  MM/DD/YYYY HH:MM:SS.sss
    if ($s =~ m|(\d\d)/(\d\d?)/(\d\d(\d\d)?) (\d\d?):(\d\d)(:(\d\d))?|)
    {
        return POSIX::mktime( $8 ? $8 : 0, # sec
                              $6, # min
                              $5, # hrs
                              $2, # mday
                              $1 - 1, # mon
                              ($4 ? $3 - 1900 : $3)); # yr
    }
    # JRun metrics:  MM/DD HH:MM:SS
    if ($s =~ m|^(\d\d?)/(\d\d) (\d\d?):(\d\d)(:(\d\d))?|)
    {
        if (! defined( $gb_year))
        {
            die "JRun date found, but no year given on cmd line ($s)";
        }
        return POSIX::mktime( $6 ? $6 : 0, # sec
                              $4, # min
                              $3, # hrs
                              $2, # mday
                              $1 - 1, # mon
                              $gb_year - 1900);
    }
    return undef;
}

# ----------------------------------------------------------------------------
#  Main
# ----------------------------------------------------------------------------

my ($opt_beginTime, $opt_endTime, $opt_year);
my $badOptions = 0;

GetOptions( "b=s" => \$opt_beginTime,
            "e=s" => \$opt_endTime,
            "y=i" => \$opt_year)
    or die $!;

if (! $opt_beginTime && ! $opt_endTime)
{
    warn "Must specify at least one of begin-time or end-time";
    $badOptions = 1;
}

if ($opt_year)
{
    if ($opt_year < 1900)
    {
        $gb_year = 1900 + $opt_year;
    }
    else
    {
        $gb_year = $opt_year;
    }
}

my ($beginTime, $endTime);

$opt_beginTime && do
{
                                # m/d/y hh:mm
    $beginTime = &matchTime( $opt_beginTime);
    if (! defined( $beginTime))
    {
        warn "Invalid begin-time ($opt_beginTime)";
        $badOptions = 1;
    }
};

$opt_endTime && do
{
                                # m/d/y hh:mm
    $endTime = &matchTime( $opt_endTime);
    if (! defined( $endTime))
    {
        warn "Invalid end-time ($opt_endTime)";
        $badOptions = 1;
    }
};

if ($badOptions)
{
    die;
}

my $recTime;                    # record time
my $timeColNum;                 # 1-based

while (<>)
{
    chomp;
    s/\r//;
    
    $recTime = &matchTime( $_);
    (! defined( $recTime))
        && (printf( "%s\n", $_), next); # Couldn't find timestamp, must be
                                        # metadata, print.
    
    $beginTime && ($recTime < $beginTime) && next;
    $endTime && ($recTime > $endTime) && last;
    printf( "%s\n", $_);
}

# ----------------------------------------------------------------------------
#  END
# ----------------------------------------------------------------------------

__END__


# $Log: timeFilter.pl,v $
# Revision 1.3  2001/12/07 18:10:47  J80Lusk
# *** empty log message ***
#
# Revision 1.2  2001/11/15 18:45:02  J80Lusk
# Add year option for JRun dates, which don't have years.
#
# Revision 1.1  2001/11/10 22:51:13  J80Lusk
# Initial version.
