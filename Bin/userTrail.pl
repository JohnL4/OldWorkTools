#!/perl/bin/perl -w
                                # -*- coding: raw-text-dos -*-


=head1 NAME

userTrail.pl

=head1 SYNOPSIS

 userTrail.pl [-s sessionId...] [-f [fieldName]...]
    [-u userid...] [--think {after|before}] [-l iisLogfile]
    [-P pageSize] [-m]
    
 egrep '^#|jsessionid=' ex011206.log | userTrail.pl -P -1

=head1 DESCRIPTION

Show all transactions, in physical order (assumed to be chronological), for
the given list of session ids.  Display each of the specified fields, in the
order given.

=head2 PARAMETERS

=over

=item -f I<fieldName>

The fields to display.  If none are given, a default set will be used.  If
-f is given w/out parameters, the default set of field names will be
printed to stdout.

B<Default fields>

    Session          -- Session or userid
    Timestamp        -- GMT time at which request was issued
    Think time       -- User think time in seconds BEFORE request was
                        issued 
    Processing time  -- Processing time in seconds request required
                        on server 
    Method           -- e.g., GET or POST
    URI (munged?)    -- The URL used, possibly w/some extra parameter
                        fields that are informative.

=item -l I<iisLogfile>

The IIS log file from which to get data.  If none is given, input is taken
from stdin.

=item -m

Intermingle trails, possibly for purposes of debugging interactions
between users.  If not given, user trails will be printed w/out being
mixed w/trails from other users, in chronological order of first entry.

=item -P I<pageSize>

Number of lines to print on each page, not counting header.  Use -1 to
indicate that no headers should ever be printed.  Default is 63
($DEFAULT_PAGE_SIZE). 

=item -s I<sessionId>

The session ids to track.  If none are given, all transactions will be
displayed. 

=item --think {before|after}

Calculate think times either before the given URL was requested or after it
was requested.  In other words, "before" is "how long did the user think
BEFORE requesting this url?" and "after" is "how long did the user think AFTER
requesting this url?".  The default is "before".

=item -u I<userid>

Set of userids, analogous to session ids, in form "I<login>@I<domain>".
NOT CURRENTLY IMPLEMENTED.

=back

Parameters that are lists can be specified either as comma-delimited or
repeated uses of the option letter (e.g., -s 123 -s 456).

=head1 AUTHOR

john.lusk@canopysystems.com

=head2 VERSION

$Header: v:/J80Lusk/CVSROOT/Tools/Bin/userTrail.pl,v 1.6 2001/12/10 19:23:32 J80Lusk Exp $
    
=head1 SEE ALSO

L<perl>.

=head1 TODO

=cut

use 5.006;
use strict;
use warnings;
use Carp;
use Getopt::Long;
use Pod::Usage;

use WebServer::Log::Entry;

# ----------------------------------------------------------------------------
#  Globals
# ----------------------------------------------------------------------------

my $DEFAULT_PAGE_SIZE = 63;     # Number of lines to print on body of page
                                # before printing the header.

my ($BEGIN_ENTRY, $END_ENTRY);  # Special entries indicating the beginning and
                                # end of a user trail, for purposes of
                                # preventing false transitions occurring
                                # between trails.

my $gb_opt_think = "before";    # "gb" ==> global; "opt" ==> cmd-line option;
                                # "think" ==> actual option name (--think).

# ----------------------------------------------------------------------------
#  Static Methods
# ----------------------------------------------------------------------------

# Returns true iff the given entry is a transaction in one of the given
# session ids.  Returns true if @$sessionIds is empty, meaning "match all
# sessions".

sub matchesTrackedSession
{
    my ($entry, $sessionIds) = @_;

    my $retval = (! @$sessionIds)
        || scalar( grep( { $_ eq $entry->getUserId() } @$sessionIds));
    return $retval;
}

# Analogous to printEntry(), prints a header line indicating what fields are
# being displayed.

sub printHeader
{
    my ($fieldNames) = @_;

    if (@$fieldNames)
    {
        print "Custom field list unimplemented.\n";
    }
    else
    {
        my $dashes = sprintf( "%-20s %-19s %-4s %4s %4s %s\n",
                              "-" x 20, # userid
                              "-" x 19, # timestamp
                              "-" x 4, "-" x 4, # think, processing time
                              "-" x 4, # method
                                # Final "-5" is due to spaces between columns.
                              "-" x (79 - 20 - 19 - 4 - 4 - 4 - 5));
        print "$dashes";
        printf( "%-20s %-19s %-4s %3s %3s %s\n",
                "Session", "Timestamp",
                "Thnk", "Proc",
                "Meth", "URI (munged)?");
        print "$dashes";
    }
}

