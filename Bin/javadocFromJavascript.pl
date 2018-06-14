#!/perl/bin/perl -w
                                # -*- coding: raw-text-dos -*-

=head1 NAME

javadocFromJavascript -- Extract javadoc-like docs from javascript files

=head1 SYNOPSIS

 javadocFromJavascript [-o <html-output>] <dir>

=head1 DESCRIPTION

This script extract Javadoc-like documentation from a group of Javascript
files, constructing an HTML document.

For each JS file (*.js) in the directory, the first block of javadoc comments
(beginning with "/**" and ending with "*/") will be associated with the
filename of the JS file.  All such javadoc will be emitted to the HTML
file, in alphabetical order of associated JS file.

Blank lines will delimit paragraphs.

Lines starting with "@" must come after all other text, and will be placed in
their own paragraph, preceded by their @-keyword, one per line.

=head1 AUTHOR

john.lusk@canopysystems.com

=head2 VERSION

$Header: v:/J80Lusk/CVSROOT/Tools/perl-template.pm,v 1.5 2001/08/28 16:21:27 J80Lusk Exp $
    
=head1 SEE ALSO

L<perl>.

=head1 TODO

Process subdirectories, recursively, leaving an HTML file in each subdirectory.

Process individual functions in each JS file, extracting "javadoc" to the html output.

=head1 IMPLEMENTATION NOTES

=over
    
=cut

use 5.006;
use strict;
use warnings;
use Carp;
use Getopt::Long;

use DirHandle;
use FileHandle;

# ----------------------------------------------------------------------------
#  Globals
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
#  Static Methods
# ----------------------------------------------------------------------------

=item fileComments

Returns file-level comments (first "/**"-style comment).

=cut

sub fileComments
{
    my ($dir, $file) = @_;
    my $fh = FileHandle->new( "< $dir/$file")
        or die "FileHandle->new( \"< $dir/$file\"): $!";
    my $scanningComment = 0;
    my $sawCommentEnd = 0;
    my $comments = "";
    my $atBreak = "P";          # paragraph break before first @-tag
    while (<$fh>)
    {
        m=^\s*/\*\*= && ($scanningComment = 1);
        $scanningComment && do
        {
            $sawCommentEnd = ($_ =~ m=\*/=);
            s=/\*\*\**==;       # /**
            s=\**\*/==;         # **/
            s=^\s*\*==;         # leading *
            s=^(\s*)@=$1<${atBreak}>@= # P or BR before "@"
                and $atBreak = "BR/";
            $comments .= $_;
            if ($sawCommentEnd)
            {
                last;
            }
        };
    }
    $fh->close();
                                # If @-tags opened a new paragraph, close it.
    return $comments . ($atBreak eq "BR/" ? "</P>" : "");
}

=item printIndexOpener

Prints, to STDOUT, opening text of index document.  For an HTML doc, this is
the HEAD, STYLE and BODY opener.

=cut

sub printIndexOpener
{
    my ($aDir,                  # Directory that was scanned
        $aFileComments)         # Mapping from filenames to file comments.
        = @_;
    
    my @today = localtime();
    my $today = sprintf( "%4d/%02d/%02d %02d:%02d",
                         $today[5]+1900, # yr
                         $today[4]+1, # mon
                         $today[3], # mday
                         $today[2], # hr
                         $today[1] # min
                         );

    my $docOpener = <<EOF;
<html>
<head>
<title>JavaScript Docs, $aDir, $today</title>
<style>
    \@import "javascript-doc.css";
</style>
</head>
<body>
<H1>JavaScript Docs, $aDir, $today</H1>
EOF
    print( $docOpener);
}

=item printTOC

    Prints table of contents in body of doc.

=cut
    
