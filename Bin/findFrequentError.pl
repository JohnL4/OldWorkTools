#!/perl/bin/perl -w

# Process a multi-line log file containing Java stack traces, searching for a
# particular error and the most interesting stack record, in order to see in
# which processes the error is occurring.

use strict;                     # strict compilation warnings
use Carp;                       # better diagnostics (carp/croak
                                #   vs. warn/die).

my $RECORD_SEPARATOR = "xxxxx";
my $ERROR_STAMP = "Additional Info:  no FhcUIUtils";
my $INTERESTING_STACK_RECORD = "^\\s*at jsp\\.";

my $scanningStack = 0;          # True if we are scanning a java stacktrace
                                #   for something interesting.
my $builtLine = "";

while (<>)
{
    /$RECORD_SEPARATOR/ && do
    {
        $builtLine && printf( "%s\n", $builtLine);
        $scanningStack = 0;
    };
    /($ERROR_STAMP)/ && do
    {
        $scanningStack = 1;
        $builtLine = $1;        # Matched subexpression.
    };
    $scanningStack && /$INTERESTING_STACK_RECORD/ && do
    {
        chomp;                  # trailing newline
        s/^\s*/ /;              # leading whitespace
        $builtLine .= $_;       # string concat w/current input line.
    };
}

    
