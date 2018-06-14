#!/perl/bin/perl -w
                                # -*- coding: raw-text-dos -*-

# Below is stub documentation for your module. You better edit it!

=head1 NAME

cvs2gnuplot.pl -- Extract gnuplot x-y pairs from CSV files, for plotting

=head1 SYNOPSIS

    csv2gnuplot.sh -x <xCol> -y <yCol>

=head1 DESCRIPTION

Reads stdin, writes to stdout.

=head2 PARAMETERS

=over

=item -x I<xCol>, -y I<yCol>

Offsets from 0 of the columns in the input data holding x- and y-values.

=back

=head1 AUTHOR

john.lusk@canopysystems.com

=head2 VERSION

$Header: v:/J80Lusk/CVSROOT/Tools/Bin/csv2gnuplot.pl,v 1.1 2001/09/24 23:37:17 J80Lusk Exp $
    
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

my ($opt_xCol, $opt_yCol);      # Offsets from 0.
my @fields;                     # Values from input record
my ($x, $y);

GetOptions( "x=i" => \$opt_xCol,
            "y=i" => \$opt_yCol)
    or die $!;

if (! defined( $opt_xCol)
    or ! defined( $opt_yCol))
{
    system( "pod2text $0");
    exit 1;
}

while (<>)
{
    chomp;
    @fields = split( /,/, $_);
    ($x, $y) = @fields[ $opt_xCol, $opt_yCol];
    $x =~ s/^[ \"]*([^\"]*)[\" ]*$/$1/;
    $y =~ s/^[ \"]*([^\"]*)[\" ]*$/$1/;
    printf( "%s\t%s\n", $x, $y);
}

# ----------------------------------------------------------------------------
#  END
# ----------------------------------------------------------------------------

1;
__END__


# $Log: csv2gnuplot.pl,v $
# Revision 1.1  2001/09/24 23:37:17  J80Lusk
# Initial version.
#
# Revision 1.5  2001/08/28 16:21:27  J80Lusk
# Add emacs coding: mode line.
#
# Revision 1.4  2001/08/22 15:53:44  J80Lusk
# Add #! line.
#
# Revision 1.3  2001/08/22 15:22:17  J80Lusk
# *** empty log message ***
#
