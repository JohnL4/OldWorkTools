#!c:/perl/bin/perl

=pod

Grim hack by Joe Bowers to snarf interesting bits out of a Canopy
audit log (on stdin) and render them more politely (to stdout) in CSV
lines.

Output format seems to be a comma-separated list of the following
fields:

=over

=item *
YYYY-MM-DD HH:MM:SS timestamp

=item *
Session-count at time of login

=item *
User name

=item *
Domain

=item *
Session id
    
=back

=cut

my $ENTRY_SEPARATOR = "xxxxx";  # Match operator compiled once, so
                                # don't get fancy here.

MAIN:
{    
    my @line;
    my @headers = qw(timestamp sessions username domain id);

    print '#', join(',', @headers), "\n";
    
    while(<>)
    {
        (
         m/^(.*) : AUDIT_TRAIL/
         and $line[0] = $1
        ) or
        (
         m/SessionManager\.addSession\: new session for \'([^\']*)\' in domain \'([^\']*)\', session is ID=(\d+)/
         and @line[2, 3, 4] = ($1, $2, $3)
        ) or
        (
         m/SessionManager\.addSession\: currently\, there are (\d+) sessions\./
         and @line[1] = $1
        );

        (@headers == (grep {defined($_)} @line)) and print join(',', @line[0..4]), "\n";
        
        (m/^$ENTRY_SEPARATOR/o || (@headers == grep {defined($_)} @line)) and @line = (); #new line
   }
}


