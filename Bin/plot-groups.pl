#!/perl/bin/perl -w
                                # -*- coding: raw-text-dos -*-

=head1 NAME

plot-groups.pl -- Plot groups of data files together, to consolidate graphs

=head1 SYNOPSIS

    plot-groups.pl -n <filenameRE> <listOfDataFiles>

=head1 DESCRIPTION

Plots groups of 4 files from the given list on the same plot, "breaks" to a
new plot and plots 4 more, etc.

=head2 OPTIONS

=over

=item -f I<listOfDataFiles>

List of files to plot.  First word of each line will be used as the
filename.

=item -n I<filenameRE>

Specify a regular expression contain at least one subexpression.  It will be
used to match filenames and subexpression 1 will be used as the title of
the curve being plotted.

=back

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

my $PREAMBLE = <<'_EOF';

set format x '%H:%M'
set ytics nomirror
set y2tics
set grid xtics ytics
set xdata time
set timefmt '%m/%d/%Y %H:%M:%S'
set yrange [0:180]

set terminal gif size 400,300

_EOF
    
# ----------------------------------------------------------------------------
#  Static Methods
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
#  Main
# ----------------------------------------------------------------------------

my $i = 0;
my @files;

my $opt_titleRE = "(.*)";

GetOptions( "n=s" => \$opt_titleRE)
    or die "GetOptions: $!";

print $PREAMBLE;

while (<>)
{
    chomp;
    s/\r//;
    $i++;
    split( " ");
    push( @files, $_[0]);
    if ($i % 4 == 0)
    {
        my $plotcmd = "";
        foreach my $file (@files)
        {
            my $title;
            if ($file =~ m/$opt_titleRE/o)
            {                
                $title = $1;
            }
            else
            {
                warn "Filename ($file) doesn't match RE '$opt_titleRE'";
                $title = $file;
            }
            $plotcmd .= ($plotcmd ? ", " : "")
                . "'$file' using 1:3 title '$title' with linespoints";
        }
        $plotcmd = "set output 'group-" . ($i / 4) . ".gif'\n"
            . "plot $plotcmd\n";
        print $plotcmd;
        undef @files;
    }
}

# ----------------------------------------------------------------------------
#  END
# ----------------------------------------------------------------------------

__END__


# $Log: perl-template.pm,v $