sub printTOC
{
    my ($aDir,                  # Directory that was scanned
        $aFileComments)         # Mapping from filenames to file comments.
        = @_;

    my $filename;
    my $fnLength = 0;           # filename length
    my @filenames = sort keys %$aFileComments;
    foreach $filename (@filenames)
    {
        if ($fnLength < length( $filename))
        {
            $fnLength = length( $filename);
        }
    }
    my $nCols = int( 100 / $fnLength);
    my $nRows = @filenames / $nCols;
    if ($nRows != int( $nRows))
    {
        $nRows = int( $nRows) + 1;
    }
    print( "<table cellpadding=\"4\" cellspacing=\"4\">\n");
    for (my $row = 0; $row < $nRows; $row++)
    {
        print( "\t<tr>\n");
        for (my $col = 0;
             $col < $nCols
             && ($row + $col * $nRows) < @filenames;
             $col++)
        {
            my $fnLink = &filenameLink( $filenames[ $row + $col * $nRows]);
            print( "\t\t<td>$fnLink</td>\n");
        }
        print( "\t</tr>\n");
    }
    print( "</table>\n");
}

=item printTOCWithOneLiners

Prints TOC, accompanying each entry w/the first sentence of its comments.

=cut
    
sub printTOCWithOneLiners
{
    my ($aDir,                  # Directory that was scanned
        $aFileComments)         # Mapping from filenames to file comments.
        = @_;

    my @filenames = sort keys %$aFileComments;

    print( "<table rules=\"rows\" border=\"1\" cellpadding=\"4\" cellspacing=\"4\">\n");
    foreach my $file (@filenames)
    {
        printf( "\t<tr valign=\"baseline\"><td>%s</td>	<td>%s</td></tr>\n",
                &filenameLink( $file),
                &firstSentence( $aFileComments->{$file}));
    }
    print( "</table>\n");
}

=item firstSentence

Returns the first sentence (text up to ending punctuation) of the given
string.

=cut
    
sub firstSentence
{
    my ($commentBlock) = @_;

    if ($commentBlock =~ m/[.!?]\s/g) # Use 'g' to set pos()
    {
        printf( STDERR "Sentence ends at %d.\n", pos( $commentBlock));
        return substr( $commentBlock, 0, pos( $commentBlock) - 1);
    }
    else
    {
        printf( STDERR "No sentence-ender found in comment block.\n");
        return $commentBlock;
    }
}

=item printIndexCloser

Prints closing text of index doc.  In HTML, this is the BODY closer.

=cut
    
sub printIndexCloser
{
    print( "</body></html>\n");
}

=item filenameLink

Renders filename as a link to an anchor in the same document.

=cut

sub filenameLink
{
    my ($filename) = @_;

    return "<a href=\"#$filename\">$filename</a>";
}

=item filenameAnchor

Renders filename as an anchor in the document for reference by
&filenameLink().

=cut

sub filenameAnchor
{
    my ($filename) = @_;
    
    return "<a name=\"$filename\">$filename</a>";
}

=item printEntry

Prints a single entry.

=cut

sub printEntry
{
    my ($anEntry, $aComments) = @_;
    
    printf( "\n<H3>%s</H3>\n\n%s\n",
            &filenameAnchor( $anEntry), $aComments);
}

=item processDir

Processes a single directory of Javascript files, extracting comments into a
hash.

=cut

sub processDir
{
    my ($dir, $html) = @_;

    my $dirEntry;
    my %fileComments;           # Map from filename to comments for file
                                #   (raw).                    
    
    printf( STDERR "Opening dir \"$dir\"...\n");
    my $dh = DirHandle->new( "$dir")
        || die "DirHandle->new( \"$dir\"): $!";
    while ($dirEntry = $dh->read())
    {
        if ($dirEntry =~ m/\.js$/i)
        {
            $fileComments{ $dirEntry} = &fileComments( $dir, $dirEntry);
        }
    }

    &printIndexOpener( $dir, \%fileComments);
    print( "\n<H2>Contents</H2>\n\n");
    &printTOCWithOneLiners( $dir, \%fileComments);
    print( "\n<H2>Files</H2>\n\n");
    foreach $dirEntry (sort keys %fileComments)
    {
        &printEntry( $dirEntry, $fileComments{ $dirEntry});
    }
    &printIndexCloser();
}

# ----------------------------------------------------------------------------
#  Main
# ----------------------------------------------------------------------------

my ($opt_o);

GetOptions( "o=s" => \$opt_o
            )
    or die $!;

my $dir = $ARGV[0]; shift @ARGV;

my $html = $opt_o || "index.html";

&processDir( $dir, $html);

# ----------------------------------------------------------------------------
#  END
# ----------------------------------------------------------------------------

1;
__END__

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
