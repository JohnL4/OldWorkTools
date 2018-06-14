#!/perl/bin/perl -w
                                # -*- coding: raw-text-dos -*-


=head1 NAME

exprand.pl -- exponential random number distribution from uniform distribution

=head1 SYNOPSIS

    exprand.pl -n <n> [-9 <x> | -5 <x>]

=head1 DESCRIPTION

Generate a string of random numbers having exponential distribution.


=head1 AUTHOR

john.lusk@canopysystems.com, after
http://icfa3d.web.cern.ch/ICFA3D/3D/html2/node151.html#SECTION038220210000000000000.

=head2 VERSION

$Header: v:/J80Lusk/CVSROOT/Tools/Bin/exprand.pl,v 1.1 2001/12/13 21:35:43 J80Lusk Exp $
    
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


# ----------------------------------------------------------------------------
#  Main
# ----------------------------------------------------------------------------

my ($opt_n);
my ($opt_5, $opt_9);

GetOptions( "n=i" => \$opt_n,
            "5=f" => \$opt_5,
            "9=f" => \$opt_9)
    or die $!;

if ($opt_5 and $opt_9)
{
    die "Can't specify both -5 and -9";
}

my $a = 1;
if ($opt_5)
{
    $a = 0.693/$opt_5;
}
elsif ($opt_9)
{
    $a = 2.3/$opt_9;
}

for (my $i = 0; $i < $opt_n; $i++)
{
    my $u = rand;               # uniformly-distributed random var.
    my $r = - log(1-$u)/$a;     # r: rand number in the dist. we want
                                #   (exponential). 
    printf( "%g\n", $r);
}

# Discussion:
#
# (Based on http://www.mathcs.duq.edu/larget/math496/random2.html)
#
# If u is a random number from a uniform distribution over the interval [0,1),
# then f(u) = - log( 1 - u) is a random number from the exponential
# distribution over the interval [0, infinity).  The cumulative probability
# density function for f is F(x) = 1 - e^(-x).
#
# At what x do we have 50% and 90% probability (i.e., what value will we be
# below 50% and 90% of the time?  Let t be the threshold we seek.).
#
#     t = 1 - e^(-x)
#     t-1 = -e^(-x)
#     1-t = e^(-x)
#     log(1-t) = -x
#     -log(1-t) = x        -log(1-.5) = 0.693      -log(1-.9) = 2.30
#
# How can we pick a different number to be below 50% and 90% of the time? If
# f(u) = -log(1-u)/a, the cdf is F(x) = 1-e^(-ax)
#
#     t = 1 - e^(-ax)
#     t-1 = -e^(-ax)
#     1-t = e^(-ax)
#     log(1-t) = -ax
#     -log(1-t) = ax
#     -log(1-t)/a = x      .693/a = x              2.30/a = x
#
# Suppose we want to be below 100 90% of the time.
#
#     2.3/a = 100
#     2.3/100 = a          a = .0023
#
#     f(u) = -log(1-u)/.0023


# ----------------------------------------------------------------------------
#  END
# ----------------------------------------------------------------------------

1;
__END__

=pod

=cut

# $Log: exprand.pl,v $
# Revision 1.1  2001/12/13 21:35:43  J80Lusk
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
