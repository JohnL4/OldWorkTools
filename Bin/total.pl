#!/usr/bin/perl -w
                                # -*- coding: raw-text-dos -*-


=head1 NAME

total.pl -- Print total value of input file values

=head1 SYNOPSIS

    total.pl -c <n> [-d <delimiter>] [<file>]

=head1 DESCRIPTION

=head2 OPTIONS

=over

=item -c I<n>

Column number (1-based) to use as numeric values for computing total.

=item -d I<delimiter>

Delimiter to use in separating columns.  Default is space.

=back

=head1 AUTHOR

john.lusk@canopysystems.com

=head2 VERSION

$Header: v:/J80Lusk/CVSROOT/Tools/Bin/total.pl,v 1.5 2005/03/28 18:38:07 j6l Exp $
    
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

sub total
{
    my( $data) = @_;            # ref to list

    my $sum = 0;
    map( { $sum += $_ } @$data);
    return $sum;
}

# ----------------------------------------------------------------------------
#  Main
# ----------------------------------------------------------------------------

my ($opt_colNum, $opt_delim);

GetOptions( "c=i" => \$opt_colNum,
            "d=s" => \$opt_delim)
    or die $!;

($opt_colNum <= 0) && die "Must specify column number";

if ( ! defined( $opt_delim))
{
    $opt_delim = "[ \t]*";
}

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
        printf( "%s\t%g\n", $filename, &total( \@data));
        undef @data;
        $filename = $ARGV;
    }
    @cols = split( /$opt_delim/o, $_);
    push( @data, $cols[ $opt_colNum - 1]);
}

printf( "%s\t%g\n", $filename, &total( \@data));


# ----------------------------------------------------------------------------
#  END
# ----------------------------------------------------------------------------

__END__

# $Log: total.pl,v $
# Revision 1.5  2005/03/28 18:38:07  j6l
# General-purpose commit, just catching things up before adding summatch.pl.
#
# Revision 1.4  2003/02/14 19:09:15  J80Lusk
# *** empty log message ***
#
# Revision 1.3  2001/12/10 19:41:40  J80Lusk
# Number in 7-column field (right-justified), like wc outputs.
#
# Revision 1.2  2001/12/10 19:39:52  J80Lusk
# Switch order of output to:  number, file
# (vs. file, number).
#
# Revision 1.1  2001/12/10 19:24:14  J80Lusk
# Initial version, based on median.pl.
#
# Revision 1.1  2001/11/11 01:44:56  J80Lusk
# Initial version.
#