# Return thinktime between earlier and later entries.  May return undef.
#
# $laterEntry
# $earlierEntry

sub thinkTime
{
    my ($laterEntry, $earlierEntry) = @_;
    my $retval;
    if ($laterEntry
        and $laterEntry != $BEGIN_ENTRY
        and $laterEntry != $END_ENTRY)
    {
        $retval = $laterEntry->getThinkTime( $earlierEntry);
    }
    return $retval;
}

# Dump a log entry to stdout in the format this pgm is supposed to generate.
# May do nothing, if the parameters and $gb_opt_think specify so.
#
# Params:
#
#  $laterEntry -- The entry occurring later in time.  May be null or
#     $BEGIN_ENTRY or $END_ENTRY. 
#  $earlierEntry -- The entry occurring earlier in time.  May be null (undef).
#  $fields -- The fields of the entry to print

sub printEntry
{
    my ($laterEntry, $earlierEntry, $fields) = @_;

    my $prtEntry;               # Entry to print
    if ($gb_opt_think eq "before"
        or ($laterEntry and ($laterEntry eq $BEGIN_ENTRY
                             or $laterEntry eq $END_ENTRY)))
    {
        $prtEntry = $laterEntry;
    }
    else
    {
        $prtEntry = $earlierEntry;
    }
    if (! $prtEntry)
    {
        return;
    }
    
    if (@$fields)
    {
        print "Custom field list unimplemented.\n";
    }
    else
    {
                                # Print default fields
        
        my $thinkTime = &thinkTime( $laterEntry, $earlierEntry);
        printf( "%-20s %-19s %4d %4d %-4s %s\n",
                $prtEntry->getUserId(), $prtEntry->getExternalTimestamp(),
                (defined( $thinkTime) ? $thinkTime : -1), 
                $prtEntry->getProcessingTime(),
                $prtEntry->getMethod(), $prtEntry->getUriStem()); 
    }
}

# ----------------------------------------------------------------------------
#  Main
# ----------------------------------------------------------------------------

my $userNeedsHelp;
my @sessionIds = ();
my (@fieldNames, @userIds, $logfileName);
my $pageSize = $DEFAULT_PAGE_SIZE;
my $intermingleSessions;

GetOptions( "h" => \$userNeedsHelp,
            "s=s" => \@sessionIds,
            "f=s" => \@fieldNames,
            "u=s" => \@userIds,
            "l=s" => \$logfileName,
            "P=i" => \$pageSize,
            "think=s" => \$gb_opt_think,
            "m" => \$intermingleSessions)
    or pod2usage( 2);
    # or ($userNeedsHelp = 1);

if ($gb_opt_think !~ /^(before|after)$/)
{
    warn "--think must be 'before' or 'after'";
    $userNeedsHelp = 1;
}

@sessionIds = split( /,/, join( ",", @sessionIds));
@fieldNames = split( /,/, join( ",", @fieldNames));
@userIds = split( /,/, join( ",", @userIds));

if (@userIds)
{
    warn "Track by userId not implemented yet.  Use session ids instead";
}

if ($userNeedsHelp)
{
#     print "User WANTS help.\n";
#     pod2usage( -exit => 0,
#                -verbose => 2);
    system( "pod2text $0");
    exit 1;
}

$BEGIN_ENTRY = WebServer::Log::Entry->new();
$END_ENTRY = WebServer::Log::Entry->new();

for ($BEGIN_ENTRY)
{
    $_->setUserId( "99");
    $_->setMethod( "X");
    $_->setUriStem( "----(begin)----");
    $_->setProcessingTime( -99);
    $_->setExternalTimestamp( "....-..-.. ..:..:..");
}

for ($END_ENTRY)
{
    $_->setUserId( "99");
    $_->setMethod( "X");
    $_->setUriStem( "----(end)----");
    $_->setProcessingTime( -99);
    $_->setExternalTimestamp( "....-..-.. ..:..:..");
}

local (*IIS_LOG);               # filehandle

