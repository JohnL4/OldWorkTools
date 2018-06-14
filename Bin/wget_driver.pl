#!/perl/bin/perl -w
                                # -*- coding: raw-text-dos -*-

=head1 NAME

wget_driver.pl -- Drive simple url fetches for stress testing

=head1 SYNOPSIS

 wget_driver.pl -s <sessionid> -f <paramFile> [--offset <fraction>] -u <url>

=head1 DESCRIPTION

For each row of I<paramFile>, interpolate I<url> w/fields from the file (CSV)
and submit the url as a GET request w/cookie 'jsessionid' having the given
I<sessionid>.

I<url> may contain occurrences of "$col[I<n>]", when I<n> is the 0-based
column of the data from I<paramFile> to be interpolated in.

If --offset I<fraction> is given ([0.0 ... 1.0]), the data will be pulled
starting at the indicated offset of the file (0 ==> beginning, 1 ==>
end). 

=head1 AUTHOR

john.lusk@canopysystems.com

=head2 VERSION

$Header: v:/J80Lusk/CVSROOT/Tools/Bin/wget_driver.pl,v 1.2 2001/09/25 18:21:35 J80Lusk Exp $
    
=head1 SEE ALSO

L<perl>.

=head1 TODO


=cut

use 5.006;
use strict;
use warnings;
use Carp;
use Getopt::Long;

use FileHandle;

# ----------------------------------------------------------------------------
#  Globals
# ----------------------------------------------------------------------------


# ----------------------------------------------------------------------------
#  Main
# ----------------------------------------------------------------------------

my ($opt_sessionId, $opt_paramFile, $opt_url, $opt_offset);

GetOptions( "s=s" => \$opt_sessionId,
            "f=s" => \$opt_paramFile,
            "u=s" => \$opt_url,
            "off|offset=f" => \$opt_offset)
    or die $!;

if (! $opt_url)
{
    system( "pod2text $0");
    exit 1;
}

my $fh = FileHandle->new( "< $opt_paramFile")
    or die "new FileHandle( $opt_paramFile): $!";

my @params = <$fh>;
chomp @params;

$fh->close();

my $i;
my $count;

if (defined( $opt_offset))
{
    $i = $opt_offset * scalar( @params);
}
else
{
    $i = 0;
}

my @col;
my $url;
my $cmd;

for ($count = 0; $count < @params; $count++, $i = ($i + 1) % @params)
{
    @col = split( "[ 	]+|,", $params[ $i]);
    $url = eval qq/"$opt_url"/;
    $cmd = "wget -O /tmp/wget.$$.$count.result "
        . (defined( $opt_sessionId)
           ? " --header=\"Cookie: jsessionid=$opt_sessionId\" "
           : "")
        . "\"$url\"";
    print( STDERR "rec $i --> $cmd\n");
    my $rc = system( $cmd);
    if ($rc)
    {
        ($rc < 0) and warn "system( $cmd): $!";
        ($rc > 0) and do
        {
            warn "system( $cmd) returned " . ($rc >> 8);
        };
    }
}

# ----------------------------------------------------------------------------
#  END
# ----------------------------------------------------------------------------

1;
__END__


# $Log: wget_driver.pl,v $
# Revision 1.2  2001/09/25 18:21:35  J80Lusk
# *** empty log message ***
#
# Revision 1.1  2001/09/25 17:48:28  J80Lusk
# Initial version.
#
# Revision 1.5  2001/08/28 16:21:27  J80Lusk
# Add emacs coding: mode line.
#
# Revision 1.4  2001/08/22 15:53:44  J80Lusk
# Add #! line.
#
# Revision 1.3  2001/08/22 15:22:17  J80Lusk
# *** empty log message ***
#
