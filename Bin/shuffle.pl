#!/usr/bin/perl -w
                                # -*- coding: raw-text-dos -*-

=head1 NAME

shuffle.pl - Shuffle a line-oriented file like a deck of cards

=head1 SYNOPSIS

   shuffle.pl filename.txt > filename.shuffled.txt

=head1 DESCRIPTION

Slurps in all lines of the input file and rewrites them in random order.
    
=head1 AUTHOR

john.lusk@canopysystems.com, based on a suggestion from joey.carr@canopysystems.com.

=head2 VERSION

$Header:perl-template.pm, 1, 3/5/2002 7:00:51 PM, John Lusk$
    
=head1 SEE ALSO

L<perl>.

=head1 TODO


=cut

use 5.006;
use strict;
use warnings;
use Carp;
use Getopt::Long;
use POSIX;

# ----------------------------------------------------------------------------
#  Globals
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
#  Static Methods
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
#  Main
# ----------------------------------------------------------------------------

# my ($opt_a, $opt_b);
# 
# GetOptions( "a=s" => \$opt_a,
#             "b=s" => \$opt_b)
#     or die $!;

my @filelines = <>;
my $i;

while (@filelines)
{
    $i = POSIX::floor( rand scalar( @filelines));
    printf( "%s", $filelines[$i]);
    @filelines = @filelines[ 0..($i-1), ($i+1)..(scalar( @filelines) - 1) ];
}

# ----------------------------------------------------------------------------
#  END
# ----------------------------------------------------------------------------

1;
__END__

=pod


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
