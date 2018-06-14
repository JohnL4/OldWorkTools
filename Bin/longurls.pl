#!/perl/bin/perl -w
                                # -*- coding: raw-text-dos -*-

=head1 NAME

longurls.pl - display urls that are longer than 256 chars

=head1 SYNOPSIS

 longurls.pl [<IISlogfile>]

 egrep '#Fields|jsessionid=' ex011206.log | ./longurls.pl |\
    awk '{print $2}' | sort | uniq

=head1 DESCRIPTION

Lists all urls that are too long (> 256 chars).  Output format is input
filename, uri stem, complete uri (all separated by tabs).

=head1 AUTHOR

john.lusk@canopysystems.com

=head2 VERSION

$Header: v:/J80Lusk/CVSROOT/Tools/Bin/longurls.pl,v 1.2 2001/12/13 19:32:25 J80Lusk Exp $
    
=head1 SEE ALSO

L<perl>.

=head1 TODO


=cut

use 5.006;
use strict;
use warnings;
use Carp;
use Getopt::Long;

use WebServer::Log::Entry;

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

while (<>)
{
    chomp;
    s/\r$//;                    # cygwin
    /^\#Fields:/ && WebServer::Log::Entry->setFieldNames( $_);
    /^\#/ && next;            # comments
    /^\s*$/ && next;          # blank lines

    my $entry = WebServer::Log::Entry->new( $_);
    if (length( $entry->getUri()) >= 256)
    {
        printf( "%s\t%s\t%s\n", $ARGV, $entry->getUriStem(),
                $entry->getUri());
    }
}

# ----------------------------------------------------------------------------
#  END
# ----------------------------------------------------------------------------

1;
__END__

=pod


=cut

# $Log: longurls.pl,v $
# Revision 1.2  2001/12/13 19:32:25  J80Lusk
# MINOR
#
# Revision 1.1  2001/12/13 19:31:53  J80Lusk
# Initial version.
