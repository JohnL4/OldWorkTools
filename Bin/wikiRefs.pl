#!/usr/bin/perl -w

=head1 NAME

wikiRefs.pl - Prints out nodes referred to by a wiki page, in Graphviz format

=head1 SYNOPSIS

 wikiRefs.pl [--undirected] *.txt > wikiRefs.txt
    
=head1 DESCRIPTION

Scans input files, printing to stdout the nodes referred to by the current
file.  Output format is "a -> b", where I<a> is the source file and I<b> is
the destination file.


=head1 AUTHOR

jlusk@a4healthsystems.com

=head2 VERSION

$Header: perl-template.pm, 1, 3/5/2002 7:00:51 PM, John Lusk$
    
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

                                # Regexp matching a (potential) WikiWord.
my $WW = "[A-Z]+[a-z]+[A-Z][A-Za-z0-9]*"; 

# ----------------------------------------------------------------------------
#  Static Methods
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
#  Main
# ----------------------------------------------------------------------------

my ($opt_undirected);

GetOptions( "undirected" => \$opt_undirected)
    or die $!;

my %printed;                    # Map from tuple to boolean indicating that
                                #   it's been printed already.
while (<>)
{
    /^\s*%META:/ && next;
    /\b$WW\b/o && do
    {
        s/<nop>$WW\b//go;       # Take out the nop'd WikiWords.
        s/[*_=]$WW[*_=]//go;    # Code and other WikiWords (e.g.,
                                #   =NonWikiWord=) 
        s/\#$WW//go;            # anchors in a wiki page are not WikiWords for
                                #   the purpose of this pgm.
        s/\b$WW\.[A-Za-z_]//go; # Remove unescaped WikiWords that appear to be
                                #   classnames followed by "." method name.
                                # Process all remaining matches (WikiWords)
        while (m/\b($WW)\b/go)
        {
            my $wikiWord = $1;
            if ($wikiWord !~ m/^$WW$/o)
            {
                next;
            }
            my $fnam;
            ($fnam = $ARGV) =~ s/\.txt$//;
            $fnam =~ s/-/_/g;   # Who's creating WikiWords with dashes in
                                #   them??? 
                                # Need to prevent printing twice?
            if ($fnam eq $wikiWord)
            {
                next;           # No self-edges.
            }
            my $edgnam;
            if ($opt_undirected)
            {
                $edgnam = join( " -- ", sort ($fnam, $wikiWord));
            }
            else
            {
                $edgnam = "$fnam -> $wikiWord";
            }
            if ($printed{ $edgnam})
            {
            }
            else
            {
                printf( "%s;\n", $edgnam);
                $printed{ $edgnam} = 1;
            }
        }
    };
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
