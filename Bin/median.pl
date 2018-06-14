#!/perl/bin/perl -w
                                # -*- coding: raw-text-dos -*-


=head1 NAME

median.pl -- Print median value of input file values

=head1 SYNOPSIS

    median.pl -c <n> [<file>]

=head1 DESCRIPTION

=head2 OPTIONS

=over

=item -c I<n>

Column number (1-based) to use as numeric values for computing median.

=back

=head1 AUTHOR

john.lusk@canopysystems.com

=head2 VERSION

$Header: v:/J80Lusk/CVSROOT/Tools/Bin/median.pl,v 1.3 2001/12/10 19:41:39 J80Lusk Exp $
    
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
#  Static Methods
# ----------------------------------------------------------------------------

sub median
{
    my( $data) = @_;            # ref to list
    my @sortedData;
    
    @sortedData = sort { $a <=> $b } @$data;

    my $n = @sortedData;

    if ($n % 2 == 0)
    {
        return ($sortedData[ $n/2] + $sortedData[ $n/2 - 1]) / 2.0;
    }
    else
    {
        return $sortedData[ int( $n/2)];
    }
}

# ----------------------------------------------------------------------------
#  Main
# ----------------------------------------------------------------------------

my ($opt_colNum);

GetOptions( "c=i" => \$opt_colNum)
    or die $!;

($opt_colNum <= 0) && die "Must specify column number";

my @data;
my @cols;
my $filename;

while (<>)
{
    if (! defined( $filename))
    {
        $filename = $ARGV;
    }
    if ($filename ne $ARGV)
    {
        printf( "%s\t%g\n", $filename, &median( \@data));
        undef @data;
        $filename = $ARGV;
    }
    @cols = split( " ", $_);
    push( @data, $cols[ $opt_colNum - 1]);
}

printf( "%7g\t%s\n", &median( \@data), $filename);


# ----------------------------------------------------------------------------
#  END
# ----------------------------------------------------------------------------

__END__

# $Log: median.pl,v $
# Revision 1.3  2001/12/10 19:41:39  J80Lusk
# Number in 7-column field (right-justified), like wc outputs.
#
# Revision 1.2  2001/12/10 19:39:51  J80Lusk
# Switch order of output to:  number, file
# (vs. file, number).
#
# Revision 1.1  2001/11/11 01:44:56  J80Lusk
# Initial version.
#
