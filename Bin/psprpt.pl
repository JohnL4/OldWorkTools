#!/usr/bin/perl -w

# $Header: v:/J80Lusk/CVSROOT/Tools/Bin/psprpt.pl,v 1.3 2005/03/28 18:38:04 j6l Exp $

use Carp;
use POSIX qw( mktime);
use Getopt::Long;
use strict;

my $myname = $0;
my @eventStack;
my %entryTime;                  # Time for each entry
my %entryComment;               # Comment for each entry
my %oneDayEntryTime;            # Time for each entry on a single day 
                                #   (reset for each new day).
my %dayTime;                    # Time for each day.  Entries marked
                                #   "dontCount" will not be included
                                #   in this total.

my $DEBUG = 0;

my $accumComments = 0;          # Specifies whether to reset comment
                                #   history w/each new day.
my $oneLine = 0;                # Specifies that each activity record
                                #   is to be dumped on a single,
                                #   tab-delimited line.
my $dontCount = 0;              # Name of file containing list of
                                #   words (classification tags) not to
                                #   count toward daily time total.
my %dontCount;                  # Hash of classification tags not to
                                #   add to daily time total.

my $treatPhaseAsSubtask = 1;    # Consider phase (rs, ds, cd, etc.) to be the
                                # first subtask of the given task.

sub help
{
    my $help;

    $help = <<"END_HELP";
Usage: $0 [--accumComments] [--oneLine] [--dontCount <fileName>]	\\
	[--[no]phaseAsSubtask]						\\
	<journal> [<entry_breakdown> [<day_breakdown>]]

   where

       	--accumComments indicates that you want all comments for a
                 	particular task to be accumulated over the
                 	days in which that task appears, rather than
                 	have the comment "history" reset with each new
                 	day (which is the default).

 	--oneLine	indicates that you want each entry dumped onto
            		a single line with the fields date, hours,
            		tags and comments all tab-delimited, suitable
            		for parsing into a spreadsheet or database.
                            
	--dontCount <fileName> Specifies a file containing a list of
            		top-level classification tags not to count
            		toward the daily time total.  (e.g., lunch,
            		personal errands).

	--[no]phaseAsSubtask Specifies whether or not to treat the phase (rs,
			ds, cd, pm, etc.) as the first subtask of a task.
			Default is TRUE.

	<journal>	is the journal file you want parsed

	<entry_breakdown> is the output file that will contain the total time 
			spent on each entry, modulo interrupts

	<day_breakdown>	is the time spent working each day.

   If the breakdown arguments are not given, their corresponding files
   will not be written.

   Consider post-processing as follows:

      cat 2005-03-10.entries.txt | sort -k2,2 -k1,1gr | sed -e'1i\\
\\tTime\\tTask\\tPhase\\tSubtask\\tSubsubtask' \\
         > 2005-03-10.entries.sorted,withHdrs.txt

   Consider also using summatch.pl with ~/timecodes.txt

END_HELP
    printf( "%s\n", $help);
}

sub dumpEventStack
    # For debugging, dump the event stack.
{
    my $eventTuple;

    foreach $eventTuple (@eventStack)
    {
        if ($$eventTuple{'tupleType'} eq "durationAdjust")
        {
            printf( "durAdj $$eventTuple{'tupleData'}\n");
        }
        elsif ($$eventTuple{'tupleType'} eq "event")
        {
            printf( "event %s\n", join( ", ", @{$$eventTuple{'tupleData'}}));
        }
        else
        {
            printf( "UNEXPECTED EVENT TUPLE TYPE: $$eventTuple{'tupleType'}\n");
        }
    }
}

