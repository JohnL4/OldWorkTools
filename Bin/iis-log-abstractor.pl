#!/usr/bin/perl -w

# $Header: v:/J80Lusk/CVSROOT/Tools/Bin/iis-log-abstractor.pl,v 1.4 2005/03/28 18:37:59 j6l Exp $

use strict;
use Carp;
use Getopt::Long;
use File::Basename;

my $myname = basename( $0);

sub help
{
    print <<_EOF;

USAGE: $myname [--showActuateUser] --params <paramList> [<IIS-logfile>]
	[--showFields] [--inclFields <fieldnameList>]

   Prints timestamps, session ids and requested parameter values from
   the given IIS log.

   You might want to filter the IIS logs first with the following
   command:

       egrep -vi ' GET .*\.(js|gif|html|css|jpg)[ 	]'

   Once you have the IIS log filtered somewhat, try this command on
   the filtered log:

       $myname --inclFields time,cs-method,cs-uri-stem,sc-status,time-taken


OPTIONS:

   --showActuateUser
       		If true, will display Actuate user name cookie value
		(could be long).

   --showFields
       		Show all the fields (names) present in the log and
       		exit.

   --inclFields	Include the given fields (comma-delimited list, no
 		spaces) in the output.  You can use field names or
 		0-based indices.
_EOF
}

# --------------------------------------------------------------------
#  main
# --------------------------------------------------------------------

my $datestamp;
my $method;                     # get/post
my $url;
my $plainUrl;                   # url w/out query string
my $sessionid;                  # http cookie
my $actuateUserName;            # http request param (?) or cookie (?)

my $key;                        # http request param 
my @keys;                       # list of matches for "key=".  Should
                                #   be only one.  If there are more
                                #   than one, should all agree.
my $i;

my @field;                      # Fields of incoming line.

my $showActuateUserName;        # boolean
my $showFields;
my $inclFields;
my @inclFields;
my %inclField;                  # map from field name to column index
                                #   (0-based). 
my $inclField;
my $inclFieldDisplay;

my $userNeedsHelp;              # boolean

GetOptions( 
            "help" => \$userNeedsHelp,
            "showActuateUserName" => \$showActuateUserName,
            "showFields" => \$showFields,
            "inclFields=s" => \$inclFields
            ) || die $!;

if ($userNeedsHelp)
{
    help();
    exit 1;
}

if ($inclFields)
{
    @inclFields = split( /,/, $inclFields);
    foreach $inclField (@inclFields)
    {
        $inclField{ $inclField} = $inclField;
    }
    printf( "#Fields: %s\n", "jsessionid " . join( " ", @inclFields));
}

while (<>)
{
    chomp;
    @field = split;
    if ($showFields)
    {
        /^\#Fields:/ && do
        {
            for ($i = 1; $i < @field; $i++)
            {
                printf( "\t%d: %s\n", ($i - 1), $field[ $i]);
            }
            last;
        };
    }
    if ($inclFields)
    {
        /^\#Fields:/ && do
        {
            for ($i = 1; $i < @field; $i++)
            {
                if ($inclField{ $field[ $i]})
                {
                    $inclField{ $field[ $i]} = ($i - 1);
                }
            }
        };
    }

    /^#/ && next;               # Skip comments (presumaby in the log
                                #   header). 
    /^\s*$/ && next;            # Skip blank lines.
    
                                # not --showFields
    
    $url = $actuateUserName = $key = $sessionid = "";

    /jsessionid=(\d*)/i && ($sessionid = $1);
    /ActuateUsername=([^;]*)/ && ($actuateUserName = $1);

    $inclFieldDisplay = "";
    if ($inclFields)
    {
        foreach $inclField (@inclFields)
        {
            $inclFieldDisplay .= ($inclFieldDisplay ? "\t" : "")
                . $field[ $inclField{ $inclField}];
        }
    }

    printf( "%s", $sessionid);

    if ($showActuateUserName)
    {
        printf( "\t%-15s", $actuateUserName);
    }

    if ($inclFields)
    {
        printf( "\t");
        printf( "%s", $inclFieldDisplay);
    }

    printf( "\n");
}
