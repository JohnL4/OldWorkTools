#!/perl/bin/perl -w
                                # -*- coding: raw-text-dos -*-


=head1 NAME

gc-log-parse.pl -- analyze record of GCs produced by -verbose:gc

=head1 SYNOPSIS

 gc-log-parse.pl <file>

=head1 DESCRIPTION

Sum of time spent in GC.


=head1 AUTHOR

john.lusk@canopysystems.com

=head2 VERSION

$Header: v:/J80Lusk/CVSROOT/Tools/perl-template.pm,v 1.5 2001/08/28 16:21:27 J80Lusk Exp $
    
=head1 SEE ALSO

L<perl>.

=head1 TODO


=cut

use 5.006;
use strict;
use warnings;
use Carp;
use Getopt::Long;


# ----------------------------------------------------------------------------
#  Globals
# ----------------------------------------------------------------------------


# ----------------------------------------------------------------------------
#  Main
# ----------------------------------------------------------------------------

# my ($opt_a, $opt_b);
# 
# GetOptions( "a=s" => \$opt_a,
#             "b=s" => \$opt_b)
#     or die $!;

my ($start, $startUnit, $end, $endUnits, $totHeap, $totHeapUnits, $secs);
my $totTime = 0;

while (<>)
{
    /\[.*\bGC\s+(\d+)(.*)->(\d+)(.*)\((\d+)(.*),\s+(\S+)\s+secs\]/ && do
    {
        ($start, $startUnit, $end, $endUnits, $totHeap, $totHeapUnits, $secs)
            = ($1, $2, $3, $4, $5, $6, $7);
        $totTime += $secs;
        print( "$secs\n");
        next;
    };
    print "Unexpected record: $_";
}

print "Tot. time = $totTime secs.\n";

# ----------------------------------------------------------------------------
#  END
# ----------------------------------------------------------------------------

1;
__END__

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
