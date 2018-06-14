#!perl -w

# ----------------------------------------------------------------------------
#  NOTE:  USE Tools/perl-template.pm INSTEAD
# ----------------------------------------------------------------------------
    
use strict;
use warnings;
use Carp;

use File::Basename;
use Pod::Text;
use IO::File;
use IO::Seekable;
use File::Temp;
use Getopt::Long;

# --------------------------------------------------------------------
#  globals
# --------------------------------------------------------------------

my $myname = basename( $0);
my $version = "\$Header: v:/J80Lusk/CVSROOT/Tools/Bin/template.pl,v 1.2 2001/08/22 15:20:23 J80Lusk Exp $";
                                # " fool emacs

# --------------------------------------------------------------------
#  help
# --------------------------------------------------------------------

sub help()
                                # TODO: Consider investigating pod2usage.
{
    my $pod = <<"_EOF";

=head1 SYNOPSIS
    $myname - Generate diffs between files in two directory hierarchies

=head1 USAGE
    $myname <old-dir> <new-dir>

=head1 DESCRIPTION
    Recursively traverses old-dir, comparing all files found w/the
    matching file in new-dir.  Generated diffs are left in the old-dir
    tree.

=head1 OPTIONS/PARAMETERS
    <old-dir>, <new-dir>
        
=head1 VERSION
    $version
        
=head1 SEE ALSO
    
=cut
_EOF

                                # write above string to temp file,
                                #   parse, unlink 
    
    my( $podfile, $podfilename) = File::Temp::tempfile();
    if (! defined( $podfile))
    {
        warn "tempfile(): $!";
    }
    printf( $podfile $pod);
    close( $podfile)
        || warn "close( \$podfile): $!";
    open( POD, "< $podfilename")
        || warn "open( \"< $podfilename\"): $!";
    my $podParser = Pod::Text->new();
    print( "\n");
    $podParser->parse_from_filehandle( \*POD);
    close( POD)
        || warn "close( POD): $!";
    unlink( $podfilename)
        || warn "unlink( $podfilename): $!";
}

# --------------------------------------------------------------------
#  main
# --------------------------------------------------------------------

my( $opt_help
    );

GetOptions( "help|h" => \$opt_help
            ) || ($opt_help = 1);

if (! @ARGV || $opt_help)
{
    help();
    exit 1;
}

# ----------------------------------------------------------------------------
#  END
# ----------------------------------------------------------------------------

__END__

# $Log: template.pl,v $
# Revision 1.2  2001/08/22 15:20:23  J80Lusk
# *** empty log message ***
#
