#!/usr/bin/perl -w

=head1 NAME

timecards.pl -- Process task time data into timecards for Solomon

=head1 SYNOPSIS

  timecards.pl --codes I<timecode-mapping> [I<time-data-file>]

=head1 DESCRIPTION

=head2 OPTIONS

=over
    
=item --codes

Specifies file mapping task identifiers to Solomon timecodes.  Format of file
is space-delimited, one mapping per line, first field is timecode, rest of
line is perl regular expression to match line from raw input data (task names
or comments).

=back
    
=head2 USAGE

Run 'psprpt.pl --oneLine' to generate data.
The process with 'timecards.pl --codes ~/timecodes.txt I<psprpt-output>'.

=head1 AUTHOR

john.lusk@allscripts.com

=head2 VERSION

$Header: v:/J80Lusk/CVSROOT/Tools/perl-template.pm,v 1.5 2001/08/28 16:21:27 J80Lusk Exp $
    
=head1 SEE ALSO

L<perl>.

=head1 TODO


=cut

BEGIN { push( @INC, "/usr/local/lib/perl"); }

use 5.006;
use strict;
use warnings;
use Carp;
use Getopt::Long;

use Time::Local;

use MatchRE ':all';

# ----------------------------------------------------------------------------
#  Globals
# ----------------------------------------------------------------------------

my @mynames = split( /[\/\\]/, $0);
my $myname = pop( @mynames);

# ----------------------------------------------------------------------------
#  Static Methods
# ----------------------------------------------------------------------------

# Returns Saturday on or before given date, as seconds since epoch.  Given
# date is also seconds since epoch.

sub previousSaturday
{
    my ($aDate
        ) = @_;

                                # wday -- 0 is Sunday.
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)
        = localtime( $aDate);
                                # 6 is Saturday
                                # 6 ? 0 --> 1
                                # 6 ? 1 --> 2
                                # 6 ? 2 --> 3
                                # 6 ? 3 --> 4
                                # 6 ? 4 --> 5
                                # 6 ? 5 --> 6
                                # 6 ? 6 --> 0
                                # What delta do we need to get back to the
                                #   previous Saturday?
    my $dayDelta = ($wday + 7 - 6) % 7;
    return $aDate - $dayDelta * 24 * 60 * 60;
}

# ----------------------------------------------------------------------------
#  Main
# ----------------------------------------------------------------------------

my ($opt_codes,
    @res
);

GetOptions( "codes=s" => \$opt_codes,
)
    or die $!;

if ( ! $opt_codes)
{
    printf( STDERR "$myname: --codes is required\n");
    exit 1;
}

@res = MatchRE::slurpREs( $opt_codes);

my %solTask;                    # Solomon task, key is task code.  For
                                #   indicated sub-hash, key is date.
my ($minTime, $maxTime);        # Earliest, latest dates in data.

while (<>)
{
    chomp;
    s/\r//;
    my ($taskDate, $taskHours, $taskTags, $taskComments) = split( /\t/, $_);
    my $tagsAndComments = $taskTags . "\t" . $taskComments;
    my $matchKey = MatchRE::matchKey( $tagsAndComments, \@res);
    if ($matchKey)
    {
        if ( ! $solTask{ $matchKey})
        {
            $solTask{ $matchKey} = ();
        }
        $solTask{ $matchKey}->{ $taskDate} += $taskHours;

                                # Find earliest date
        my ($yyyy, $mm, $dd) = split( /\//, $taskDate);
        my $tm = timelocal( 0, 0, 0, $dd, ($mm - 1), $yyyy);
        if ( ! defined( $minTime) || $tm < $minTime)
        {
            $minTime = $tm;
        }
        if ( ! defined( $maxTime) || $tm > $maxTime)
        {
            $maxTime = $tm;
        }
    }
    else
    {
        printf( STDERR "%s: unmatched: %s\n", $myname, $tagsAndComments);
    }
}

my $saturday = &previousSaturday( $minTime);

my (@dayNames) = ("Sat", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri");

do {
                                # Headers
    printf( " " x 10);
    foreach my $dayName (@dayNames)
    {
        printf( "\t%5s", $dayName);
    }
    printf( "\n");
    printf( " " x 10);
    for (my $wkday = 0; $wkday < 7; $wkday++)
    {
        my $day = $saturday + $wkday * 24 * 60 * 60;
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)
            = localtime( $day);
        my $taskMonthDay = sprintf( "%d/%d", $mon + 1, $mday);
        printf( "\t%5s", $taskMonthDay);
    }
    printf( "\n\n");

                                # Detail data
    foreach my $solTask (sort keys %solTask)
    {
        if ($solTask eq ("0" x 10))
        {
            next;               # Skip special tasks (lunch, personal).
        }
        printf( "%10s", $solTask);
        for (my $wkday = 0; $wkday < 7; $wkday++)
        {
            my $day = $saturday + $wkday * 24 * 60 * 60;
            my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)
                = localtime( $day);
            my $taskDt = sprintf( "%04d/%02d/%02d",
                                  $year + 1900, $mon + 1, $mday);
            if ( ! defined( $solTask{ $solTask}->{ $taskDt})
                 || $solTask{ $solTask}->{ $taskDt} == 0)
            {
                printf( "\t%5s", "-");
            }
            else
            {
                printf( "\t%5.1f", $solTask{ $solTask}->{ $taskDt});
            }
        }
        printf( "\n");
    }
    printf( "\n");
    $saturday += 7 * 24 * 60 * 60;
} until ($saturday > $maxTime);

# ----------------------------------------------------------------------------
#  END
# ----------------------------------------------------------------------------

1;
__END__

=pod


=cut

# $Log: perl-template.pm,v $
# Revision 1.5  2001/08/28 16:21:27  J80Lusk
# Add emacs coding: mode line.
#
# Revision 1.4  2001/08/22 15:53:44  J80Lusk
# Add #! line.
#
# Revision 1.3  2001/08/22 15:22:17  J80Lusk
# *** empty log message ***
#
