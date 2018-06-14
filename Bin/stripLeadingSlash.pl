#!/usr/bin/perl -w

=head1 NAME

stripLeadingSlash.pl -- Remove leading slashes from URLs in CanopyIA

=head1 SYNOPSIS

  stripLeadingSlash.pl

=head1 DESCRIPTION

Walks source code tree, stripping or otherwise transmogrifying leading slash
from URLs in JSPs.

=head1 AUTHOR

john.lusk@canopysystems.com

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

# use File::Glob qw(:globally :nocase); # Overrides global 'glob' behavior to be
                                #   case-insensitive. 
# use File::DosGlob 'glob';
# use File::Basename;
use File::Spec;

# ----------------------------------------------------------------------------
#  Globals
# ----------------------------------------------------------------------------

my $CANDIDATE_FILE_RE = "\.jspf?\$"; # Matches files to be considered for
                                #   munging. 
my $CANDIDATE_FILE_ORIG_RE = "\.jspf?\.orig\$";

# my $gb_fixed;                   # boolean indicating a line was fixed

my %gb_correctFilePath;         # Map from case-incorrect relative filepath to
                                #   correct filepath. 
my %gb_dirEntries;              # Map from relative dirpath to list of entries
                                #   for that dir.

# ----------------------------------------------------------------------------
#  Static Methods
# ----------------------------------------------------------------------------

# Return the case-corrected filename from the given dir.

sub correctFilename
{
    my ($aDirname,
        $aFilename,
        ) = @_;

    my $retval = $aFilename;
    my $dirname = ($aDirname || "."); # Force empty dirname to mean current
                                #   dir. 
    
    if ($aFilename)
    {
        if (! $gb_dirEntries{ $dirname})
        {
            my ($dh, @entries);
            opendir( $dh, $dirname) or croak "opendir( $dirname): $!";
            @entries = readdir( $dh);
            closedir( $dh) or warn "closedir( $dirname): $!";
            $gb_dirEntries{ $dirname} = \@entries;
        }
        my $entries = $gb_dirEntries{ $dirname};
        if ($entries)
        {
            foreach my $entry (@$entries)
            {
                if ($entry =~ m/^$aFilename$/i)
                {
                    $retval = $entry;
                    last;
                }
            }
        }
    }
    return $retval;
}

# Get the correct filepath for the given case-incorrect filepath.

sub getCaseCorrectDirEntry
{
    my ($aFilePath,
        ) = @_;

    my $retval = $gb_correctFilePath{ $aFilePath};
    if (! $retval)
    {
        my $no_file = (! -f $aFilePath);
        my ($vol, $dirname, $file) =
            File::Spec->splitpath( $aFilePath, $no_file);
        my @dirs = File::Spec->splitdir( $dirname);
        if (@dirs == 1)
        {
            $dirname = &correctFilename( ".", $dirname);
        }
        else
        {
            for (my $i = 0; $i < @dirs; $i++)
            {
                if ($dirs[$i])
                {
                    my $tmpdir =
                        &getCaseCorrectDirEntry( File::Spec->catdir( @dirs[0..$i]));
                    my @tmpdirs = File::Spec->splitdir( $tmpdir);
                    if ($tmpdirs[$i])
                    {
                        $dirs[$i] = $tmpdirs[$i];
                    }
                    else
                    {
                        warn "lost dir path component $i: $dirs[$i]";
                    }
                }
            }
        }
        $dirname = File::Spec->catdir( @dirs); # Dirname is now case-correct.
        $file = &correctFilename( $dirname, $file);
        $retval = File::Spec->catpath( $vol, $dirname, $file);
        $gb_correctFilePath{ $aFilePath} = $retval;
    }
    return $retval;
}

# Fix the case of the given URL, since URLs are really supposed to be
# case-sensitive and JBoss reflects that.

