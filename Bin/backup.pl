#!/usr/bin/perl -w
                                # -*- coding: raw-text-dos -*-

=head1 NAME

backup -- Back up (and compress) work files to a network drive

=head1 SYNOPSIS

 backup [-v] [-c <configFile>] [--namesOnly] [--[no]age]

=head1 DESCRIPTION

Uses a complex specification to scan one or more directory trees, creating a
single archive file containing the specified files to be backed up.  In the
backup destination, removes backup archives older than a specified age.

=head2 OPTIONS

=item --[no]age

Remove "old" backup archives after creating the new one.  The definition of
"old" can be by count (too many) or by age (written too long ago).  The
default is to age old archive.

=item -c I<configFile>

The config file to be used.  Default is ~/.backuprc.xml.

=item --namesOnly

Only print out the names of the files to be backed up, don't actually archive
them.  (Not implemented.)

=item -v

Verbose.

=head2 CONFIG-FILE SYNTAX

I wish I could put a schema down here, but I don't have time right now.

    <!DOCTYPE zipfile SYSTEM "/usr/local/etc/backup.dtd">

or [the following may be out of date; consult the above DTD]
    
    <!DOCTYPE zipfile
    [
     <!-- regexp is a perl regular expression delimited by "/" -->
     <!ENTITY %regexp "CDATA">

     <!ELEMENT zipfile (topdir)*>
     <!ELEMENT topdir (dir | file)*>
     <!ELEMENT dir (dir | file)*>
     <!ELEMENT file EMPTY>

     <!-- maxCount and maxAge must be non-negative integers -->
     <!ATTLIST zipfile
         namebase    CDATA                   #REQUIRED
         type        ( full | incremental )  #FIXED full
         maxCount    CDATA                   #REQUIRED
         maxAge      CDATA                   #IMPLIED
     >
     <!ATTLIST topdir
         name        CDATA                   #REQUIRED
     >
     <!ATTLIST dir
         name        %regexp;                #REQUIRED
     >
     <!ATTLIST file
         name        %regexp;                #REQUIRED
         op          ( include | exclude )   #REQUIRED
     >

    ]>
    
In English:  top element (document) is a "zipfile", containing zero or more
"topdir" elts.  Each "topdir" contains zero or more "file" and "dir"
elts.  Similarly, each "dir" contains zero or more "file" and "dir" elts.
These elements are used to lay out rules about which files to include or
exclude from the backup.  Once specified, a rule applies to an entire
subtree of the directory hierarchy unless countermanded by another rule.

