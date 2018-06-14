#!perl -w
 
# $Header: v:/J80Lusk/CVSROOT/Tools/Bin/parseSSHistory.pl,v 1.7 2005/03/28 18:38:03 j6l Exp $

# Parse stuff of the following format:
#
# *****  UserRoleDesc.java  *****
# Version 14
# User: J49dennis     Date:  4/18/00   Time:  7:17a
# Checked in $/Canopy/Releases/Latest/Source/canopy/usermanagement
# Comment:   * 04/18/2000  jd              Added getAll and getList methods as
# proxies to DM Peer Methods

# local 
#     $parsingNewEntryData,       # boolean, true if we're parsing new
#                                 #   entry data.
#     $filename,
#     $version,
#     $actingUsername,
#     $actionDate, $actionTime,
#     $comment, $commentLine;

format =
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @>>>>>>> @>>>>> @>>>>>>>>>>>>>>>>>>>>>
$filename, $actionDate, $actionTime, $actingUsername

~~	^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$action
~~	^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$comment

.

while (<>)
{
    # printf( STDERR "\> %s", $_);
    /^\*+  (.*)  \*+$/ && do {
        $newFilename = $1;
        $parsingFileEntry = 1;
        if ($filename)
        {
            write;
        }
        $filename = $newFilename;
        # print( "----  New file: $filename\n");
        $version = "";
        $comment = "";
        $actingUsername = "";
        $actionDate = "";
        $actionTime = "";
        next;
    };
    /^\*+\s*$/ && do {
                                # "Label" entry.
        $parsingFileEntry = 0;
        next;
    };
    $parsingFileEntry && /^Version ([0-9]+)/ && do {
        $version = $1;
        next;
    };
    $parsingFileEntry && /^User:\s+(\S+)\s+Date:\s+(\S+)\s+Time:\s+(\S+)/ && 
    do {
        $actingUsername = $1;
        $actionDate = $2;
        $actionTime = $3;
        next;
    };
    /^Checked in / && do {
        $action = "";
        next;
    };
    /^(\S+) (added|deleted|recovered)\s*$/ && do {
        $action = "$2 $1";
        # printf( STDERR "action = \"%s\"", $action);
        next;
    };
                                # Add other action lines here.
    /^Labeled\s*$/ && next;
    /^Label comment:\s*$/ && next;
    $parsingFileEntry && do {
        ($commentLine = $_) =~ s/^(Comment:)?(\*|\s)*//;
        $comment .= $commentLine;
        next;
    };
                                # Swallow expected non-data lines.
    /^Building list for \$|^\.*$|^\s*$/ && next;
    
                                # Complain about unexpected non-data lines.
    {
        printf( STDERR "WARNING: unparsed line: %s", $_);
    }
}
if ($filename)
{
    write;
}

print( "Done.\n");
