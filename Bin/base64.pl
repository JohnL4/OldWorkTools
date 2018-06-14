#!/usr/bin/perl -w
                                # -*- coding: raw-text-dos -*-


=head1 NAME

base64.pl - base-64 ops on files

=head1 SYNOPSIS

 base64.pl -e file.mp3 > file.txt
 base64.pl -d file.txt > file.mp3

=head1 DESCRIPTION

Perform base-64 operations on files (encode, decode).

=head1 AUTHOR

john.lusk@canopysystems.com, as if any credit is deserved

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

use MIME::Base64;

# ----------------------------------------------------------------------------
#  Globals
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
#  Static Methods
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
#  Main
# ----------------------------------------------------------------------------

my ($opt_e, $opt_d, $opt_o);

GetOptions( "d" => \$opt_d,
            "e" => \$opt_e)
    or die $!;

my $fileContents = join( "", <>); # SLURP!!
my ($encoded, $decoded);        # encoded/decoded file contents

# printf( "File contents:\n%s\n", $fileContents); # debug

if ($opt_e)
{
    $encoded = encode_base64( $fileContents);
    print $encoded, "\n";
}
elsif ($opt_d)
{
    $decoded = decode_base64( $fileContents);
    print $decoded;
}

# ----------------------------------------------------------------------------
#  END
# ----------------------------------------------------------------------------


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
