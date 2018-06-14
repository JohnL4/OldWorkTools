#!/usr/bin/perl -w

# Use this template for both scripts (.pl) and modules (.pm).

# Below is stub documentation for your module. You better edit it!

=head1 NAME

summatch.pl - sum lines that match regexps, printing totals on section break

=head1 SYNOPSIS

 summatch.pl --match I<match-re-file> --skip I<skip-re> --break I<break-re> \
    --datacol I<n> I<data-file>

=head1 DESCRIPTION

Script scans given file, assuming numeric data is in column I<n>.  Lines
matching a regular expression given in I<match-re-file> have their numeric
data added to a total keyed by the "match regexp key" specified in
I<match-re-file>.  (TODO: this file should really be an XML file, but I don't
have time right now.)

When a section break (or end of data) is recognized, all totals are printed
out (by key), reset to zero and matching resumes w/the next section.

=head2 OPTIONS

=over

=item --match I<match-re-file>

File containing lines of form "key re", where I<key> contains no whitespace
(I<re> may contain whitespace).

=item --skip I<skip-re>

Regular expression matching lines to be skipped entirely.  No summation will
be performed, nor will the line be scanned for a possible section break.
Default is empty lines, lines made of underscores or dashes, lines beginning
with "[" (psprpt.pl generates these to indicate clearly off-the-job time) and
lines containing only numbers (psprpt.pl totals).

=item --break I<break-re>

Regular expression indicating a section break.  Default matches dates
occurring at the end of the line in the form "yyyy/mm/dd/ (www)".

=item --datacol I<n>

The 0-based column number of the column containing the data to be summed.

=back

=head1 AUTHOR

jlusk@a4healthsystems.com

=head2 VERSION

$Header: v:/J80Lusk/CVSROOT/Tools/Bin/summatch.pl,v 1.3 2005/03/28 19:28:34 j6l Exp $
    
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

# ----------------------------------------------------------------------------
#  Globals
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
#  Static Methods
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
#  Main
# ----------------------------------------------------------------------------

my ($opt_match_re_file,
    $opt_skip_re,
    $opt_break_re,
    $opt_datacol,
    $opt_verbose,
    );

GetOptions( "match=s"   => \$opt_match_re_file,
            "skip=s"    => \$opt_skip_re,
            "break=s"   => \$opt_break_re,
            "datacol=i" => \$opt_datacol,
            "verbose"   => \$opt_verbose,
            )
    or die "GetOptions(): $!";

my ($datacol,                   # User-entered or default
    $break_re,                  # User-entered or default
    $skip_re,
    );

$datacol = $opt_datacol || 0;

       
$break_re = $opt_break_re 
                                # "YYYY/mm/dd (www)"
    || "\\d\\d\\d\\d/\\d\\d/\\d\\d \\(\\S\\S\\S\\)\\s*\$"; 

$skip_re = $opt_skip_re
                                # Lines of underscores or dashes (or empty),
                                #   lines beginning w/"[" or that contain
                                #   nothing but a number (totals). 
    || "^[-_]*\\s*\$|^\\[|^\\s*\\d+\\.\\d+\\s*\$";

my @res =                       # List of objects (tuples) with members "key",
                                #   "re".  
    &slurpREs( $opt_match_re_file); 

my %sum;                        # Map from matched string to sum of data
                                #   column. 
my %unmatched;                  # Map from unmatched string to sum of data
                                #   column. 
my $breakMatch;                 # Matched break RE, for dumping totals w/a
                                #   label.  The assumption is that the text
                                #   for *this* break is the correct label to
                                #   use when printing out the section
                                #   subtotals. 

