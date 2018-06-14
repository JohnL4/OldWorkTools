#!/perl/bin/perl -w

# $Header: v:/J80Lusk/CVSROOT/Tools/Bin/tzplay.pl,v 1.2 2001/08/27 23:02:07 J80Lusk Exp $

# This script started life as a sandbox hack to learn about timezones and time
# conversion in perl.  I have noticed that ActiveState and Cygwin perls handle
# timezones differently, so run this script under the perl of your choice to
# see how they behave.

use POSIX;

print "\$ENV{ TZ} = ", (defined( $ENV{ TZ}) ? $ENV{ TZ} : "(undef)"), "\n";
if ($ENV{ TZ})
{
    print "\t(Try running this program w/out that env. var.)\n";
}
print "Before calling tzset(), timezones are:\n\t",
    join( ", ", POSIX::tzname()), "\n";
print "2001-8-23 6:00 a.m. --> ", POSIX::mktime( 0, 0, 6, 23, 7, 101), "\n";

POSIX::tzset();
print "After calling tzset(), timezones are:\n\t",
    join( ", ", POSIX::tzname()), "\n";
print "2001-8-23 6:00 a.m. --> ", POSIX::mktime( 0, 0, 6, 23, 7, 101), "\n";
print "\n";

print "Your timezone's mktime() offset from GMT, in January and July:\n";
$epochJan = mktime( 0, 0, 0, 2, 0, 70); # Jan 2nd
$epochJul = mktime( 0, 0, 0, 2, 6, 70); # Jul 2nd
@epochJul = localtime( $epochJul);
if ($epochJul[ @epochJul - 1])
{
                                # Remake, correcting for DST.
    $epochJul = mktime( 0, 0, 0, 2, 6, 70, 0, 0, 1);
}
@epochJan = gmtime( $epochJan);
@epochJul = gmtime( $epochJul);

$offsetJan = $epochJan[0] + 60 * $epochJan[1] + 3600 * $epochJan[2]
    + 24 * 3600 * ($epochJan[3] - 2);
$offsetJul = $epochJul[0] + 60 * $epochJul[1] + 3600 * $epochJul[2]
    + 24 * 3600 * ($epochJul[3] - 2);

print "\tepochJan = $epochJan\n";
print "\tepochJul = $epochJul\n";
print "\tgmtime( \$epochJan)\t--> ", join( ", ", @epochJan), "\n";
print "\tgmtime( \$epochJul)\t--> ", join( ", ", @epochJul), "\n";
print "\toffsetJan = $offsetJan\n";
print "\toffsetJul = $offsetJul\n";


print "\nlast elt returned by localtime(),gmtime() is \"isdst\" flag.\n";

$lastJanHardcoded = 978346800;
print "lastJanHardcoded = $lastJanHardcoded\n";
print "\tlocaltime( \$lastJanHardcoded)\t--> ", join( ", ", localtime( $lastJanHardcoded)), "\n";
print "\tgmtime( \$lastJanHardcoded)\t--> ", join( ", ", gmtime( $lastJanHardcoded)), "\n";


$now = time;
print "now = $now\n";

print "\tlocaltime( \$now)\t--> ", join( ", ", localtime( $now)), "\n";
print "\tgmtime( \$now)\t--> ", join( ", ", gmtime( $now)), "\n";

$lastJul = mktime( 0, 0, 6, 1, 6, 101, 0, 0, 1);
print "lastJul = $lastJul\n";
print "\tlocaltime( \$lastJul)\t--> ", join( ", ", localtime( $lastJul)), "\n";
print "\tgmtime( \$lastJul)\t--> ", join( ", ", gmtime( $lastJul)), "\n";

$old_tz = $ENV{TZ};
if (! (defined( $old_tz) and $old_tz eq "CST6CDT"))
{
    $ENV{ TZ} = "CST6CDT";
    POSIX::tzset();
    print "old TZ was ", (defined( $old_tz) ? $old_tz : "(undef)"),
    " new TZ is $ENV{ TZ}\n";
    print "\tlocaltime( \$lastJul)\t--> ", join( ", ", localtime( $lastJul)), "\n";
    print "\tgmtime( \$lastJul)\t--> ", join( ", ", gmtime( $lastJul)), "\n";

    $lastJulNewTZ = mktime( 0, 0, 6, 1, 6, 101, 0, 0, 1);
    print "lastJulNewTZ = $lastJulNewTZ\n";
    if ($lastJulNewTZ == $lastJul)
    {
        print <<EOF;
        
	WARNING:  attempt to change timezones via POSIX::tzset() apparently
	NOT EFFECTIVE. 

EOF
    }
    else
    {
        print <<EOF;

	NOTE:  attempt to change timezones via POSIX::tzset() apparently seems
	to work.

EOF
    }
    print "\tlocaltime( \$lastJulNewTZ)\t--> ", join( ", ", localtime( $lastJulNewTZ)), "\n";
    print "\tgmtime( \$lastJulNewTZ)\t--> ", join( ", ", gmtime( $lastJulNewTZ)), "\n";
}
if (defined( $old_tz))
{
    $ENV{ TZ} = $old_tz;
}
else
{
    delete $ENV{ TZ};
}
POSIX::tzset();

$lastJan = mktime( 0, 0, 6, 1, 0, 101);
print "lastJan = $lastJan\n";
print "\tlocaltime( \$lastJan)\t--> ", join( ", ", localtime( $lastJan)), "\n";
print "\tgmtime( \$lastJan)\t--> ", join( ", ", gmtime( $lastJan)), "\n";

$lastJanBad = mktime( 0, 0, 6, 1, 0, 101, 0, 0, 1);
print "lastJanBad = $lastJanBad\n";
print "\t(I claimed it was daylight time when I made this timestamp)\n";
print "\tlocaltime( \$lastJanBad)\t--> ", join( ", ", localtime( $lastJanBad)), "\n";
print "\tgmtime( \$lastJanBad)\t--> ", join( ", ", gmtime( $lastJanBad)), "\n";
print "lastJan - lastJanBad = ", $lastJan - $lastJanBad, "\n";

print "\n";

print <<EOF;

	Interesting notes re mktime():

        The "isdst" flag passed to it is informational -- it specifies whether
	figures passed in are the true time or whether the figures represent a
	"false time" resulting from the adjustment due to daylight savings
	time ("summer time").  Once the time has been constructed, it can be
	queried to see if it was during DST, regardless of how it was
	constructed (probably unless it indicated an hour that couldn't exist,
	like 2:30 a.m. on the day of the "spring forward", in which case I
	don't know what will happen).

        The timezone appears to be set only once, when the program starts
        running (POSIX::tzset() seems to be a no-op).  This *seems* to be an
        ActiveState perl bug, since the Cygwin perl doesn't have this
        behavior.

EOF
                                # ' # fool emacs

__END__

# $Log: tzplay.pl,v $
# Revision 1.2  2001/08/27 23:02:07  J80Lusk
# *** empty log message ***
#
# Revision 1.1  2001/08/23 19:21:11  J80Lusk
# Initial version.
#
    