sub fixUrlCase
{
    my ($anUrl,
        ) = @_;
    my $retval = $anUrl;
    if ($gb_correctFilePath{ $anUrl})
    {
                                # Cached value exists
        $retval = $gb_correctFilePath{ $anUrl};
    }
    else
    {
                                # Determine case of given file as it exists on
                                # disk, and use that (and cache it).
        my $filePath = $anUrl;
        $filePath =~ s{^/}{};   # Make it "truly relative" by ripping
                                #   off any existing leading slash.
        if (-e $filePath)       # Relative to cur. working dir.
        {
            $retval = &getCaseCorrectDirEntry( $filePath);
        }
        else
        {
            undef $retval;
        }
        if ($retval && ($anUrl =~ m{^/}))
        {
                                # Restore leading slash.
            $retval = "/$retval";
        }
        if (! $retval)
        {
            $retval = $anUrl;   # Doesn't exist -- return as-is and hope for
                                #   the best. 
        }
        $gb_correctFilePath{ $anUrl} = $retval;
    }
    return $retval;
}

# Fix single line, setting $gb_fixed if anything actually happened.  Returns
# input line, fixed or not.

sub fixup
{
    my ($line,
        $aSlashReplacement,     # "" or "../" or "../../", etc.
        $aFixedFlag             # Ref to scalar
        ) = @_;

    my ($firstPart,             # First part of line
        $rest,                  # Rest of line
        );
    
    if ($line =~ m/<%@/)
    {
        if ($line =~ m{<%@\s*include\s+file=\"([^\"]+)\"\s*%>})
        {
            my $relativeFileUrl = $1;
            $relativeFileUrl = &fixUrlCase( $relativeFileUrl);
            $line = "<jsp:include page=\"$relativeFileUrl\"/>\r\n";
            $$aFixedFlag++;
        }
        # else, line is unchanged
    }
    else
    {
        ($line =~ s{
            ([\"\'])            # Leading quote
            (/)                 # Followed by "/"
            (
               [A-Za-z0-9_/]+\.  # Followed by alphanumerics and underscores,
                                #   with a trailing "."
               \b(jsp|js|gif|html)\b # Followed by any of these suffixes
            |
               servlet/         # (or leading "/" is followed by "servlet/")
            )}
            {$1$aSlashReplacement$3}gxi) # Substitution text
         && ($$aFixedFlag++);
        ($line =~ m{jsp:getProperty.*property=\"([A-Z])}) && do
        {
            my $prop1stLetter = $1;
            $prop1stLetter =~ tr/A-Z/a-z/;
            $line =~ s{(.*\bproperty=\")[A-Z](.*)}{$1$prop1stLetter$2};
            $$aFixedFlag++;
        };
#         ($line =~ m{(<jsp:getProperty\b.*\bproperty=\")([^\"])([^\"]*\".*)})
#             && do
#         {
#             my $prop1stLetter;
#             ($firstPart, $prop1stLetter, $rest) = ($1, $2, $3);
#             $prop1stLetter =~ tr/A-Z/a-z/;
#             $line = "$firstPart$prop1stLetter$rest";
#             chomp $line;
#             $line =~ s/\r//;
#             $line = "$line\r\n";
#             $$aFixedFlag++;
#         };
        ($line =~ m{(<jsp:useBean\b.*\bclass=\")([A-Za-z0-9_]+)(.*)}) && do
        {
            my $beanClass;
            ($firstPart, $beanClass, $rest) = ($1, $2, $3);
            ($beanClass =~ m/JavascriptVersionBean/)
                && ($beanClass = "canopy.utilities.$beanClass");
#            $line = "$firstPart$beanClass$rest";
            $line =~ s{(<jsp:useBean\b.*\bclass=\")([A-Za-z0-9_]+)}{$1$beanClass};
            chomp $line;
            $line =~ s/\r//;
            $line = "$line\r\n";
            $aFixedFlag++;
        };
    }    
    $line;                      # return value, I think.
}

# Process a single in a directory.

sub processFile
{
    my ($aDirName,
        $aDirEntry,
        $aRerunFlag,
        ) = @_;

    my $slashReplacement = "<%= request.getContextPath() %>/";

    my ($fh,                    # Filehandle
        $fhNew,                 # Filehandle for new file
        $fixed,                 # 0 ==> implies file was not fixed
        @flines,                # File lines.
        );

    my $entryPath = "$aDirName/$aDirEntry";
    if (($aRerunFlag && $aDirEntry =~ m{$CANDIDATE_FILE_ORIG_RE}o)
        || ($aRerunFlag && $aDirEntry =~ m{$CANDIDATE_FILE_RE}o
            && (! -e "$aDirName/$aDirEntry.orig"))
        || ((! $aRerunFlag) && $aDirEntry =~ m{$CANDIDATE_FILE_RE}o))
    {
        # printf( "%s\t", $aDirEntry);
        # printf( ".");
        open( $fh, "< $entryPath") or carp "open( $entryPath): $!";
        $fixed = 0;
        @flines = map { &fixup( $_, $slashReplacement, \$fixed) } <$fh>;
        close( $fh);
        if ($fixed)
        {
            printf( "!");
            if ($aRerunFlag)
            {
                # Remove previously-hacked version
                $entryPath =~ s/\.orig$//;
                unlink( $entryPath)
                    or die "unlink( $entryPath): $!";
            }
            else 
            {
                # Rename pristine original version before
                #   hacking it all up.
                rename( $entryPath, "$entryPath.orig")
                    or die "rename( $entryPath, $entryPath.orig): $!";
            }
            open( $fhNew, "> $entryPath")
                or die "open( \"> $entryPath\"): $!";
            print $fhNew @flines;
            close( $fhNew)
                or die "close(): $!";
        }
        else
        {
            printf( "-");
        }
    }
}

# Walk a directory, fixing up files.

sub walkDir
{
    my ($aDirName,
        $aRerunFlag,            # true ==> this is a re-run: operate on *.orig
                                #   files. 
        $aRecursionLevel
        ) = @_;

    my $dir;
    my $otherCount = 0;
    my ($fh, $fhNew);
    my $entryPath;
    my @flines;
    my $fixed;                  # boolean, true if file was fixed
    my $fixedFileCount = 0;
    # my $slashReplacement = "../" x $aRecursionLevel;
    
    # printf( "    walking %s -- ", $aDirName);
    opendir( $dir, $aDirName) or die $!;
    while (my $dirEntry = readdir( $dir))
    {
        $entryPath = "$aDirName/$dirEntry";
        (-f $entryPath) && do
        {
            &processFile( $aDirName, $dirEntry, $aRerunFlag);
            next;
        };

        ((-d $entryPath) && ($dirEntry !~ m/^\.\.?$/)) && do
        {
            printf( "\n%s/", "$entryPath");
            eval { &walkDir( "$entryPath", $aRerunFlag,
                             $aRecursionLevel + 1) };
            $@ && warn $@;
            next;
        };
                                # Don't know what this is, but it ain't a
                                # JSP.
        # printf( "?");
        $otherCount++;
    }
    closedir( $dir);
    printf( " (%d others)\n", $otherCount);
}
# ----------------------------------------------------------------------------
#  Main
# ----------------------------------------------------------------------------

my ($opt_rerun);
my $dir;

GetOptions( "rerun" => \$opt_rerun,
            )
    or die $!;

                                # Approach:
                                # Walk current dir, looking for files matching
                                #   pattern given by --match
                                # For each such file, make backup, scan file,
                                #   either removing leading slash from URLs or
                                #   replacing w/some call to
                                #   request.getContextPath(). 

if (! @ARGV)
{
    @ARGV = (".");
}
while (@ARGV)
{
    my $dirOrFile = shift @ARGV;
    if (-d $dirOrFile)
    {
        eval
        {
            &walkDir( $dirOrFile, $opt_rerun, 0);
        };
        $@ && carp $@;
    }
    elsif (-f $dirOrFile)
    {
        &processFile( ".", $dirOrFile, $opt_rerun);
        printf( "\n");
    }
    else
    {
        warn "Neither dir nor file: $dirOrFile";
    }
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