sub handleBegin
    # Handle an event beginning.  Push event onto stack.
{
    my @args = @_;
    my(
       $yr, $mo, $da, $dow, $hrs, $min, $beginEnd, $phase, $rest, $comment)
        = @args;
    $DEBUG && printf( "BEGIN $yr/$mo/$da $hrs:$min '$rest'\n");
    if ($treatPhaseAsSubtask)
    {
        my @rest = split( " ", $rest);
        if (@rest)
        {
            $rest = join( " ", $rest[0], $phase, @rest[1..$#rest]);
            $DEBUG && printf( "\tmodified \$rest: '$rest'\n");
        }
        else
        {
            $rest = $phase;
        }
    }
    my @tupleData = ($yr, $mo, $da, $dow, $hrs, $min, $beginEnd, $phase,
                     $rest, $comment);
    my %eventTuple = ( tupleType => "event",
                       tupleData => \@tupleData);
    push( @eventStack, \%eventTuple);
}

sub timeDiff
    # Compute elapsed time between two events, in minutes.
{
                                # *_L -- later event
                                # *_E -- earlier event
    my(
       $yr_L, $mo_L, $da_L, $dow_L, $hrs_L, $min_L, $beginEnd_L, $phase_L, $rest_L, $comment_L,
       $yr_E, $mo_E, $da_E, $dow_E, $hrs_E, $min_E, $beginEnd_E, $phase_E, $rest_E, $comment_E)
        = @_;

    if (! (($yr_L == $yr_E) && ($mo_L == $mo_E) && ($da_L == $da_E)))
    {
        printf( STDERR "$myname: WARNING: time span crosses day boundary: %s, %s\n",
                "$yr_E-$mo_E-$da_E $hrs_E:$min_E", 
                "$yr_L-$mo_L-$da_L $hrs_L:$min_L");
    }

    my( $later, $earlier)
                                # Days are zero-based; years are since 1900.
        = (&mktime( 0, $min_L, $hrs_L, ($da_L - 1), $mo_L, ($yr_L - 1900)),
           &mktime( 0, $min_E, $hrs_E, ($da_E - 1), $mo_E, ($yr_E - 1900)));

    return (($later - $earlier) / 60);
}

sub computeDuration
    # Compute duration of just-ended event, in minutes.  Pop duration
    # adjustments, accumulating them, until you get to an event entry,
    # which will be the start marker for the current event.  Compute
    # time elapsed - duration adjustments.  Return popped
    # event-beginning tuple along w/duration and total elapsed time.
{
    my(
       $yr, $mo, $da, $dow, $hrs, $min, $beginEnd, $phase, $rest, $comment)
        = @_;
    my $durationAdjust = 0;
    my $eventTuple;

    (! @eventStack) && confess "attempt to pop empty stack";

    $eventTuple = pop( @eventStack);
    while ($$eventTuple{'tupleType'} eq "durationAdjust")
    {
        $DEBUG && printf( "\t\tduration adjust -%d\n", 
                          $$eventTuple{'tupleData'});
        $durationAdjust += $$eventTuple{'tupleData'};
        (! @eventStack) && confess "attempt to pop empty stack";
        $eventTuple = pop( @eventStack);
    }
    my $prevEvt = $$eventTuple{'tupleData'};
    my $wallClock = &timeDiff( @_, @$prevEvt);
    $DEBUG && printf( "\t\tduration = %d - %d\n", $wallClock, $durationAdjust);
    return ($eventTuple, $wallClock - $durationAdjust, $wallClock);
}

sub handleEnd
    # Handle an event ending.  Pop event off stack and replace with duration, 
    # for use in calculating duration of containing event.
{
    my(
       $yr, $mo, $da, $dow, $hrs, $min, $beginEnd, $phase, $rest, $comment)
        = @_;
    my( @classificationTag);
    $DEBUG && printf( "END   $yr/$mo/$da $hrs:$min phase:$phase '$rest'\n");
    my ($beginTuple, $duration, $wallClock) = &computeDuration( @_);
    $DEBUG && printf( "\tduration = %d (%g)\n", $duration, $duration/60);
    my %durationTuple = ( tupleType => "durationAdjust",
                          tupleData => $wallClock);
    push( @eventStack, \%durationTuple);

                                # Record data for entry.
                                # *_E ==> "earlier" event data

    my( $yr_E, $mo_E, $da_E, $dow_E, $hrs_E, $min_E, $beginEnd_E, $phase_E, $rest_E, $comment_E)
        = @{$$beginTuple{'tupleData'}};

#     printf( "handleEnd 1: rest:'$rest'\n");
#     printf( "handleEnd 1: rest_E:'$rest_E'\n");
    $rest = $rest_E . (($rest_E && $rest) ? " " : "") . $rest;
    $comment = $comment_E . (($comment_E && $comment) ? " " : "") . $comment;

#     printf( "handleEnd 2: rest:'$rest'\n");
    @classificationTag = split( " ", $rest);
    if (scalar( @classificationTag) == 0)
    {
        $classificationTag[0] = "";
    }

    $entryTime{ $rest} += $duration; # regardless of $dontCount
    $oneDayEntryTime{ $rest} += $duration; # regardless of $dontCount
    if ($comment)
    {
        $entryComment{ $rest} .= (($entryComment{ $rest} ? " -- " : "") 
                                  . $comment);
    }

    if (! $dontCount{ $classificationTag[0]})
    {
        my $day = "$yr_E/$mo_E/$da_E ($dow_E)";
        $dayTime{ $day} += $duration;
    }
}

sub handleEvent
    # Push or pop event onto stack.
{
    my(
       $yr, $mo, $da, $dow, $hrs, $min, $beginEnd, $phase, $rest, $comment)
        = @_;
    # printf( "handleEvent: yr:$yr mo:$mo da:$da dow:$dow hrs:$hrs min:$min\n");
    # printf( "handleEvent: b/e:$beginEnd phase:$phase rest:'$rest' comment:'$comment'\n");
    if ($beginEnd =~ m/[Bb]/)
    {
        &handleBegin( @_);
    }
    elsif ($beginEnd =~ m/[Ee]/)
    {
        &handleEnd( @_);
    }
    else
    {
        printf( "$myname: WARNING: unrecognized begin/end marker: '$beginEnd'\n");
    }
}

sub dumpDay
    # Dump the data for the current day, in one of a variety of
    # formats.
{
    my( $day) = @_;
    
    if ($oneLine)
    {
        &dumpDayRecords( $day);
    }
    else
    {
        &dumpDaySummary( $day);
    }
}

sub dumpDayRecords
    # Dump activity records for the given day, each record on a
    # single, tab-delimited line.  Fields are date, hours, tags,
    # comments.
{
    my( $day) = @_;
    my( $yrmoda);
    my (@events, $event, $eventName, $eventComment);
    my ($eventTime, $totEventTime);

    $yrmoda = (split( " ", $day))[0];
    foreach $eventName (keys( %oneDayEntryTime))
    {
        push( @events, $oneDayEntryTime{ $eventName} . "\0" . $eventName);
    }
    @events = sort { my @a_fields = split( "\0", $a);
                     my @b_fields = split( "\0", $b);
                     return ($b_fields[0] <=> $a_fields[0]) } @events;
    foreach $event (@events)
    {
        ($eventTime, $eventName) = split( "\0", $event, 2);
        if ($entryComment{ $eventName})
        {
            $eventComment = $entryComment{ $eventName};
        }
        else
        {
            $eventComment = "";
        }
        printf( "%s\t%f\t%s\t%s\n", $yrmoda,
                $oneDayEntryTime{ $eventName}/60.0, $eventName,
                $eventComment);
    }
}

sub dumpDaySummary
    # Dump a summary of the day's events to stdout, sorted in descending 
    # order of amount of time spent, not totalling classifications
    # from dontCount file.
{
    my( $day) = @_;
    my (@events, $event, $eventName, $eventDesc);
    my ($eventTime, $totEventTime);
    my (@primaryClassificationTag); # Top-level classification tag(s)
    my (@timeDecoration);       # Characters to put before and after
                                #   time to indicate that it didn't
                                #   count toward the daily total.
    
    format STDOUT =
@@####.#@ ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$timeDecoration[0], $eventTime/60, $timeDecoration[1], $eventDesc
~~          ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$eventDesc
.

    format STDOUT_subtotal = 
--------
@#####.#                                                       @<<<<<<<<<<<<<<<
$totEventTime/60, $day
_______________________________________________________________________________

.
    
    foreach $eventName (keys( %oneDayEntryTime))
    {
        push( @events, $oneDayEntryTime{ $eventName} . "\0" . $eventName);
    }
    @events = sort { my @a_fields = split( "\0", $a);
                     my @b_fields = split( "\0", $b);
                     return ($b_fields[0] <=> $a_fields[0]) } @events;
    foreach $event (@events)
    {
        ($eventTime, $eventName) = split( "\0", $event, 2);
#         printf( "dumpDaySummary last loop: eventName = '$eventName'\n");
        if ($entryComment{ $eventName})
        {
            $eventDesc = $eventName . " -- " . $entryComment{ $eventName};
        }
        else
        {
            $eventDesc = $eventName;
        }
        @primaryClassificationTag = split( " ", $eventName);
        if (scalar( @primaryClassificationTag) == 0)
        {
            $primaryClassificationTag[0] = "";
        }
        if ($dontCount{ $primaryClassificationTag[0]})
        {
            @timeDecoration = ("[", "]");
        }
        else
        {
            $totEventTime += $eventTime;
            @timeDecoration = ( " ", " ");
        }
        write;
    }

    $~ = "STDOUT_subtotal";
    write;
    $~ = "STDOUT";
}

sub handleDayBreak
    # Dump out stats for a single day and reset data, when date
    # changes in journal.
{
    my( $day, $prevDay, $beginEnd) = @_;

    if ($beginEnd =~ m/[Bb]/)
    {
        if ($day ne $prevDay)
        {
            &dumpDay( $prevDay);
            undef( %oneDayEntryTime);
                                # Prevent comments from stacking up
                                #   and up
            (! $accumComments) && undef( %entryComment); 
        }
    }
}

#================================================================
                                # main

if (@ARGV < 1)
{
    &help;
    exit( 1);
}

GetOptions( "accumComments" => \$accumComments,
            "oneLine" => \$oneLine,
            "dontCount=s" => \$dontCount,
            "phaseAsSubtask!" => \$treatPhaseAsSubtask)
    or die $!;

my( $journal, $entryBreakdown, $dayBreakdown) = @ARGV;

my( $yr, $mo, $da, $dow, $hrs, $min, 
    $beginEnd, $phase, $rest, $comment); # Data from journal entry

my $sawEntry = 0;               # true if we have seen a journal entry
my ($day, $prevDay);

if ($dontCount)
{
    # print "dontCount file is $dontCount\n";
    open( DONTCOUNTFILE, $dontCount);
    while (<DONTCOUNTFILE>)
    {
        s/^\s+//;               # leading space
        s/\s+$//;               # trailing space
        # print "\t\"$_\"\n";
        $dontCount{ $_} = 1;
    }
    close( DONTCOUNTFILE);
}

open( JOURNAL, $journal) || croak $!;

while (<JOURNAL>)
{
    $DEBUG && printf( "> $_");

    (! $sawEntry) && /^\s*\--/ && next; # comment lines

    /^\s*$/ && next;            # blank lines

    /^(\d+)-(\d+)-(\d+)\s+\((...)\)\s+(\d+):(\d+)\s+([BbEe])\s+(\w+)\s*(([^-]|-[^-])*)(--(-|\s)*)?(.*)?/ && do
                                # beginning of an event entry
    {
                                # new stuff
        my ($yr_N, $mo_N, $da_N, $dow_N, $hrs_N, $min_N, 
            $beginEnd_N, $phase_N, $rest_N, $comment_N)
            = ($1, $2, $3, $4, $5, $6, $7, $8, $9, $13);
        my $nCharsChomped = 0;
        do {
            $nCharsChomped 
                = chomp( $yr_N, $mo_N, $da_N, $dow_N, $hrs_N, $min_N,
                         $beginEnd_N, $phase_N, $rest_N, $comment_N);
        } until ($nCharsChomped == 0);

        $rest_N =~ s/(.*\S)\s*/$1/; # trim trailing whitespace
        $comment_N =~ s/(.*\S)\s*/$1/;

#        printf( "main: yr:%s mo:%s da:%s dow:%s hrs:%s min:%s b/e:%s phase:%s\n      rest:'%s' comment:'%s'\n",
#                $yr_N, $mo_N, $da_N, $dow_N, $hrs_N, $min_N, 
#                $beginEnd_N, $phase_N, $rest_N, $comment_N);

        if ($sawEntry)
        {
                                # Handle previously-built event.
            &handleEvent( $yr, $mo, $da, $dow, $hrs, $min, 
                          $beginEnd, $phase, $rest, $comment);
        }
        
        ($yr, $mo, $da, $dow, $hrs, $min, $beginEnd, $phase, $rest, $comment)
            = ($yr_N, $mo_N, $da_N, $dow_N, $hrs_N, $min_N, 
               $beginEnd_N, $phase_N, $rest_N, $comment_N);

        $day = "$yr/$mo/$da ($dow)";
        ($sawEntry) && &handleDayBreak( $day, $prevDay, $beginEnd);
        $prevDay = $day;

        $sawEntry = 1;
        next;
    };

    ($sawEntry) && /^\s+(([^-]|-[^-])*)(--(-|\s)*)?(.*)?/ && do
                                # continuation line
    {
        my( $restCont, $commentMarker, $commentCont) = ($1, $3, $4);
        ($restCont, $commentMarker, $commentCont)
            = ((defined( $restCont) ? $restCont : ""), 
               (defined( $commentMarker) ? $commentMarker : ""), 
               (defined( $commentCont) ? $commentCont : ""));
        my $nCharsChomped;
        do {
            $nCharsChomped = chomp( $restCont, $commentMarker, $commentCont);
#            printf( STDERR "chomp $nCharsChomped from %s\n", 
#                    join( "# ", $restCont, $commentCont));
        } until ($nCharsChomped == 0);

#         printf( "cont: rest:'%s' --:'%s' comment:'%s'\n",
#                 (defined( $restCont) ? $restCont : "(UNDEF)"), 
#                 (defined( $commentMarker) ? $commentMarker : "(UNDEF)"), 
#                 (defined( $commentCont) ? $commentCont : "(UNDEF)"));
        if ($comment)
        {
                                # comment started on prev. line, current text
                                # must be comment continuation.  commentMarker
                                # must actually be part of the comment.
            $comment .= " " . $restCont . " " . $commentMarker . " " . $commentCont;
        }
        elsif ($commentMarker)
        {
                                # THIS line explicitly started a comment
            $rest .= " " . $restCont;
            $comment = $commentCont;
        }
        else
        {
            $rest .= " " . $restCont;
        }

        $rest =~ s/(.*\S)\s*/$1/; # trim trailing whitespace
        $comment =~ s/(.*\S)\s*/$1/;

        next;
    };

    printf( STDERR "$myname: WARNING: unrecognized line '$_'");
}

                                # Handle previously-built event.
&handleEvent( $yr, $mo, $da, $dow, $hrs, $min, 
              $beginEnd, $phase, $rest, $comment);

close( JOURNAL);

&dumpDay( $day);

$DEBUG && do
{
    if (scalar( @eventStack))
    {
        printf( "\n$myname: NOTE: %d tuples left on the stack.\n\n", 
                scalar( @eventStack));
        &dumpEventStack();
    }
};

$DEBUG && printf( "\n");

my $key;

# (! $entryBreakdown) && ($entryBreakdown = $journal . ".entries");
# (! $dayBreakdown) && ($dayBreakdown = $journal . ".days");

if ($entryBreakdown)
{
    open( ENTRIES, "> $entryBreakdown")
        || croak "open( ENTRIES, \"> $entryBreakdown\") --> $!";
    foreach $key (keys( %entryTime))
    {
        my @entryWords = split( " ", $key);
        if (! $dontCount{ $entryWords[0]})
        {
            printf( ENTRIES "%8.2f\t%s\n", $entryTime{ $key}/60, $key);
        }
    }    
    close( ENTRIES);
}

if ($dayBreakdown)
{
    my( $yyyymmdd, $dow);
    $DEBUG && printf( STDERR "Opening \"%s\"\n", $dayBreakdown);
    open( DAYS, "> $dayBreakdown")
        || croak "open( DAYS, \"> $dayBreakdown\") --> $!";
    foreach $key (keys( %dayTime))
    {
        $DEBUG && printf( STDERR "%8.2f\t>%s<\n", $dayTime{ $key}/60, $key);
        my @entryWords = split( " ", $key);
        if (! $dontCount{ $entryWords[0]})
        {
            $key =~ m|(..../../..) \((.*)\)|;
            $yyyymmdd = $1;
            $dow = $2;
            printf( DAYS "%8.2f\t%s\t%s\n",
                    $dayTime{ $key}/60, $yyyymmdd, $dow);
        }
    }
    $DEBUG && printf( STDERR "Closing \"%s\"\n", $dayBreakdown);
    close( DAYS);
}

# $Log: psprpt.pl,v $
# Revision 1.3  2005/03/28 18:38:04  j6l
# General-purpose commit, just catching things up before adding summatch.pl.
#
# Revision 1.2  2004/09/13 13:28:31  J80Lusk
# Prevent 'dontCount' entries from appearing in entry, day breakdowns.
#
# Revision 1.1  2004/07/13 19:27:02  j80lusk
# Initial version?
