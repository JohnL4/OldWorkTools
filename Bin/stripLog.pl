#!/usr/bin/perl -w

=head1 NAME

stripLog.pl -- Strips the "Log" VC keyword (and log entries) from source code

=head1 SYNOPSIS

  stripLog.pl [I<sourceCodeFile>]

=head1 DESCRIPTION

This script finds the change history log denoted by a "Log" version-control
keyword and removes it from the given source code file (or stdin, if no file
is given).



=head1 AUTHOR

john.lusk@allscripts.com

=head2 VERSION

$Header: v:/J80Lusk/CVSROOT/Tools/perl-template.pm,v 1.5 2001/08/28 16:21:27 J80Lusk Exp $
    
=head1 SEE ALSO

L<perl>.

=head1 TODO

=cut

use 5.006;
use strict;
use warnings;
use Carp;
use Getopt::Long;


# ----------------------------------------------------------------------------
#  Globals
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
#  Static Methods
# ----------------------------------------------------------------------------


# ----------------------------------------------------------------------------
#  Main
# ----------------------------------------------------------------------------

# my ($opt_a, $opt_b);
# 
# GetOptions( "a=s" => \$opt_a,
#             "b=s" => \$opt_b)
#     or die $!;

my( $leader,                    # Characters appearing at the start of every
                                #   log line.
    $sawLogKeyword,             # True if we're in the log section (and are
                                #   therefore stripping lines).
    );

while (<>)
{
    /^(.*)\$Log:/ && do
    {
        $leader = $1;
        $leader =~ s/\*/\\*/g;  # Escape for use in match expression below.
        $sawLogKeyword = 1;
        print;                  # Print opening and closer, but nothing in
                                #   between.  We expect the SCM system to
                                #   repopulate the change history on next
                                #   checkout. 
        next;
    };
    $sawLogKeyword && /^$leader\$/ && do
    {
        $sawLogKeyword = 0;
        print;
        next;
    };
    $sawLogKeyword && next;
    print;
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
