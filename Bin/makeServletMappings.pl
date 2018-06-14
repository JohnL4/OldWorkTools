#!/usr/bin/perl -w


=head1 NAME

makeServletMappings.pl - make web.xml fragment from list of servlet classes

=head1 SYNOPSIS

 makeServletMappings.pl <servletList>

=head1 DESCRIPTION

Makes a web.xml fragment of servlets and servlet-mappings for each of the
servlets named in the text file <servletList> (one per line).

=head1 AUTHOR

john.lusk@canopysystems.com

=head2 VERSION

$Header:perl-template.pm, 1, 3/5/2002 7:00:51 PM, John Lusk$
    
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

my ($opt_a, $opt_b);

GetOptions( "a=s" => \$opt_a,
            "b=s" => \$opt_b)
    or die $!;

my @servlets = <>;

foreach my $servlet (@servlets)
{
    chomp $servlet;
    $servlet =~ s/\r//;
    
    printf( "  <servlet>\n");
    printf( "    <servlet-name>%s</servlet-name>\n", $servlet);
    printf( "    <servlet-class>%s</servlet-class>\n", $servlet);
    printf( "  </servlet>\n");
    printf( "\n");
}

printf( "\n");

foreach my $servlet (@servlets)
{
    chomp $servlet;
    $servlet =~ s/\r//;
    
    printf( "  <servlet-mapping>\n");
    printf( "    <url-pattern>/servlet/%s</url-pattern>\n", $servlet);
    printf( "    <servlet-name>%s</servlet-name>\n", $servlet);
    printf( "  </servlet-mapping>\n\n");
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
