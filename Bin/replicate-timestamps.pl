#!/usr/bin/perl -w

=head1 NAME

replicate-timestamps.pl - copy timestamp from a line to all following lines
    that don't have a timestamp

=head1 SYNOPSIS

  replicate-timestamps.pl

=head1 DESCRIPTION

Finds timestamp on a line (beginning of line) and, for every following line
that doesn't have a timestamp at the beginning, prints that line preceded by
previously-found timestamp.

After this, the output can be used with timeFilter.pl.


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

my ($opt_a, $opt_b);

GetOptions( "a=s" => \$opt_a,
            "b=s" => \$opt_b)
    or die $!;

my $prevTimestamp;

while (<>)
{
    chomp;
    s/\r//;
    my @fields = split;
    my $line = $_;
    if ($_ =~ m/^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d/ or # YYYY-MM-DD HH:MM:SS
        $_ =~ m/^\d\d\/\d\d\/\d\d\d\d \d\d:\d\d:\d\d/) # MM/DD/YYYY HH:MM:SS
    {
        $prevTimestamp = $fields[0] . " " . $fields[1];
    }
    elsif ($prevTimestamp)
    {
        $line = $prevTimestamp . " " . $line;
    }
    print( "$line\n");
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
