#!/perl/bin/perl -w
                                # -*- coding: raw-text-dos -*-

=head1 NAME

userTrailFreqDist - Frequency distribution of sub-sequences of the user trail

=head1 SYNOPSIS

    userTrailFreqDist [-h] [-f urlFieldOffset] [--minScore x]
        [--maxSeqLength n] [--seqLengthGrowthRate x] [-F {iis|trail}]
	[userTrailFile]

    cat ex0108??.log |
    userTransactions_iisFilter.pl
        -i userTransactions_iisFilter_uninterestingStuff.txt |
    userTrailFreqDist --minScore 0.01 --maxSeqLength 40

    userTrail -s 123 -l ex010823-filtered.log -P -1 |
        userTrailFreqDist -f -0

    cat ex0108??.log |
    userTransactions_iisFilter.pl
        -i userTransactions_iisFilter_uninterestingStuff.txt |
    userTrail.pl |
    userTrailFreqDist.pl --minScore 0.01 > userActivity-freqDist.txt

=head1 DESCRIPTION

Prints frequency distributions of groups of longer and longer subsequences of
length I<n> of the user's trail, until n increases such that no subsequences
of length n occur more than once.

Each trail element is numbered (in descending order of frequency), starting at
one, and trail subsequences are represented as element numbers separated by
hyphens.  I<Groups> of subsequences are indicated as sets of trail elements
and printed w/the accumulated scores of all subsequences in the group.  No
overlap between sequences in the same group is allowed.  For example, if
sequences "1-2-2-3" and "2-3-3-1" begin at offsets 0 and 2, respectively, they
are considered to be overlapping, and the latter sequence will be discarded.
(Note that if it had occurred at offset 4, it would not have been discarded,
and would have contributed to the total score for group "{1, 2, 3}".)

If you concatenate several user trails, each trail should start with a "begin"
token (e.g., "(begin)") and end w/an "end" token (e.g., "(end)").  This is to
prevent false patterns arising from spanning trails.

=head2 PARAMETERS

=over

=item -h

This help.

=item -F I<fileFmt>

The format of the input file.  Note that support for format "trail" is not
currently implemented.

=item -f I<urlFieldOffset>

B<Not implemented yet>.  Specifies the offset, counting from 0, from the left,
of the field containing the URLs comprising the trail elements.  Use negative
numbers to count from the right.  Use "-0" to specify the rightmost field.
Default is "-0".

=item --maxSeqLength I<maxLength>

Do not look for sequences longer than this; terminate after finding all
smaller sequences.  (Program will also terminate if a search for sequences
produces no sequences that occur more than once.)

=item --minScore I<relativeScore>

Do not report sequences whose scores are below (this number * total score).
Option value is expressed as a fraction of the total score of all entries in
the trail.

=item --seqLengthGrowthRate I<rate>

Number specifying the sequence length growth rate.  If 0.0, seq. window will
be grown by one on every iteration.  Otherwise, it will be grown by $seqLength
* $rate.  The default is somewhere in the 3-5% range.

=back

=head1 OUTPUT

Columns are:

=over

=item Id

(For sequences of length 1) The id assigned to the given sequence element.
All other sequences and group use number as abbreviations for these individual
elements.

=item Count

The number of times a sequence in the given sequence group occurred.

=item Time

The total time accounted for by all elements of all sequences in the group, in
seconds.  A higher time means the given sequence group covers more of the
input data.

=item Sequence

