#!perl -w

# $Header: v:/J80Lusk/CVSROOT/Tools/Bin/log-monitor.pl,v 1.1 2001/09/04 15:55:32 J80Lusk Exp $

use strict;
use Carp;
use IO::File;
use File::Basename;
use Getopt::Long;
use Time::localtime;

my( $myname) = basename( $0);

sub help
{
    print <<_EOF;

Usage: $myname [-f <logfilename>] [-o <decoratedLogfilename>]

Options

    -f <logfilename>
        	Monitor the given file.  If not specified, monitor
        	stdin.
                            
    -o <decoratedLogfilename>
        	Write timestamp-decorated lines of logfile to
        	decoratedLogfile.  If not specified, write to stdout.
_EOF
}

sub timestamp
{
    my $time = localtime();
    return sprintf( "%04d-%02d-%02d %02d:%02d:%02d",
                    ($time->year + 1900), ($time->mon + 1), $time->mday,
                    $time->hour, $time->min, $time->sec);
}

# --------------------------------------------------------------------
#  main
# --------------------------------------------------------------------

{
    my $logfile;
    my $decoratedLogfile;
    my $datestamp;
    my $logfilename;
    my $decoratedLogfilename;
    my %optctl = ( "f" => \$logfilename,
                   "o" => \$decoratedLogfilename);
    
    GetOptions( \%optctl, "f=s", "o=s") || die $!;

    if (! $logfilename) { $logfilename = "-"; }
    if (! $decoratedLogfilename) { $decoratedLogfilename = "-"; }
    
    $logfile = IO::File->new( "< $logfilename")
        || die "$! ($logfilename)";
    $decoratedLogfile = IO::File->new( "> $decoratedLogfilename")
        || die "$! ($decoratedLogfilename)";
    $decoratedLogfile->autoflush();
    
    for(;;) { # wait for interrupt
        
        while (<$logfile>)
        {
            chomp;
            $decoratedLogfile->printf( "%s : %s\n", timestamp(), $_);
        }

        sleep(1);
        $logfile->seek(0, 1);
    }
    
    $logfile          = undef;
    $decoratedLogfile = undef;
}


