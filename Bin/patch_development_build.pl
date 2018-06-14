#!/usr/bin/perl -w

=head1 NAME

patch_development_build.pl - Fix a development build after eclipse "clean"

=head1 SYNOPSIS

  patch_development_build.pl

=head1 DESCRIPTION

Copies extra files to development build required after Eclipse has cleaned
Canopy.

Requires environment variable CANOPY_BRANCH to be set to the release (StarTeam
branch) of Canopy being used.  Examples:  "R5.0" or "R5.0_SR10_MAINT_BRANCH". 

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

use File::Copy;

# ----------------------------------------------------------------------------
#  Globals
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
#  Main
# ----------------------------------------------------------------------------

my ($opt_a, $opt_b);

# GetOptions( "a=s" => \$opt_a,
#             "b=s" => \$opt_b)
#     or die $!;

&copyWebInfFiles();
&copyConfigDir();
&copyLibs();
&copyLog4J();

# ----------------------------------------------------------------------------
#  Static Methods
# ----------------------------------------------------------------------------

# Execute a system call and exhaustively study the return code.  Dies on any
# failure. 

sub doSystem
{
    my ($cmd) = @_;
    
    my $rc = system( $cmd);
    if ($rc == 0)
    {
        # success, do nothing
    }
    elsif ($rc == -1)
    {
        croak "system( \"$cmd\") failed to execute: $!";
    }
    elsif ($? & 127)
    {
        my $msg = sprintf( "system( \"%s\") child process died with signal %s, %s coredump",
                           $cmd,
                           ($rc & 127),
                           ($rc & 128) ? "with" : "without");
        croak $msg;
    }
    else
    {
        croak "system( \"$cmd\") exited with status " . ($rc >> 8);
    }
}

# Returns a list of names of all files in the given directory or dies.

sub dirFiles
{
    my ($aDir) = @_;
    my @retval;
    local *DIR;
    opendir( DIR, $aDir) or croak "opendir( DIR, \"$aDir\"): $!";
    @retval = readdir( DIR);
    closedir( DIR);
    return @retval;
}

# Copy J2EE standard config files that live in WEB-INF, such as
# canopy-faces.tld and faces-config.xml.

sub copyWebInfFiles
{
    my @filesToCopy = ("canopy-faces.tld", "faces-config.xml");
    
    my $srcDir = "/e/work/Canopy/$ENV{'CANOPY_BRANCH'}/CanopyIA/Source";
    my $destDir = "/JBoss/jboss-4.0.1/server/canopy/deploy/Canopy.war/WEB-INF";
    if (-e $destDir)
    {
        if ( ! -d $destDir)
        {
            die "$destDir exists, but is not a directory";
        }
    }
    else
    {
        mkdir( $destDir) or die "mkdir($destDir): $!";
    }
    foreach my $f (@filesToCopy)
    {
        eval
        {
            if ($f ne "." && $f ne "..")
            {
                printf( STDERR ".");
                if (-e "$destDir/$f")
                {
                    unlink( "$destDir/$f")
                        or die "unlink( \"$destDir/$f\"): $!";
                }
                copy( "$srcDir/$f",
                      "$destDir/$f")
                    or die "copy( \"$srcDir/$f\", \"$destDir/$f\"): $!";
            }
        };
        $@ && printf( STDERR "%s\n", $@);
    }
    printf( STDERR "\n");
}

# Copy Canopy 'config' directory from work area to deploy area.

sub copyConfigDir
{
    my $srcDir = "/e/work/Canopy/$ENV{'CANOPY_BRANCH'}/CanopyIA/Source/config";
    my $destDir = "/JBoss/jboss-4.0.1/server/canopy/deploy/Canopy.jar/config";
    if (-e $destDir)
    {
        if ( ! -d $destDir)
        {
            die "$destDir exists, but is not a directory";
        }
    }
    else
    {
        mkdir( $destDir) or die "mkdir($destDir): $!";
    }
    foreach my $f (&dirFiles( $srcDir))
    {
        eval
        {
            if ($f ne "." && $f ne "..")
            {
                printf( STDERR ".");
                if (-e "$destDir/$f")
                {
                    unlink( "$destDir/$f")
                        or die "unlink( \"$destDir/$f\"): $!";
                }
                copy( "$srcDir/$f",
                      "$destDir/$f")
                    or die "copy( \"$srcDir/$f\", \"$destDir/$f\"): $!";
            }
        };
        $@ && printf( STDERR "%s\n", $@);
    }
    printf( STDERR "\n");
}

# Copy COTS components from work area to deploy area.

sub copyLibs
{
    my $srcDir = "/e/work/Canopy/$ENV{'CANOPY_BRANCH'}/CanopyIA/COTS";
    my $destDir = "/JBoss/jboss-4.0.1/server/canopy/deploy/Canopy.jar/lib";
    if (-e $destDir)
    {
        if ( ! -d $destDir)
        {
            die "$destDir exists, but is not a directory";
        }
    }
    else
    {
        mkdir( $destDir) or die "mkdir($destDir): $!";
    }
    foreach my $subDir (&dirFiles( $srcDir))
    {
        eval
        {
            if ($subDir ne "."
                && $subDir ne ".."
                && -d "$srcDir/$subDir")
            {
                foreach my $lib (&dirFiles( "$srcDir/$subDir"))
                {
                    if ($lib =~ m/\.(jar|zip)$/i)
                    {
                        printf( STDERR ".");
                        if (-e "$destDir/$lib")
                        {
                            unlink( "$destDir/$lib")
                                or die "unlink( \"$destDir/$lib\"): $!";
                        }
                        copy( "$srcDir/$subDir/$lib",
                              "$destDir/$lib")
                            or die "copy( \"$srcDir/$subDir/$lib\", \"$destDir/$lib\"): $!";
                    }
                }
            }
        };
        $@ && printf( STDERR "%s\n", $@);
    }
    printf( STDERR "\n");
}

# Copy Canopy Log4J config from work area to deploy area.

sub copyLog4J
{
    my $src = "/e/work/Canopy/$ENV{'CANOPY_BRANCH'}/CanopyIA/Source/canopy-log4j.xml";
    my $destDir = "/JBoss/jboss-4.0.1/server/canopy/deploy/Canopy.jar";
    printf( STDERR ".");
    if (-e "$destDir/canopy-log4j.xml")
    {
        unlink( "$destDir/canopy-log4j.xml")
            or die "unlink( \"$destDir/canopy-log4j.xml\"): $!";
    }
    copy( $src, "$destDir/canopy-log4j.xml")
        or die "copy( \"$src\", \"$destDir/canopy-log4j.xml\"): $!";
    printf( STDERR "\n");
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
