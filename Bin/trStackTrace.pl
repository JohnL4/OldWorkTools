#!/usr/bin/perl -w

=head1 NAME

trStackTrace.pl - write stacktrace legend and translate input

=head1 SYNOPSIS

 trStackTrace.pl --legend I<legendFilename> --msgDelimiter I<msgDelimiter>

=head1 DESCRIPTION

Translates a Canopy log file on stdin (e.g., fhcSysAdmin_{info,error}.log),
compressing stacktraces into smaller strings on stdout (unique key in
legendFile), updating legendFile as needed.

=head2 EXPORT

None by default.


=head1 AUTHOR

jlusk@a4healthsystems.com

=head2 VERSION

$Header: perl-template.pm, 1, 3/5/2002 7:00:51 PM, John Lusk$
    
=head1 SEE ALSO

L<perl>.

=head1 TODO

=head1 PUBLIC METHODS

=over

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

my $STACKFRAME_RE = "^\tat ";   # regexp matching stackframes

# ----------------------------------------------------------------------------
#  Static Methods
# ----------------------------------------------------------------------------

# Dumps traces in form "seqNum:trace", where seqNum is a positive integer and
# trace is a multiline stacktrace (w/embedded newlines).

sub dumpTraces
{
    my ($aLegendFileName,
        $aTraces                # ref to hash
        ) = @_;
    
    my $legendFH = FileHandle->new( "> $aLegendFileName")
        or die "FileHandle->new( \"> $aLegendFileName\"): $!";
    foreach my $trace (keys %$aTraces)
    {
        $legendFH->printf( "%d:%s\n", $aTraces->{$trace}, $trace);
    }
    $legendFH->close();
}

# Inhales trace legend d/b from disk and returns it as reference to a hash.

sub slurpTraces
{
    my ($aLegendFileName
        ) = @_;
    my $legendFH = FileHandle->new( "< $aLegendFileName");
    my $retval = {};
    my $trace;                  # Complete stacktrace.
    my $traceSeq;               # Unique sequence num of trace
    while (<$legendFH>)
    {
        chomp;
        s/\r//;
        /^(\d+):(.*)/ && do
        {
            if ($trace)
            {
                $retval->{$trace} = $traceSeq;
            }
            ($traceSeq, $trace) = ($1, $2); # Start new trace.
            next;
        };
        $trace .= "\n" . $_;
    }
                                # Last line counts as record break
    if ($trace)
    {
        $retval->{$trace} = $traceSeq;
    }
    undef $legendFH;
    return $retval;
}

# Returns a unique integer for the given trace.  If the trace is already
# present in the traces legend d/b, we return the previously-allocated
# integer.  Otherwise, we allocate a new integer and store the new trace in
# the legend d/b.

sub traceHash
{
    my ($aTraces,               # Ref to hash
        $aTrace                 # Trace in question
        ) = @_;

    my $retval = $aTraces->{$aTrace};
    if ( ! $retval)
    {
        $retval = scalar( keys %$aTraces) + 1;
        $aTraces->{$aTrace} = $retval;
    }
    return $retval;
}

# ----------------------------------------------------------------------------
#  Main
# ----------------------------------------------------------------------------

my ($opt_legendFileName,
    $opt_msgDelimiter);

GetOptions( "legend=s" => \$opt_legendFileName,
            "msgDelimiter=s" => \$opt_msgDelimiter)
    or die $!;

$opt_legendFileName = "stacktraces.txt" unless $opt_legendFileName;
$opt_msgDelimiter
    = "^----------------------------------------------------------------\$"
    unless $opt_msgDelimiter;

my $traces = &slurpTraces( $opt_legendFileName); # ref to hash

my $trace;                      # stacktrace

while (<>)
{
    chomp;
    s/\r//;
    /$STACKFRAME_RE/o && do
    {
        $trace = ($trace ? "$trace\n" : "") . $_;
        next;
    };
                                # We get here only for non-stacktrace lines.
    if ($trace)
    {
        # store in hash, get seqnum, write it out
        my $traceSeq = &traceHash( $traces, $trace);
        undef $trace;
        printf( "(stacktrace %d)\n", $traceSeq);
    }
    print( "$_\n");
}
				# Last line
if ($trace)
{
    # store in hash, get seqnum, write it out
    my $traceSeq = &traceHash( $traces, $trace);
    undef $trace;
    printf( "(stacktrace %d)\n", $traceSeq);
}

&dumpTraces( $opt_legendFileName, $traces);

# ----------------------------------------------------------------------------
#  END
# ----------------------------------------------------------------------------

1;
__END__

=pod

=back

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
