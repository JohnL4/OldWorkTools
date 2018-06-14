#!/perl/bin/perl -w

=head1 NAME

userTransaction_iisFilter.pl - Filter IIS log using a config file.

=head1 SYNOPSIS

    userTransaction_iisFilter.pl [-h] [-i I<IGNORE_FILE>] [I<IIS_LOG>]

=head1 DESCRIPTION

Filters lines not representing user transactions out of the IIS log.

=head2 PARAMETERS

=over

=item -h

This help.
    
=item -i I<IGNORE_FILE>

Specifies other egrep(1) regular expressions (one per line) to be
ignored.  File may contain comments (#) and blank lines.

=back

=head1 AUTHOR

john.lusk@canopysystems.org

=head2 VERSION

$Header: v:/J80Lusk/CVSROOT/Tools/Bin/userTransactions_iisFilter.pl,v 1.5 2001/08/28 13:43:38 J80Lusk Exp $
    
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
#  Subroutines
# ----------------------------------------------------------------------------

# Build an egrep regexp consisting of a bunch of alternatives.

sub extraRegexp
{
    my( $ignoreFilename) = @_;
    local( *REGEXPS);

    open( REGEXPS, "< $ignoreFilename")
        or die "Couldn't open \"$ignoreFilename\": $!";
    my $retval = "";
    while (<REGEXPS>)
    {
        /^\s*\#/ && next;       # comments
        /^\s*$/ && next;        # blank lines
        chomp;
        $retval .= ($retval ? "|" : "") . $_;
    }
    return $retval;
}

# ----------------------------------------------------------------------------
#  Main
# ----------------------------------------------------------------------------

my $userNeedsHelp;
my ($ignoreFilename, $iisLogname);

GetOptions( "h" => \$userNeedsHelp,
            "i=s" => \$ignoreFilename)
    or die $!;

if ($userNeedsHelp)
{
    system( "pod2text $0");
    exit 1;
}

if (@ARGV)
{
    $iisLogname = $ARGV[0];
}

my $cmd = "";

if ($iisLogname)
{
    $cmd .= "cat \"$iisLogname\" | ";
}

$cmd .= "egrep -vi \" GET .*\.(js|gif|html|css|jpg)[ 	]\" | ";
$cmd .= "egrep -vi \" GET / \" | ";
$cmd .= "egrep -vi \" - -\$\" | ";
$cmd .= "egrep -vi \" GET /ios_benchmark/\" ";

if ($ignoreFilename)
{
                                # NOT case-insensitive.
    $cmd .= "| egrep -v \"" . extraRegexp( $ignoreFilename) . "\"";
}

print STDERR "Execing \"$cmd\"\n";
if (system( $cmd) == -1)
{
    die "Couldn't exec \"$cmd\": $!";
}

# ----------------------------------------------------------------------------
#  END
# ----------------------------------------------------------------------------

__END__

# $Log: userTransactions_iisFilter.pl,v $
# Revision 1.5  2001/08/28 13:43:38  J80Lusk
# Add auditPrettifier to archive, since it's part of the userTransactions
# system.  Add online help to filter.  Minor correction to userTransactions
# help.
#
# Revision 1.4  2001/08/23 13:47:35  J80Lusk
# Total conversion to perl from bash script.  Based on
# userTransactions_iisFilter.sh.
#
# Revision 1.3  2001/08/22 15:22:17  J80Lusk
# *** empty log message ***
#
