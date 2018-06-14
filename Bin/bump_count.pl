#!/usr/bin/perl -w

=head1 NAME

bump_count.pl - Bumps a counter up/down depending on line substring matches
   and writes the updated count on the line in question

=head1 SYNOPSIS

  bump_count.pl --up <regexp> --down <regexp> [--column <n>] [<file>]

=head1 DESCRIPTION

For every line, maintain a counter, initialized at 0.  If the "up" regexp
occurs, the counter is incremented; if the "down" regexp occurs, the counter
is decremented.  (Both may occur, in which case the net is no change,
obviously.)

The counter value is written in the specified column.


=head1 AUTHOR

john.lusk@allscripts.com

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
#  Static Methods
# ----------------------------------------------------------------------------


# ----------------------------------------------------------------------------
#  Main
# ----------------------------------------------------------------------------

my ($opt_up, $opt_down, $opt_col);

GetOptions( "up=s" => \$opt_up,
            "down=s" => \$opt_down,
            "column=i" => \$opt_col)
    or die $!;

my $counter = 0;
my $maxCounter = 0;

while (<>)
{
    chomp;
    s/\r//;
    my @fields = split;
    /$opt_up/o && $counter++;
    /$opt_down/o && $counter--;
    my @outfields = (@fields[ 0..$opt_col - 1],
                     $counter,
                     @fields[ $opt_col ..  scalar( @fields) - 1]);
    print( join( " ", @outfields) . "\n");
    if ($maxCounter < $counter)
    {
        $maxCounter = $counter;
    }
}
print( STDERR "maxCounter = $maxCounter\n");

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
