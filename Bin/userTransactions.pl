#!/perl/bin/perl

=head1 NAME

userTransactions -- Dump user transactions

=head1 SYNOPSIS

    userTransactions [-l I<IIS_LOG_FILE>] -a I<CANOPY_AUDIT_LOG>

=head1 DESCRIPTION

Dumps user transactions from IIS log file, using audit log to
translate session ids to user names.

=head2 PARAMETERS

=over

=item -a I<CANOPY_AUDIT_LOG>

The audit log will be used to translate session ids into user ids (user
names).

=item -l I<IIS_LOG_FILE>

The IIS log to scan for transactions.  If not given, stdin will be used.

=back

=head2 FILTERING

You might want to filter the IIS log before passing it to this program.  Try
the following:

    egrep -vi ' GET .*\.(js|gif|html|css|jpg)[ 	]' |\
    egrep -vi ' GET /ios_benchmark/' |\
    egrep -vi ' GET (/ |/bottom.html|/servlet/canopy.ui.LoginServlet)'

Or use another filtering script (userTransactions_iisFilter.sh?).

=head1 AUTHOR

john.lusk@canopysystems.com

=head2 VERSION

$Header: v:/J80Lusk/CVSROOT/Tools/Bin/userTransactions.pl,v 1.3 2001/08/30 15:46:08 J80Lusk Exp $
    
=head1 SEE ALSO

L<perl>.

=head1 TODO

=cut

use 5.006;
use strict;
use warnings;
use Carp;

use Getopt::Long;

use WebServer::Log::Entry;
use WebServer::Log::CanopyAuditLog;

# --------------------------------------------------------------------
#  functions
# --------------------------------------------------------------------

sub _screenFreqDescendingComparison
{
    my ($freqDist) = @_;        # Ref. to hash
    
    return sub { -1 * ($freqDist->{$a} <=> $freqDist->{$b}) };
}

sub _xactionCountDescendingComparison
{
    my ($userActivity) = @_;    # Ref. to hash containing tuples containing
                                # freq. counts.
    
    return sub { -1 * ($userActivity->{$a}->{TOTAL_SCREENS} <=>
                       $userActivity->{$b}->{TOTAL_SCREENS})};
}

# --------------------------------------------------------------------
#  main
# --------------------------------------------------------------------

my ($iisLogname, $auditLogname);

GetOptions( "l=s" => \$iisLogname,
            "a=s" => \$auditLogname)
    or die $!;

if (! $auditLogname)
{
    warn "Insufficient params, needs audit log name";
    my $cmd = "pod2text $0";
    if (system( $cmd) != 0)
    {
        die "Can't execute \"$cmd\": $!";
    }
    exit 1;
}

my $auditLog = new WebServer::Log::CanopyAuditLog( $auditLogname);

# print "Audit Log:\n", $auditLog->toString(), "\n";
WebServer::Log::Entry->setSessionToUserIdMapping( $auditLog);

local( *IIS_LOG);

if ($iisLogname)
{
    open( IIS_LOG, "< $iisLogname")
        or die "Can't open \"$iisLogname\": $!";
}
else
{
    *IIS_LOG = *STDIN;
}

my %userTrail;                  # Map from userid to list of screens that user
                                # hit, in the order in which they were hit.

while (<IIS_LOG>)
{
    chomp;
    /^\#Fields: / and do
    {
        print STDERR "\t$_\n";
        WebServer::Log::Entry->setFieldNames( $_);
    };
    /^\#/ and next;             # comments
    /^\s*$/ and next;           # blank lines
    my $entry = WebServer::Log::Entry->new( $_);
    push( @{$userTrail{ $entry->getUserId()}}, $entry->getUriStem());
}
if ($iisLogname)
{
    close( IIS_LOG);
}

                                # For each user, build frequency table of
                                # screens hit.

my ($userId, $userTrail);
my $xaction;                    # A single transaction from the user's trail
                                # of transactions.

my %userActivity;               # Map from userid to tuple consisting of total
                                # no.of screens hit and hash containing
                                # frequency count of each screens.

my %activityByXaction;          # Map from transactions to counts.

my $closure;

while (($userId, $userTrail) = each( %userTrail))
{
    # print "$userId:\n";
    $userActivity{ $userId} = { TOTAL_SCREENS => 0,
                                SCREEN_FREQ => {}};
    foreach $xaction (@$userTrail)
    {
        # print "\t$_\n";
        $activityByXaction{ $xaction}++;
        $userActivity{ $userId}->{ TOTAL_SCREENS}++;
        $userActivity{ $userId}->{ SCREEN_FREQ}->{ $xaction}++;
    }
                                # Having built this user's freq. distribution
                                # of screens visited, use that freq. dist. to
                                # create the "workload signature".
                                #
                                # Because the sort comparator needs access to
                                # data we'd rather not make global, we use a
                                # function call to generate a closure. 

    $closure = _screenFreqDescendingComparison( $userActivity{ $userId}->{ SCREEN_FREQ});
    my @screens
        = sort $closure keys( %{$userActivity{ $userId}->{ SCREEN_FREQ}});
    $userActivity{ $userId}->{ WORKLOAD_SIGNATURE} = \@screens;
}

$closure = _xactionCountDescendingComparison( \%userActivity);
my @users = sort $closure keys( %userActivity);

my $sigElt;                     # signature element

print "=" x 16 . "  USER ACTIVITY  " . "=" x 16 . "\n\n";

foreach $userId (@users)
{
    print "$userActivity{ $userId}->{TOTAL_SCREENS}"
        . "\t$userId:\n";
    foreach $sigElt (@{$userActivity{ $userId}->{ WORKLOAD_SIGNATURE}})
    {
        print "\t$userActivity{$userId}->{SCREEN_FREQ}->{$sigElt}"
            . "\t$sigElt\n";
    }
}

print "\n================  TRANSACTIONS  ================\n\n";

$closure = _screenFreqDescendingComparison( \%activityByXaction);
my @xactions = sort $closure keys( %activityByXaction);
foreach (@xactions)
{
    print "$activityByXaction{ $_}" . "\t$_\n";
}

print "\n================  SESSIONS  ================\n\n";

my $loginToSessionMap = $auditLog->getLoginToSessionMap();

                                # lc (lowercase) ==> case-insensitive
my @userids = sort { uc( $a) cmp uc( $b) } keys %$loginToSessionMap;
foreach my $userid (@userids)
{
    print "$userid\n";
    foreach my $tuple (@{$loginToSessionMap->{ $userid}})
    {
        print "\t$tuple->{ TIMESTAMP}\t$tuple->{ SESSION}\n";
    }
}

__END__

# $Log: userTransactions.pl,v $
# Revision 1.3  2001/08/30 15:46:08  J80Lusk
# Change -i option to -l (-i tends to mean "ignore", not "iis log").
# Add userid-to-session map dump at end of report.
#
# Revision 1.2  2001/08/28 13:43:38  J80Lusk
# Add auditPrettifier to archive, since it's part of the userTransactions
# system.  Add online help to filter.  Minor correction to userTransactions
# help.
# 
# Revision 1.1  2001/08/28 13:29:22  J80Lusk
# Initial version.
# 