The sequence group itself.  In the case of sequences of length 1, this is the
actual element.  In other cases, the sequence groups are sets of elements.
Each set covers those sequences that have exactly the indicated elements.
(Sequences are made of element ids separated by dashes, but you'll probably
never see a single sequence in the output of this program.

=back

=head1 AUTHOR

john.lusk@canopysystems.com, with brainstorming help from
joe.bowers@canopysystems.com

=head2 VERSION

$Header: v:/J80Lusk/CVSROOT/Tools/Bin/userTrailFreqDist.pl,v 1.10 2001/09/10 20:22:05 J80Lusk Exp $

=head1 SEE ALSO

L<perl>,
L<userTransactions_iisFilter.pl>,
L<userTrail.pl>,
L<userTransactions.pl>.

=head1 TODO

High-scoring sequences will have a superset/subset relationship.  Many
sequences will be recognizable as subsets of longer sequences.  We should find
those relationships by sorting in descending order of sequence length and
building a lattice.  I'm not exactly sure how to process the lattice after
that, though.  We could roll scores up and down the lattice, maybe.
Graph-traversal algorithm, mark each node as its (non-cumulative) scores are
transmitted to other nodes.  Then maybe print out all nodes that have no
supersets (top level of lattice).

=cut
                                # ' fake out emacs font-lock
use 5.006;
use strict;
use warnings;
use Carp;
use Getopt::Long;

use IO::File;
# use IO::Handle;

use WebServer::Log::Entry;
use OrderedSet;

# ----------------------------------------------------------------------------
#  Globals
# ----------------------------------------------------------------------------

my $DEFAULT_SEQ_LENGTH_GROWTH_RATE = 0.04;

my $INPUT_FORMAT_USER_TRAIL = "user_trail";
my $INPUT_FORMAT_IIS_LOG    = "iis_log";

my ($BEGIN_ENTRY, $END_ENTRY);

# my @gbTrail;                    # The user's trail(s).  A list of
#                                 # WebServer::Log::Entries.

my @gbIdTrail;                  # The user's trail(s), with each element
                                # mapped to an id.

my $gbIdTrail;                  # join( "-", @gbIdTrail)

my %gbSeqEltId;                 # Map from sequence elements (URLs) to unique
                                # integer ids.

my $gbMaxIdDigits;              # Number of digits in largest id in
                                # %gbSeqEltId.  Used to construct string
                                # elements of uniform length, for translation
                                # of substring index to offset in trail of
                                # entries.

my $gbMinScore = 0;             # Minimum score a sequence must have to be
                                # printed, expressed as an integer (number of
                                # elements in @gbTrail, i.e., amount of
                                # @gbTrail that must be covered by sequence).

my %gbSigCache;                 # Cache of previously-computed signatures for
                                # sequences, keyed by seq. string.

# ----------------------------------------------------------------------------
#  Static Methods
# ----------------------------------------------------------------------------

# Returns the numeric sum over all list elements.
sub sum
{
    my (@list) = @_;

    my $sum = 0;
    foreach my $elt (@list)
    {
        $sum += $elt;
    }
    return $sum;
}

# Return true if $_ is a row of header labels instead of trail data.

sub isHeader
{
    my ($line) = @_;
    return $line !~ /^[0-9]+/;
}

# Make a WebServer::Log::Entry from a line of a user trail file, using the
# fields specified by -f

sub makeEntryFromTrailLine
{
    my ($line) = @_;

    croak "Not implemented";
}

# Make and store appropriately a WebServer::Log::Entry for later processing.
# Store in list keyed by session id.

sub storeEntry
{
    my ($trail,                 # hashref
        $entry)                 # WebServer::Log::Entry
        = @_;
    push( @{$trail->{ $entry->getUserId()}}, $entry);
}

# From the session-keyed hash of previously-stored Entries, make and return a
# reference to a single trail of Entries.

sub makeSingleTrail
{
    my ($trail) = @_;           # hashref
    my @trail;
    foreach my $key (sort { $trail->{ $a}->[0]->getInternalTime()
                                <=> $trail->{ $b}->[0]->getInternalTime() }
                     keys %$trail)
    {
        push( @trail, $BEGIN_ENTRY);
        push( @trail, @{$trail->{ $key}});
        push( @trail, $END_ENTRY);
    }
    return \@trail;
}

# Scans input data, returning a reference to a single trail (list) of
# WebServer::Log::Entries.

sub scanData
{
    my ($trailfileName, $trailfileFmt) = @_;

    print "Source data: ", ($trailfileName || "stdin"), "\n";

    my $trail = IO::File->new( "<" . ($trailfileName || "-"))
        or die "Open \"$trailfileName\" or stdin: $!";
    my $entry;
    my %trail;

    while (<$trail>)
    {
        chomp;
        if ($trailfileFmt eq $INPUT_FORMAT_USER_TRAIL)
        {
            /^--/ && next;      # Dashes of header lines.
            /^\s*$/ && next;    # blank lines
            isHeader( $_) && next; # Header labels.
            $entry = makeEntryFromTrailLine( $_);
        }
        elsif ($trailfileFmt eq $INPUT_FORMAT_IIS_LOG)
        {
            /^\#Fields:/ && WebServer::Log::Entry->setFieldNames( $_);
            /^\#/ && next;      # comments
            /^\s*$/ && next;    # blank lines
            $entry = WebServer::Log::Entry->new( $_);
        }
        else
        {
            croak "Unexpected trail file format: \"$trailfileFmt\"";
        }
        storeEntry( \%trail, $entry);
    }
    print "\n";

    close( $trail) or warn "close trail: $!";
    $trail = makeSingleTrail( \%trail); # ref to list

    return $trail;
}

# Given a sequence element (URL), returns a unique id for that seq. elt, for
# the purposes of constructing shorter strings than by using the original
# sequence element.  Returned id is padded on left zeros so that all returned
# ids will have the same length.  See $gbMaxIdDigits.

sub seqEltId
{
    my ($entry) = @_;
    my $url = $entry->getUriStem();
    my $id = $gbSeqEltId{ $url};
    if ($id)
    {
        return sprintf( "%0${gbMaxIdDigits}d", $id);
    }
    else
    {
        return $url;
    }
}

# Returns a characteristic signature (string) of the given sequence such that
# similar sequences will have the same signature, for some value of "similar".
# In this case, "similar" means two sequences have the same set of elements,
# possibly w/duplicates and possibly permuted.

sub sequenceSignature
{
    my ($seq,                   # List ref
        $seqStr)                # String version of sequence, possibly created
                                # previously for use in this call and later.
                                # If null, this function will create a local
                                # one for itself. 
        = @_;                   

    if (@$seq == 1)
    {
        # print "1";
        return $$seq[0];        # May not be a number (e.g., actual url), so
                                # skip attempt to sort numerically.
    }

    if (! defined( $seqStr))
    {
        $seqStr = makeSeqString( $seq);
    }

    my $retval = $gbSigCache{ $seqStr};
    if ($retval)
    {
        # print "*";
        return $retval;
    }

                                # Otherwise, sig for this particular has not
                                # previously been calculated.  Do so now, and
                                # cache. 
    # print "-";
    my %elts;
    for my $elt (@$seq)
    {
        $elts{ $elt} = 1;
    }
    $retval = join( ", ", sort { $a <=> $b } keys %elts);
    $gbSigCache{ $seqStr} = $retval;
    return $retval;
}

# Returns a pair of references:  list of sequence element ids for the
# $n-element subsequence beginning at offset $i (0-based) and list of
# WebServer::Log::Entries containing data for each element of the
# subsequence.

sub getSubsequence
{
    my ($trail, $i, $n) = @_;
    my @seq;
    my @entries;
    
    @entries = @{$trail}[$i..($i+$n-1)];

    if (@gbIdTrail)
    {
        @seq = @gbIdTrail[ $i .. ($i + $n - 1)];
    }
    else
    {
        @seq = map { seqEltId( $_) } @entries;
    }
    return (\@seq, \@entries);
}

# Turn the given list of element ids into a string, for use in string-matching
# and hashing operations.  This is a separate function call for profiling
# purposes.

sub makeSeqString
{
    my ($seq) = @_;             # list ref
    return join( "-", @{$seq});
}

# Returns reference to list of offsets of other sequences that overlap the
# current position.  Offsets of earlier sequences are given in $offsets,
# cur. posn is $i and length of sequences under consideration is $n.

sub overlappingOffsets
{
    my ($offsets,               # Hash ref, keys are offsets of earlier
                                # occurrences of sequences in the group.
        $range)                 # Ref to list of offsets to check for.
#         $i,                     # Index of current sequence under
#                                 # consideration. 
#         $n)                     # Length of current sequence (and all other
#                                 # sequences in this group).
        = @_;

    if (@$range == 0 or ! defined( $offsets))
    {
        return [];
    }
    
                                # If any previous seq. in this group started
                                # w/in $n elts of $i, it overlaps our current
                                # posn.
                                # 
                                # $n = 3
                                # .....
                                # ^ ^
                                # | +$i = 2
                                # +prev $i = 0
                                # @$offsets{ [0..1] }
                                # @$offsets{ [$i-$n+1 .. $i-1] }

    # my $range = [$i-$n+1..$i-1];
    my @overlappingOffsets
        = @$offsets{ @$range}; # hash slice
    return \@overlappingOffsets;
}

# Return a hash mapping subsequences of length n to attributes of those
# subsequences (the sum of scores over all occurrences (SCORE) of each
# subsequence, the occurrence count of each subsequence (COUNT)).  Also
# contains attributes OFFSETS (ref to list of starting indexes of all seqs in
# this bucket)  and SCANNED_FOR (ref to hash of subsequences encountered and
# scanned-for).

sub freqDist
{
    my ($trail,                 # List of WebServer::Log::Entries
        $n)                     # Length of subsequences to count.
        = @_;
    my %freqDist;
    my %seqLocn;                # Location of each subseq w/in the grand
                                # sequence.  Multiple subsequences cannot
                                # overlap, so if we find a subsequence (or
                                # permutation), we check here first to see
                                # whether or not to count it.

    my $range = [];             # Ref to list of indexes to check for
                                # containing offsets of overlapping
                                # sequences.  For efficiency, we maintain this
                                # range separately from function
                                # overlappingOffsets(), where it's used.
                                # Range is always the list of previous offsets
                                # that might begin an overlapping sequence,
                                # [$i-$n+1..$i-1], when overlappingOffsets()
                                # is called.  If we regenerated it every time
                                # we called overlappingOffsets(), we'd lose
                                # efficiency.

    # printf( "freqDist( %d) --\n", $n);

  SUBSEQ_WINDOW:                # Advance a window of size $n over the
                                # sequence, taking subsequences and doing
                                # counts, etc.
    for (my $i = 0;
         $i < @{$trail} - $n + 1;
         do {
                                # Funky 'for' stmt because we have 'next
                                # SUBSEQ_WINDOW' stmts in the loop.
             push( @$range, $i);
             if (@$range >= $n)
             {
                 shift( @$range);
             }
             $i++;
         } )
    {
        # print "$i: ";

        my $entries;
        my $seq;
        my $seqSig;             # signature.  multiple different seqs will
                                # share the same sig, for data coalescing
        my $seqScore;


        ($seq, $entries) = getSubsequence( $trail, $i, $n);

                                # Get the seq signature, check to see if this
                                # seq or a similar one started at
                                # currentOffset - length + 1 or greater.  If
                                # so, skip.  If not, enter this offset into
                                # sig's list and process this seq.
        my $seqStr = makeSeqString( $seq);
        $seqSig = sequenceSignature( $seq, $seqStr);

        if (grep( { defined( $_) }
                  @{overlappingOffsets( $freqDist{ $seqSig}->{OFFSETS},
                                        $range)}))
#                                         $i, $n)}))
        {
                                # At least one value defined in
                                # @overlappingOffsets.  Bail.
#             print( "Seq $seqStr beginning at $i overlaps other occurrence(s) beginning at ",
#                    join( ", ", grep( { defined( $_) }
#                                      @{overlappingOffsets( $freqDist{ $seqSig}->{OFFSETS},
#                                                            $range)})),
#                    "\n");
            next SUBSEQ_WINDOW;
        }

                                # Otherwise, we're not overlapping w/a
                                # previously scanned sequence (probably some
                                # permutation of the current seq).
        
        $freqDist{ $seqSig}->{OFFSETS}->{$i} = $i;
        
        # print ". $seqStr\n";

        $seqScore = sum( map { $_->getProcessingTime() } @$entries);
        $freqDist{ $seqSig}->{SCORE} += $seqScore;
        $freqDist{ $seqSig}->{COUNT}++;

    }
    return \%freqDist;
}

# Use a frequency distribution returned by freqDist() to set up the sequence
# element to id mapping.

sub setupSeqEltIds
{
    my ($freqDist) = @_;        # hash ref
    my $id = 1;

    foreach my $seqElt (sort {-1 * ($freqDist->{$a}->{SCORE}
                                    <=> $freqDist->{$b}->{SCORE})}
                        keys %$freqDist)
    {
        $gbSeqEltId{ $seqElt} = $id++;
    }
    $gbMaxIdDigits = length( $id - 1); # Cvt to string, take length.  Ain't
                                # perl wunnerful?
}

# Returns true if the given sequence can overlap itself, meaning some prefix
# of it can match the suffix (having the same length).  Given seq is either a
# reference to a list OR a string with form "id-id-id...", where each id is a
# sequence element id.

sub overlappable
{
    my ($seq) = @_;

    my $retval = 0;
    my $seqElts;                # list ref to @seqElt (or something else ;)

    if (ref $seq)
    {
        $seqElts = $seq;
    }
    else
    {
                                # Assume big string of form "99-99-99".
        my @seqElt = split( "-", $seq);
        $seqElts = \@seqElt;
    }

                                # ababab -- len=6
                                #  ababa -- no, n=5, pref=[0..4], suff=[1..5]
                                #   abab -- yes, n=4, pref=[0..3], suff=[2..5]

    my $len = @$seqElts;
    for (my $n = $len - 1; ! $retval and $n > 0; $n--)
    {
        my $prefix = join( "-", @{$seqElts}[ 0..($n-1)]);
        my $suffix = join( "-", @{$seqElts}[ ($len-$n)..($len-1)]);
        $retval = ($prefix eq $suffix);
        if ($retval)
        {
            $retval = length( $prefix);
        }
    }
    return $retval;
}

# Prints a line explaining the frequency distribution columns.

sub printFreqDistHeader
{
    printf( "Id");
    printf( "\t%7s\t%7s\t%s\t%s\n", "Count", "Time", "Seq",
            "* = Overlappable");
    # print( "Id\tCount\tScore\tSeq\tOverlappable\n");
}

# Print a frequency dist. hash returned by freqDist().  If $length is 1,
# includes a column showing the id for each sequence printed (the assmption is
# that each sequence has length 1 and this will be the element-to-id mapping).
#
# Params:
#  $freqDist   -- ref to hash of frequencies as produced by freqDist()
#  $length     -- all sequences are of this length

sub printFreqDist
{
    my ($freqDist, $length) = @_;        # ref to hash

    my $printSeqEltIds = ($length == 1);

    foreach my $seq (sort {-1 * ($freqDist->{$a}->{SCORE}
                                 <=> $freqDist->{$b}->{SCORE})}
                     keys %$freqDist)
    {
        if ($printSeqEltIds)
        {
            print $gbSeqEltId{ $seq};
        }
        if ($printSeqEltIds
            or (($freqDist->{ $seq}->{SCORE} >= $gbMinScore)
                and ($freqDist->{ $seq}->{COUNT} > 1)))
        {
            my $score;
            $score = $freqDist->{ $seq}->{SCORE};
            my $count = $freqDist->{ $seq}->{COUNT};
            my $strippedSeq = $seq;
            if ($printSeqEltIds)
            {
                $strippedSeq = $seq;
            }
            else
            {
                $strippedSeq
                    = "{" . join( ", ", map { $_ + 0 } split( ", ", $seq))
                        . "}";
            }
#             my $overlappable = overlappable( $strippedSeq);
            my $overlappable = 0;
            printf( "\t%7d\t%7d\t%s%s\n",
                    $count, $score, $strippedSeq,
                    ($overlappable ? "*" : ""));
        }
    }
}

# ----------------------------------------------------------------------------
#  Static Initializers (for globals)
# ----------------------------------------------------------------------------

$BEGIN_ENTRY = WebServer::Log::Entry->new();
$END_ENTRY = WebServer::Log::Entry->new();

for ($BEGIN_ENTRY)
{
    $_->setUserId( "99");
    $_->setMethod( "X");
    $_->setUriStem( "----(begin)----");
    $_->setProcessingTime( 0);
    $_->setExternalTimestamp( "....-..-.. ..:..:..");
}

for ($END_ENTRY)
{
    $_->setUserId( "99");
    $_->setMethod( "X");
    $_->setUriStem( "----(end)----");
    $_->setProcessingTime( 0);
    $_->setExternalTimestamp( "....-..-.. ..:..:..");
}

# ----------------------------------------------------------------------------
#  Main
# ----------------------------------------------------------------------------

my $fieldOffset;
my $minScore = 0;
my $userWantsHelp;
my $userNeedsHelp;              # regardless of *wanting* it
my $trailfileFmt = "iis";
my $maxSeqLength;
my $seqLengthGrowthRate = $DEFAULT_SEQ_LENGTH_GROWTH_RATE;

my $trail;                      # Ref to list of WebServer::Log::Entries

GetOptions( "h" => \$userWantsHelp,
            "F=s" => \$trailfileFmt,
            "f=s" => \$fieldOffset,
            "minScore=f" => \$minScore,
            "maxSeqLength=i" => \$maxSeqLength,
            "seqLengthGrowthRate=f" => \$seqLengthGrowthRate)
    or die $!;

my $trailfileName = $ARGV[0];

if ($trailfileFmt =~ m/^iis/i)
{
    $trailfileFmt = $INPUT_FORMAT_IIS_LOG;
}
elsif ($trailfileFmt =~ m/^trail/i)
{
    $trailfileFmt = $INPUT_FORMAT_USER_TRAIL;
}
else
{
    warn "Invalid trail file format (\"$trailfileFmt\")";
    $userNeedsHelp = 1;
}

if ($userWantsHelp || $userNeedsHelp)
{
    system( "pod2text $0");
    exit 1;
}

$trail = scanData( $trailfileName, $trailfileFmt);

my $totScore = sum( map { $_->getProcessingTime() } @$trail);
$gbMinScore = $minScore * $totScore;

print "Total elements in trail: ", scalar( @$trail),
    "\n\tscore (total processing time, in seconds): ",
    sum( map { $_->getProcessingTime() } @$trail),
    "\n\t(Includes begin/end pairs, if present.)\n";
print "Minimum score for a subsequence to be printed: $gbMinScore ($minScore)\n";
print "Seq. length growth rate: $seqLengthGrowthRate\n";

my $seqLength = 1;

print "\n";
printFreqDistHeader();

for (;;)
{
    undef %gbSigCache;          # No need to cache entries for sequences we'll
                                # never see again (because we're changing our
                                # seq. window size).
    my $freqDist = freqDist( $trail, $seqLength);
    if ($seqLength == 1)
    {
        setupSeqEltIds( $freqDist);
        @gbIdTrail = map { seqEltId( $_) } @$trail;
        $gbIdTrail = join( "-", @gbIdTrail);
        # print "trail: ", join( "-", @gbIdTrail[0..9]), "....\n";
        # print( "trail: ", $gbIdTrail, "\n");
    }
    print "\nSequences of length $seqLength:\n\n";
    printFreqDist( $freqDist, $seqLength);

                                # Bail out unless at least one freq. count
                                # was > 1.
    (! grep({$freqDist->{$_}->{COUNT} > 1} keys %$freqDist)) && last; # break

                                # When we get into high sequence lengths, we
                                # may not want to increment the window size by
                                # 1 any more, since we're likely to get very
                                # similar results.  A growth rate of 0.03
                                # gives an increment of > 2 if $segLength >
                                # 66.

    my $incr = int( $seqLengthGrowthRate * $seqLength);
    if ($incr < 1) { $incr = 1; }
    $seqLength += $incr;
    defined( $maxSeqLength) && ($seqLength > $maxSeqLength) && last;
}


# ----------------------------------------------------------------------------
#  END
# ----------------------------------------------------------------------------

1;
__END__


# $Log: userTrailFreqDist.pl,v $
# Revision 1.10  2001/09/10 20:22:05  J80Lusk
# Update POD.
#
# Revision 1.9  2001/09/10 19:48:29  J80Lusk
# A little extra POD line, and credit Joe w/his assistance.
#
# Revision 1.8  2001/09/10 19:39:12  J80Lusk
# Add seqLengthGrowthRate option.
# Optimize sequenceSignature() by caching results in hash.
# Implement alternate scheme of finding overlapping sequences:  bitmap
#     of previously-matched sequences accessed with slice (list of
#     indexes) to see if any matches occurred in the "vulnerable" range
#     of the current sequence.  This is because insertion into the
#     OrderedSet was too costly (involved list-shifting operations) and
#     there was no way to batch-insert (via sort()) to avoid polynomial
#     time complexity.
# Removed large previously-commented-out m// loop that just didn't work.
#     The problem is that previous matches on a sequence in the same
#     "sequence group" could occur at offsets beyond the current offset,
#     and could spuriously cause the sequence at the current offset to
#     be rejected as overlapping when it would not otherwise have been,
#     resulting in a non-maximal set of sequence matches.  When checking
#     for overlaps, we need to restrict ourselves... oops, we could have
#     just checked the left neighbor instead of both left and right
#     neighbors.  Oh well, it was inefficient anyway because of the need
#     to decompose matched substrings back into their Entry lists in
#     order to sum up their scores.  Although...  I bet we could do
#     something like decompose and sum only the first 10 or so
#     occurrences and after that, just use the average w/out further
#     decomposition.  Hmmm.
# Took out the ansi control sequence splitOnOverlapBoundary() function.
#     Visual clutter.
# Remove tab before "*" overlappable marker, which is now never printed
#     anyway.
# (Somewhere along the way, I changed the output to summarize on
#     sequence groups (sets of common elements) instead of printing data
#     for each sequence.  The latter approach generated a large quantity
#     of similar lines that added no info.  Now I'm counting any
#     occurrence of a sequence in the same group as another sequence to
#     be the same sequence, essentially.)
#
# Revision 1.7  2001/09/09 16:59:33  J80Lusk
# Add maxLength option.
# Change meaning of minScore back to fraction [0..1].
# Factor freqDist() into some more subroutines, to get a more-accurate
#     picture during profiling.  Turn some lists and hashes into
#     references to same, for more-efficient parameter passing.
# Use OrderedSet to store offsets of previous matches, to check to prevent
#     overlap during matching.  Turned out to be a bad implementation,
#     since OrderedSet inserts are inserts into a long list (with
#     attendant list-shifting).
# Wire the Big Choice of matching algorithms to one direction (not m//).
#
# Revision 1.6  2001/09/07 14:19:10  J80Lusk
# "Score" is now total processing time for all occurrences of the given
# sequence, instead of count * seqLength.  The previous value
# essentially assumed each request in the sequence took 1 second of
# processing time; the new value gives a more accurate weighting to
# processing time, so we can account better for the load on the server.
#
# Revision 1.5  2001/08/31 20:43:13  J80Lusk
# More docs, slightly more-verbose output.
#
# Revision 1.4  2001/08/30 22:00:16  J80Lusk
# Some obvious optimizations for speed.
# Add minimum-score filter, to prevent junk lines from getting printed
#    out.
#
# Revision 1.3  2001/08/30 17:55:05  J80Lusk
# Improve docs, output.
# Also, implement a way find the size of the maximal set of matching
#    subsequences when the subsequences could overlap themselves.
#
# Revision 1.2  2001/08/30 15:43:19  J80Lusk
# More-concise method for opening file or stdin works.
# Also, just by the way, wrote the entire rest of the functionality.
# Next step:  find maximal set of occurrences of subsequences that might
#    overlap.  (Currently, I discard subsequences that might overlap,
#    because the counts might be inaccurate.)
#
# Revision 1.1  2001/08/29 19:38:27  J80Lusk
# Initial version.
# Checking in before using more-concise notation for opening a
# cmd-line-arg file or stdin.
#