while (<>)
{
    chomp;
    s/\r//;
    if ($_ =~ m/$skip_re/o)
    {
        if ($opt_verbose) { printf( "%s\n", $_); }
        next;
    }
    if ($_ =~ m/($break_re)/o)
    {
        if ($opt_verbose) { printf( "%s\n", $_); }
        $breakMatch = $1;
        &dumpTotals( $breakMatch, \%sum, $opt_verbose);
        printf( "\n");
        undef %sum;
        next;
    }
    my @cols = split( " ", $_);
    my $matchKey = &matchKey( $_, \@res);
    if ($matchKey)
    {
        if ($opt_verbose) { printf( "%s -- %s\n", $_, $matchKey); }
        $sum{ $matchKey} += $cols[ $datacol];
    }
    else
    {
        if ($opt_verbose) { printf( "%s\n", $_); }
        my $unmatched_key = join( " ", @cols[ 0..($datacol - 1)],
                                  @cols[ ($datacol + 1)..$#cols]);
        $unmatched{ $unmatched_key} += $cols[$datacol];
    }
}
&dumpTotals( $breakMatch, \%sum, $opt_verbose);
&dumpUnmatched( \%unmatched);

# Done.

# ----------------------------------------------------------------------------
#  Subroutines
# ----------------------------------------------------------------------------

# Suck the match REs in from the specified file, returning a list of MatchRE
# objects.   Discard blank and comment lines (comment char = "#").

sub slurpREs
{
    my ($aMatchFileName,
        ) = @_;
    my @retval;
    if ($aMatchFileName)
    {
        my $fh = FileHandle->new( "< $aMatchFileName")
            or die "FileHandle->new( \"< $aMatchFileName\"): $!";
        while (<$fh>)
        {
            chomp;
            s/\r//;
            if (($_ =~ m/^\s*\#/) || ($_ =~ m/^\s*\$/))
            {
                next;           # comment or blank
            }
            my @cols = split( " ", $_);
            my $key = $cols[0];
            my $matchTgt;
            ($matchTgt = $_) =~ s/^\s*\S+\s+//;
            my $matchRE = MatchRE->new( $key, $matchTgt);
            push( @retval, $matchRE);
        }
        $fh->close();
    }
    else
    {
        @retval = ();
    }
    return @retval;
}

# Return the key corresponding to the match re that the given line matches.
# Return undef if no match.

sub matchKey
{
    my( $anInputLine,           # Line of input.
        $anREList,              # Ref to List of MatchREs
        ) = @_;
    my $retval;
    for (my $i = 0; ($i < @$anREList) && (! $retval); $i++)
    {
        my $matchRE = $anREList->[$i]->getRE();
        if ($anInputLine =~ m/$matchRE/)
        {
            $retval = $anREList->[$i]->getKey();
        }
    }
    return $retval;
}

# Dump the total times accumulated so far, by key order.  If no data has been
# accumulated, prints nothing.

sub dumpTotals
{
    my ($aSectionName,
        $aSum,                  # Ref to hash, mapping match to total of data
                                #   column.
        $aVerbose,
        ) = @_;
    if (scalar( keys %$aSum) > 0)
    {
        my $total = 0;
        my @keys = sort { $a cmp $b } (keys %$aSum);
        my $leader = ($aVerbose ? "[1m* " : ""); # bold
        my $trailer = ($aVerbose ? "[0m" : ""); # normal
        printf( "%s%s\n", $leader, $aSectionName);
        foreach my $key (@keys)
        {
            # printf( "\t%s\t%g\n", $key, $aSum->{$key});
            printf( "%s\t%6.1f\t%s\t\n", $leader, $aSum->{$key}, $key);
            $total += $aSum->{$key};
        }
        printf( "%s\t%s\n%s\t%6.1f\t(Total)%s\n",
                $leader, "-" x 6, $leader, $total, $trailer);
    }
}

# Dump the unmatched totals, in descending total order.

sub dumpUnmatched
{
    my ($aSum,                  # Ref to hash, mapping match to total of data
                                #   column.
        ) = @_;
    my $total;
    my @keys = sort { $aSum->{$b} <=> $aSum->{$a} } (keys %$aSum);
    printf( "\n%s\n", "Unmatched strings:");
    foreach my $key (@keys)
    {
        printf( "\t%6.1f\t%s\n", $aSum->{$key}, $key);
        $total += $aSum->{$key}
    }
    printf( "\t%s\n", "-" x 6);
    printf( "\t%6.1f\t(Total)\n", (defined( $total) ? $total : 0));
}

# ----------------------------------------------------------------------------
#  package MatchRE
# ----------------------------------------------------------------------------

package MatchRE;

sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    bless ($self, $class);
    $self->initialize( @_);
    return $self;
}

sub initialize
{
    my $self = shift;
    my ($aKey,                  # "key" of match (arbitrary string, acting as
                                #   an identifier or a title or a summary)
        $anRE,                  # Regexp that produces match
        ) = @_;
    
    $self->{_KEY} = $aKey;
    $self->{_RE} = $anRE;
}

sub getKey
{
    my $self = shift;
    return $self->{_KEY};
}

sub getRE
{
    my $self = shift;
    return $self->{_RE};
}

# ----------------------------------------------------------------------------
#  END
# ----------------------------------------------------------------------------

1;
__END__

=pod

=cut

# $Log: summatch.pl,v $
# Revision 1.3  2005/03/28 19:28:34  j6l
# *** empty log message ***
#
# Revision 1.2  2005/03/28 19:26:23  j6l
# *** empty log message ***
#
# Revision 1.1  2005/03/28 18:38:06  j6l
# General-purpose commit, just catching things up before adding summatch.pl.