(Quick note on regular expressions:  These are perl regular expressions, and
you must use "/" as the delimiter (this is so the script can perform a simple
syntax check for those folks who don't live and breathe perl regexps).  Each
regular expression must begin with "/" and must have exactly two "/"s in it.
Examples:

 /.*/  -- match everything
 /a/i  -- match everything containing an "a", case-insensitive
 /^A$/ -- match exactly that thing named "A" (not "a" and not "XAX").
 
)

Element attributes:

=over 4

=item elt "zipfile"

=over 4
    
=item namebase

The name base for the generated archive.  A timestamp will be
appended to the namebase to make the final filename.
    
=item type

"incremental" or "full" (only full is implemented now); the type
of backup to take.
    
=item maxCount

The max. number of archive files that should exist after the
latest one is generated.  All others will be deleted.
    
=item maxAge

(Not implemented.)  The max. age in days any archive file should have
after the latest one is generated.  All others will be deleted.

=back
    
=item elt "topdir"

=over 4
    
=item name

Path name to the top of the directory tree to be backed up.  This path will be
preserved in the archive, so you might not want to make it absolute.
However, if you make it relative, you must run this script in a directory
that will allow the relative path to work properly (see the example).

=back
    
=item elt "dir"

=over 4
    
=item name

A regular expression.  All directories found below the topdir and any
intervening dirs will have the file-matching rules contained in this dir
elt applied.
    
=back
    
=item elt "file"

=over 4
    
=item name

A regular expression matching filenames.  Use "/.*/" to match all files in
(and below) a directory.

=item op

"include" or "exclude".  Files matching this element will be included or
excluded from backup.  If multiple "file" elts match a given disk file, the
last matching rule will determine the fate of the file.  This allows you to
set general rules and specific exceptions.

=back
    
=back

=head2 COMPLETE CONFIG-FILE EXAMPLE

  <zipfile namebase="v:/j80lusk/WorkstationBackup/Work/CanopyIA/R3.0-"
      type="full"
      maxCount="2"
      >
                                  <!-- cwd must be c:/work -->
    <topdir name="CanopyIA/R3.0/Source">

      <file op="exclude" name="/.*\.class$/i"/>
      <file op="exclude" name="/.*\.jar$/i"/>
      <file op="exclude" name="/.*\.zip$/i"/>
      <file op="exclude" name="/~$/i"/>
      <file op="exclude" name="/.*\.gif$/i"/>
      <file op="exclude" name="/.*\.jpg$/i"/>

      <file op="exclude" name="/.*\.cab$/i"/>
      <file op="exclude" name="/.*\.dat$/i"/>
      <file op="exclude" name="/.*\.dfPackage$/i"/>
      <file op="exclude" name="/.*\.dll$/i"/>
      <file op="exclude" name="/.*\.scc$/i"/>

      <dir name="/^JavadocUpdate$/i">
        <file op="exclude" name="/.*/"/>
      </dir>
      <dir name="/^ui$/i">
        <dir name="/^(help|images)$/i">
          <file op="exclude" name="/.*/"/>
        </dir>
      </dir>

    </topdir>
  </zipfile>

=head1 AUTHOR

john.lusk@canopysystems.com

=head2 VERSION

$Header: v:/J80Lusk/CVSROOT/Tools/Bin/backup.pl,v 1.8 2002/05/18 17:53:30 J80Lusk Exp $
    
=head1 SEE ALSO

L<perl>.

=head1 TODO


=cut
                                # ' fool emacs font-lock
    
use 5.006;
use strict;
use warnings;
use Carp;
use Getopt::Long;
use XML::Parser;
use File::Basename;
use File::Spec;
use File::Temp qw/tempfile/;
use DirHandle;
use POSIX;

# ----------------------------------------------------------------------------
#  Globals
# ----------------------------------------------------------------------------

my $myname = basename( $0);
my $gb_indentLevel = 0;
my $gb_indentIncr = 2;          # Number of spaces to add at each indent
                                #   level.
my $gb_goodSyntax = 1;          # Syntax of user-written XML config file is
                                #   good or bad.
my $gb_curEltString;            # Element string sans trailing ">" for current
                                #   elt.  Built by &startElt, used by
                                #   &endElt.
my $gb_backupSpecTree;          # Root of tree of spec nodes (a DIR node).
                                #   First node is special null dir node
                                #   corresponding ot the ZIPFILE config file
                                #   element.
my $gb_backupSpecNode;          # Cursor into tree.

# Spec node structure:
# { NODETYPE => "dir"
#   REGEXP => string
#   PARENT_DIR => ref to a DIR node
#   FILES => list ref
#   SUBDIRS => list ref
# }
#    
#  { NODETYPE => "file"
#    REGEXP => regexp
#    PARENT_DIR => ref to a DIR node
#    OP => incl|excl
#  }

my ($gb_incl_fh, $gb_incl_filename); # File handle to temp. file of included
                                     #   file names.  

my $gb_opt_verbose = 0;

# ----------------------------------------------------------------------------
#  XML handlers
# ----------------------------------------------------------------------------

# Return true iff the given dir or file regexp has good syntax.

sub hasGoodSyntax
{
    my ($re) = @_;
    my @slashes = ($re =~ m|/|g);
    return ( ($re =~ m|^/|)
             and (@slashes == 2));
}

sub startDoc
{
#     print "START_DOC\n";
}

sub endDoc
{
#     print "END_DOC\n";
}

sub startElt
{
    my ($expat, $elt, %attrVal) = @_;
    if ($gb_curEltString)
    {
        $gb_opt_verbose and print "$gb_curEltString>\n";
        undef $gb_curEltString;
    }
    my $eltString = (" " x ($gb_indentIncr * $gb_indentLevel++)) . "<$elt";
    while (my ($attr, $val) = each( %attrVal))
    {
        $eltString .= " $attr=\"$val\"";
    }
    $gb_curEltString = $eltString;

    if (! $gb_backupSpecTree)
    {
        ($elt eq "zipfile") or die;
        $gb_backupSpecNode = $gb_backupSpecTree
            = { NODETYPE => "zipfile",
                NAMEBASE => $attrVal{ "namebase"},
                TYPE     => $attrVal{ "type"},
                MAXCOUNT => $attrVal{ "maxCount"},
                MAXAGE   => $attrVal{ "maxAge"}
            };
        if ($gb_backupSpecTree->{TYPE}
            && $gb_backupSpecTree->{TYPE} ne "full")
        {
            warn "Only full backups implemented";
        }
        if (defined( $gb_backupSpecTree->{MAXAGE}))
        {
            warn "Aging of archives not implemented";
        }
    }
    elsif ($elt eq "topdir")
    {
        my $newNode
            = { NODETYPE   => "topdir",
                WORKINGDIR => $attrVal{ "workingDir"},
                NAME       => $attrVal{ "name"},
                PARENT_DIR => $gb_backupSpecNode };

        push( @{$gb_backupSpecNode->{SUBDIRS}}, $newNode);
        $gb_backupSpecNode = $newNode;
        if ($gb_backupSpecNode->{WORKINGDIR})
        {
            warn "topdir workingDir not implemented";
        }
    }
    elsif ($elt eq "dir")
    {
        if (! &hasGoodSyntax( $attrVal{ "name"}))
        {
            $gb_goodSyntax = 0;
            $expat->xpcarp( $attrVal{ "name"} . " has bad syntax");
        }
        my $newNode
            = { NODETYPE   => "dir",
                REGEXP     => $attrVal{ "name"},
                PARENT_DIR => $gb_backupSpecNode };
        push( @{$gb_backupSpecNode->{SUBDIRS}}, $newNode);
        $gb_backupSpecNode = $newNode;
    }
    elsif ($elt eq "file")
    {
        if (! &hasGoodSyntax( $attrVal{ "name"}))
        {
            $gb_goodSyntax = 0;
            $expat->xpcarp( $attrVal{ "name"} . " has bad syntax");
        }
        my $newNode
            = { NODETYPE   => "file",
                REGEXP     => $attrVal{ "name"},
                PARENT_DIR => $gb_backupSpecNode,
                OP         => $attrVal{ "op"} };
        push( @{$gb_backupSpecNode->{FILES}}, $newNode);
    }
    else
    {
        $expat->xpcarp( "Unrecognized element type '$elt'");
    }
}

sub endElt
{
    my ($expat, $elt) = @_;
    if ($gb_curEltString)
    {
        $gb_opt_verbose and print "$gb_curEltString/>\n";
        $gb_indentLevel--;
        undef $gb_curEltString;
    }
    else
    {
        my $eltString = (" " x ($gb_indentIncr * --$gb_indentLevel))
            . "</$elt>";
        $gb_opt_verbose and print "$eltString\n";
    }

    if ($elt eq "dir" or $elt eq "topdir")
    {
        $gb_backupSpecNode = $gb_backupSpecNode->{PARENT_DIR};
    }
}

sub char
{
    my ($expat, $string) = @_;
    if ($string !~ m/^\s*$/)
    {
        $gb_opt_verbose and print "CHAR: '$string'\n";
        $expat->xpcarp( "Unexpected characters: '$string'");
    }
}

sub comment
{
    $gb_opt_verbose and print "COMMENT\n";
}

sub doctype
{
    $gb_opt_verbose and print "DOCTYPE\n";
}

sub default
{
    my ($expat, $string) = @_;
    if ($string !~ m/^\s*$/)
    {
        $gb_opt_verbose and print "DEFAULT: '$string'\n";
        $expat->xpcarp( "Unhandled: '$string'");
    }
}

# ----------------------------------------------------------------------------
#  Functions
# ----------------------------------------------------------------------------

# Decide whether or not to include file, on the basis of the spec-node tree.
#
# $filename -- string or ref to list of path components (topdir, dir, dir,
#     filename). 
# $specNodeTree -- ref to "topdir" spec-node

sub includeFile
{
                                # Algorithm:  walk down the filepath, looking
                                # for matches in the sparse spec tree.  Upon
                                # finding a matching directory, compare the
                                # matching filespecs in the dir of the spec
                                # tree to determine status (and advance the
                                # spec tree cursor).  Continue until all
                                # dir elements of the filepath are exhausted.

    my ($filepath, $specNodeTree) = @_;
    my $retval = 1;             # Files are included by default (after all,
                                #   this is a backup program).
    my @pathDirs;
    my $pathDir;
    if (ref $filepath eq "ARRAY")
    {
        @pathDirs = @$filepath;
    }
    else
    {
        @pathDirs = split( /[\/\\]/, $filepath);
    }
    my $filename = pop @pathDirs;
    my $dirSpecNode = $specNodeTree;
    $dirSpecNode->{NODETYPE} eq "topdir" or die "starting node isn't a topdir";

                                # Don't attempt to match dir specs against
                                # topdir name -- we're already there.
    if (@pathDirs and $pathDirs[0] eq $dirSpecNode->{NAME})
    {
        # carp "Ignoring top dir '$pathDirs[0]'";
        shift @pathDirs;
    }
    do
    {{                          # Doubled brace so 'next' will work.
                                # Scan filespecs in current dir spec node.
        
                                # All matching node specs
        my @fileSpecNodes = grep( { my $re = $_->{REGEXP};
                                    eval "'$filename' =~ m$re" }
                                  @{$dirSpecNode->{FILES}});
        my $lastFileSpecNode = pop @fileSpecNodes;
        if ($lastFileSpecNode)
        {
            if ($lastFileSpecNode->{OP} eq "include")
            {
                $retval = 1;
            }
            elsif ($lastFileSpecNode->{OP} eq "exclude")
            {
                $retval = 0;
            }
            else
            {
                warn "Unexpected OP: '$lastFileSpecNode->{OP}'";
            }
        }

                                # Try to advance the spec tree cursor.

        $pathDir = shift @pathDirs;
        if (defined( $pathDir))
        {
            my @dirSpecNodes = grep( { my $re = $_->{REGEXP};
                                       eval "'$pathDir' =~ m$re" }
                                     @{$dirSpecNode->{SUBDIRS}});
            if (! @dirSpecNodes)
            {
                next;
            }
            elsif (@dirSpecNodes > 1)
            {
                warn "'$pathDir' matches multiple dir-specs: "
                    . join( ", ", map( { $_->{REGEXP} } @dirSpecNodes))
                        . "; using last spec";
            }
            $dirSpecNode = pop @dirSpecNodes;
        }
    }} while ($pathDir);        # Stop AFTER we've tried to shift a directory
                                #   off an empty list.
    return $retval;
}

# Configure this program from an XML config file.

sub configure
{
    my ($configFile) = @_;

    my $parser = XML::Parser->new( Style => 'Stream',
                                   Handlers => {
                                       Init    => \&startDoc,
                                       Final   => \&endDoc,
                                       Start   => \&startElt,
                                       End     => \&endElt,
                                       Char    => \&char,
                                       Comment => \&comment,
                                       Doctype => \&doctype,
                                       Default => \&default
                                       });
    $parser->parsefile( $configFile);
}

# Dump the tree, for debugging.

sub dumpTreeNode
{
    my ($node, $indentLevel) = @_;
    print( " " x ($gb_indentIncr * $indentLevel),
           "----------------\n");
    foreach my $field (sort( keys( %$node)))
    {
        print( " " x ($gb_indentIncr * $indentLevel),
               $field, " => ",
               (ref $node->{$field} eq "ARRAY"
                ? "(" . join( ", ", map( { $_->{REGEXP} or $_->{NAME} }
                                         @{$node->{$field}})) . ")"
                : $node->{$field}),
               "\n");
    }
    map( { &dumpTreeNode( $_, $indentLevel + 1) }
         @{$node->{FILES}});
    map( { &dumpTreeNode( $_, $indentLevel + 1) }
         @{$node->{SUBDIRS}});
}

# Recursively scan a single directory for files to be considered for backup.
#
# $dirname -- Name of directory to be scanned
# $topdirNode -- Spec node of top directory (where scan started)
# $namesOnly -- Boolean, if true, only print out names of files to be included
#     in backup.
# $dirPath -- List of directories scanned so far.

sub scanDir
{
    my ($aDirName, $aTopdirNode, $aNamesOnly, $aDirPath) = @_;

    my @filePath = @$aDirPath;
    if ($aDirName ne ".")
    {
        push( @filePath, $aDirName);
    }
    my $dirPath = join( "/", @$aDirPath, $aDirName);
    my $cwd = `pwd`;
    chomp $cwd;
    $cwd =~ s/\r$//;            # for cygwin
    $cwd =~ s{^/cygdrive/(.)/}{$1:/};
    $gb_opt_verbose and print "cwd: $cwd\n";
    my $dh = DirHandle->new( ".")
        or die "DirHandle->new(.): $!";
    my $entry;
    while ($entry = $dh->read())
    {
        # print "> $dirPath/$entry\n";
        my $entryPath = join( "/", @filePath, $entry);
        if (-f $entry)
        {
            push( @filePath, $entry);
            if (&includeFile( \@filePath, $aTopdirNode))
            {
                $gb_opt_verbose and print( "\tinclude\t$entryPath\n");
                printf( $gb_incl_fh "$aTopdirNode->{NAME}/$entryPath\n");
            }
            else
            {
                $gb_opt_verbose and print( "\tEXCLUDE\t$entryPath\n");
            }
            pop( @filePath);
        }
        elsif (-d $entry)
        {
            if ($entry =~ m/^\.\.?$/)
            {
                $gb_opt_verbose and print( "\tskip\t$entryPath\n");
            }
            else
            {
                $gb_opt_verbose and print( "\tdir\t$entryPath\n");
                chdir( $entry) or die "chdir($entry): $!";
                &scanDir( $entry, $aTopdirNode, $aNamesOnly, \@filePath);
                chdir( "..") or die "chdir(\"..\"): $!";
            }
        }
        else
        {
            printf( STDERR "\tUNKNOWN\t$entryPath\n");
        }
    }
    chdir( $cwd) or die "chdir($cwd): $!";
    $dh->close();
}

# Scan the configuration-specified directory tree(s) (on the filesystem).
# Creates temp file $gb_incl_filename (must be deleted eventually).

sub scan
{
    my ($namesOnly, $specNodeTree) = @_;

    ($gb_incl_fh, $gb_incl_filename)
        = tempfile( "backup-ziplist-XXXX", DIR => File::Spec->tmpdir);
    $gb_opt_verbose and print( "temp. filename = $gb_incl_filename\n");
    my @dirNodes = @{$specNodeTree->{SUBDIRS}}; # List of dirs to scan.

    my $cwd = `pwd`;
    chomp $cwd;
    $cwd =~ s/\r$//;            # for cygwin
    $cwd =~ s{^/cygdrive/(.)/}{$1:/};

    foreach my $dirNode (@dirNodes)
    {
        my $topDirPath
            = "" # ($dirNode->{WORKINGDIR} ? "$dirNode->{WORKINGDIR}/" : "")
                . $dirNode->{NAME};
        print "Backing up $topDirPath\n";
        chdir( $topDirPath) or do
        {
            carp "cwd = $cwd; chdir($topDirPath): $!";
            next;
        };
        &scanDir( ".", $dirNode, $namesOnly, []);
        chdir( $cwd) or die "chdir($cwd): $!";
    }
    $gb_incl_fh->close();
}

# Figure out what to name the zip file

sub zipfileName
{
    my $zipfileName = $gb_backupSpecTree->{NAMEBASE};
    $zipfileName .= POSIX::strftime( "%Y%m%d-%H%M%S", localtime());
    if (-e "$zipfileName.tar.bz2")
    {
        my $i = 1;
        my $trialZipfileName;
        do {
            $trialZipfileName = sprintf( "%s-%02d", $zipfileName, $i);
        } until (! -e "$trialZipfileName.tar.bz2");
        $zipfileName = $trialZipfileName;
    }
    return "$zipfileName.tar.bz2";
}

# Glob template matching zipfile names generated by &zipfileName().

sub zipfileGlobTemplate
{
    my ($basename) = @_;
    return $basename . "[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]*.tar.bz2";
}

# Zip up the contents of $gb_incl_filename.

sub zip
{
    # my $cmd = "cat $gb_incl_filename | zip -9 " . &zipfileName() . " -\@";
    my $zipfileName = &zipfileName();
    my $tarVerbosity = ($gb_opt_verbose ? "-v" : ""); # --checkpoint (less
                                                      # verbose)
    my $shVerbosity = ($gb_opt_verbose ? "-x" : "");
    my $script = <<EOF;
#!/bin/sh

inclfile=`cygpath --unix '$gb_incl_filename'`
zipfile=`cygpath --unix '$zipfileName'`
mkdir -p `dirname \$zipfile`
tar --create $tarVerbosity --files-from \$inclfile | bzip2 -9 > \$zipfile
EOF
    $gb_opt_verbose
        and print( "----------------\n${script}----------------\n");
    my ($tempScript_fh, $tempScript_name);
    ($tempScript_fh, $tempScript_name)
        = tempfile( "backup-script-XXXX", SUFFIX => ".sh",
                    DIR => File::Spec->tmpdir);
    printf( $tempScript_fh $script);
    $tempScript_fh->close();
    my $cmd = "sh $shVerbosity $tempScript_name";
    $gb_opt_verbose and print( "$cmd\n");
    my $rc = system( $cmd);
    if ($rc == -1)
    {
        carp "system($cmd): $!";
    }
    elsif ($rc != 0)
    {
        carp( "system($cmd) exit status: " . ($? >> 8));
    }
    unlink( $tempScript_name) || carp "unlink($tempScript_name): $!";
}

# Delete older archives.

sub pruneOldArchives
{
    my $namebase = &zipfileGlobTemplate( $gb_backupSpecTree->{NAMEBASE});
    my @archives = sort {$a cmp $b} glob( $namebase);
    $gb_opt_verbose
        and print "Glob \"$namebase\" yields:\n\t" . join( "\n\t", @archives)
            . "\n";
    @archives = @archives[0..(@archives - 1 - $gb_backupSpecTree->{MAXCOUNT})];
    $gb_opt_verbose
        and print "Removing: \n\t" . join( "\n\t", @archives) . "\n";
    unlink @archives;
}

# ----------------------------------------------------------------------------
#  Main
# ----------------------------------------------------------------------------

my $configFile = "~/.backuprc.xml";

my $opt_c;
my $opt_namesOnly = 0;
my $opt_age = 1;                # Age out old archive by default.

GetOptions( "age!" => \$opt_age,
            "c=s" => \$opt_c,
            "namesOnly=s" => \$opt_namesOnly,
            "v" => \$gb_opt_verbose
            )
    or die $!;

if ($opt_namesOnly)
{
    warn "--namesOnly not implemented";
}

&configure( $opt_c);
$gb_goodSyntax or die "XML config file has bad syntax";
$gb_opt_verbose and &dumpTreeNode( $gb_backupSpecTree, 0);
&scan( $opt_namesOnly, $gb_backupSpecTree);
&zip();

if ($opt_age)
{
    &pruneOldArchives();
}

unlink( $gb_incl_filename) || carp "unlink($gb_incl_filename): $!";

print "$myname: Done.\n";

# ----------------------------------------------------------------------------
#  END
# ----------------------------------------------------------------------------

1;
__END__


# $Log: backup.pl,v $
# Revision 1.8  2002/05/18 17:53:30  J80Lusk
# DTD.
# Guard against null backup type.
# Add handler for doctype (does nothing, suppresses complaint about
#    unexpectedness).
#
# Revision 1.7  2002/04/15 21:42:25  J80Lusk
# zipfile glob template
# carp on no-directory-to-backup, instead of dying
#
# Revision 1.6  2001/12/06 14:58:50  J80Lusk
# Add docs.
#
# Revision 1.5  2001/12/06 00:44:20  J80Lusk
# Attempt to get workingDir working, failed.
#
# Revision 1.4  2001/12/06 00:31:17  J80Lusk
# Archive aging.
#
# Revision 1.3  2001/12/05 23:44:28  J80Lusk
# *** empty log message ***
#
# Revision 1.2  2001/12/05 21:37:54  J80Lusk
# Works, mostly.
#
# Revision 1.1  2001/12/05 17:59:26  J80Lusk
# Initial version.
#
