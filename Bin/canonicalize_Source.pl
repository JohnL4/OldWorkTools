#!/usr/bin/perl -w


=head1 NAME

canonicalize_Source.pl - Make the Canopy Source directory canonical in structure

=head1 SYNOPSIS

  cd /Work/Canopy/R5.0/CanopyIA/Source
  canonicalize_Source.pl

=head1 DESCRIPTION

Makes the current Canopy Source directory have a more standard (canonical)
structure, like other webapps Out There in the Wide, Wide World.  More
specifically, renames 'ui' to 'web' and moves the contained 'canopy'
directtory (containing Java source code) to a peer 'src' directory.

Also, moves files that should be in WEB-INF into 'web/WEB-INF' and moves
configs (such as canopy-log4j.xml) that need to be on the classpath to 'src'.

=head1 AUTHOR

john.lusk@allscripts.com

=head2 VERSION

$Header: v:/J80Lusk/CVSROOT/Tools/perl-template.pm,v 1.5 2001/08/28 16:21:27 J80Lusk Exp $
    
=head1 SEE ALSO

L<perl>.

=head1 TODO

=head1 PUBLIC METHODS

=over

=cut

use 5.006;
use strict;
use warnings;
use Carp;
use Getopt::Long;


# ----------------------------------------------------------------------------
#  Globals
# ----------------------------------------------------------------------------

                                # Source files that belong in web.xml.
my @WEB_INF_FILES = ( "canopy-faces.tld",
                      "faces-config.xml",
                      "jboss-web.xml",
                      "taglib.tld",
                      "web.xml"
                      );

                                # Source files that belong on the classpath.
my @CLASSPATH_FILES = ( "canopy-log4j.xml",
                        "FhcExceptionMessage.properties",
                        "HelpID.properties",
                        "version.properties"
                        );

# ----------------------------------------------------------------------------
#  Static Methods
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
#  Main
# ----------------------------------------------------------------------------

if ( ! -e "ui" or ! -e "canopy")
{
    die "Can find neither 'ui' nor 'canopy'; are you in the right directory?";
}

if (-e "web" or -e "src")
{
    die "'web' and/or 'src' already exist";
}

mkdir( "src")
    or die "mkdir( \"src\"): $!";
rename( "canopy", "src/canopy")
    or die "rename( \"canopy\", \"src/canopy\"): $!";
rename( "ui", "web")
    or die "rename( \"ui\", \"web\"): $!";
mkdir( "web/WEB-INF")
    or die "mkdir( \"web/WEB-INF\"): $!";

print( "Configuring WEB-INF by copying:\n");
foreach my $f (@WEB_INF_FILES)
{
    print( "\t$f\n");
    rename( $f, "web/WEB-INF")
        or carp "rename( $f, \"web/WEB-INF\"): $!";
}

print( "Configuring classpath by copying:\n");
foreach my $f (@CLASSPATH_FILES)
{
    print( "\t$f\n");
    rename( $f, "src")
        or carp "rename( $f, \"src\"): $!";
}


# ----------------------------------------------------------------------------
#  END
# ----------------------------------------------------------------------------

1;
__END__

=pod

=back

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