if ($logfileName)
{
    open( IIS_LOG, "< $logfileName")
        or die "open \"$logfileName\": $!";
}
else
{
    *IIS_LOG = *STDIN;
}

my %prevEntry;                  # Map from userId (session id) to
                                # previously-encountered entry for that
                                # session. 

my %entries;                    # Map from userId to ref. to list of entries
                                # for that userId.  Used for printing trails
                                # non-intermingled. 

my $printCount = 0;
while (<IIS_LOG>)
{
    chomp;
    s/\r//;                     # for cygwin
    /^\#Fields: / and do
    {
        print STDERR "\t$_\n";
        WebServer::Log::Entry->setFieldNames( $_);
        next;
    };
    /^\#/ and next;             # comments
    /^\s*$/ and next;           # blank lines
    my $entry = WebServer::Log::Entry->new( $_);

    if (matchesTrackedSession( $entry, \@sessionIds))
    {
        if ($intermingleSessions)
        {
            if ($pageSize > 0 and $printCount % $pageSize == 0)
            {
                print ("\f");       # formfeed
                printHeader( \@fieldNames);
            }
            printEntry( $entry, $prevEntry{ $entry->getUserId()},
                        \@fieldNames);
            $printCount++;
            $prevEntry{ $entry->getUserId()} = $entry;
        }
        else
        {
            push( @{$entries{ $entry->getUserId()}}, $entry);
        }
    }
}

if ($logfileName)
{
    close( IIS_LOG) || warn "close iis log: $!";
}

if ($intermingleSessions)
{
                                # Print final requests for each session to
                                #   flush thinktimes, if required.
    foreach my $userId (sort { $prevEntry{ $a}->getInternalTime()
                                   <=> $prevEntry{ $b}->getInternalTime() }
                        grep( { &matchesTrackedSession( $prevEntry{ $_},
                                                        \@sessionIds) }
                              keys %prevEntry))
    {
        &printEntry( undef, $prevEntry{ $userId}, \@fieldNames);
    }
}
else                            # ! $intermingleSessions
{
                                # Print each session separately as a "trail".

    print ("\f");               # formfeed.  For consistency, we start w/an
                                # unconditional blank page, even though we
                                # don't have to, because the intermingled case
                                # above does.
    printHeader( \@fieldNames);
    foreach my $userId (sort { $entries{ $a}->[0]->getInternalTime()
                                   <=> $entries{ $b}->[0]->getInternalTime() }
                        keys %entries)
    {
        printEntry( $BEGIN_ENTRY, undef, \@fieldNames);
        printEntry( $entries{ $userId}->[0], undef, \@fieldNames);
        $printCount++;
        my $n = @{$entries{ $userId}};
        for (my $i = 1; $i < $n; $i++)
        {
            if ($pageSize > 0 and $printCount % $pageSize == 0)
            {
                print ("\f");       # formfeed
                printHeader( \@fieldNames);
            }
            printEntry( $entries{ $userId}->[$i],
                        $entries{ $userId}->[$i-1],
                        \@fieldNames);
            $printCount++;
        }
                                # flush thinktimes
        &printEntry( undef, $entries{ $userId}->[$n - 1], \@fieldNames);
        printEntry( $END_ENTRY, undef, \@fieldNames);
        $printCount++;
    }
}

# ----------------------------------------------------------------------------
#  END
# ----------------------------------------------------------------------------

1;
__END__


# $Log: userTrail.pl,v $
# Revision 1.6  2001/12/10 19:23:32  J80Lusk
# Add thinktime before or after option.
# Doc changes.
#
# Revision 1.5  2001/08/31 20:43:46  J80Lusk
# Slight doc enhancement.
#
# Revision 1.4  2001/08/30 21:56:45  J80Lusk
# Add capability to dump multiple session trails intermingled (previous
# default) or separate (new default).
#
# Revision 1.3  2001/08/30 15:44:46  J80Lusk
# Add ability to have column headers printed out on each page (preceded
# by a form feed).
#
# Revision 1.2  2001/08/29 15:50:29  J80Lusk
# Gave up on printing current entry with lookahead.  How to know when to
# finally print the lookahead symbol?
#
# Revision 1.1  2001/08/29 15:19:09  J80Lusk
# Initial version -- before modifying to print prev entry instead of
# current entry.
#
