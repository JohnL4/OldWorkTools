#!/usr/bin/perl -w

=head1 NAME

split-lines.pl - split lines from one file into several files, based on the
    contents of a column

=head1 SYNOPSIS

  split-lines.pl { --keyColumn <n> | --keyRE <regexp>} --basename <filename>
    --suffix <suffix> [<file>]

=head1 DESCRIPTION

Scans input file, writing lines out to separate files based on the value of
given column.

keyColumn is 0-based.

keyRE has format "n:re", where n is an integer in range [0..9] and denotes a
subexpression in the RE.  n is the subexpression match result to use as
the key.  Sub-expression index is 1-based.

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

use FileHandle;

# ----------------------------------------------------------------------------
#  Globals
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
#  Static Methods
# ----------------------------------------------------------------------------


# ----------------------------------------------------------------------------
#  Main
# ----------------------------------------------------------------------------

my ($opt_keyCol, $opt_keyRE, $opt_basename, $opt_suffix);

GetOptions( "keyColumn=i" => \$opt_keyCol,
            "keyRE=s"     => \$opt_keyRE,
            "basename=s"  => \$opt_basename,
            "suffix=s"    => \$opt_suffix)
    or die $!;

my $err;

if (! defined( $opt_keyCol) and ! $opt_keyRE)
{
    print( STDERR "requires keyCol or keyRE\n");
    $err = 1;
}
if (! $opt_basename)
{
    print( STDERR "requires basename\n");
    $err = 1;
}
if (! $opt_suffix)
{
    print( STDERR "requires suffix\n");
    $err = 1;
}

if ($err)
{
    die;
}

my %fh;

my ($keyRE, $keySubexpIx);

if ($opt_keyRE)
{
    ($keySubexpIx, $keyRE) = split( /:/, $opt_keyRE, 2);
    $keySubexpIx--;             # convert 1-based to 0-based, for use as array
                                # index below.
}

while (<>)
{
    chomp;
    s/\r//;
    my @fields = split;
    my $key;
    if (defined( $opt_keyCol))
    {
        $key = $fields[ $opt_keyCol];
    }
    else
    {
        my @match = $_ =~ m/$keyRE/o;
        if (@match)
        {
            $key = $match[ $keySubexpIx];
        }
        else
        {
            undef $key;
        }
    }
    if ($key)
    {
        my $fh = $fh{ $key};
        if (! defined( $fh))
        {
            print( STDERR "new userid: $key\n");
            my $filename = "$opt_basename.$key.$opt_suffix";
            $fh = FileHandle->new( "> $filename")
                or die "FileHandle->new( \"> $filename\"): $!";
            $fh{ $key} = $fh;
        }
        $fh->print( "$_\n");
    }
}
foreach my $fh (values %fh)
{
    $fh->close();
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
