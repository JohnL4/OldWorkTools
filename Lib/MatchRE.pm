#!/perl/bin/perl -w

package MatchRE;

=head1 NAME

MatchRE - Manage list of matching regular expression mappings

=head1 SYNOPSIS

  use MatchRE;
  @res = &MatchRE::slurpREs( filename);

=head1 DESCRIPTION

Parses list of regular expression mappings in file.  One mapping per line,
whitespace-delimited.  Format of each line is:

    I<mapped-to-item> I<regular-expression-including-possible-whitespace>

where I<mapped-to-item> is the item that should be returned if the given
regular expression matches.

A possible use of this library is to map lines of a time-tracking journal to
timecodes for reporting into a timecard-processing system.

=head2 EXPORT

None by default.

=head1 AUTHOR

john.lusk@allscripts.com

=head2 VERSION

$Header: v:/J80Lusk/CVSROOT/Tools/perl-template.pm,v 1.5 2001/08/28 16:21:27 J80Lusk Exp $
    
=head1 SEE ALSO

L<perl>.

=head1 TODO

=head1 PUBLIC METHODS

=over

=cut

use 5.006;
use strict;
use warnings;
use Carp;
use Getopt::Long;

use FileHandle;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use WebServer::Log ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
                                   slurpREs
                                   new
                                   getKey
                                   getRE
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.01';


# Preloaded methods go here.

# ----------------------------------------------------------------------------
#  Globals
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
#  Static Methods
# ----------------------------------------------------------------------------

=item B<slurpREs>( I<matchFileName>)

Static method to inhale regular expressions in correct format (see above) and
return a list of MatchRE objects.  Discards blank and comment lines (comment
char = "#").

=cut
    
sub slurpREs
{
    my ($aMatchFileName,
        ) = @_;
    my @retval;
    if ($aMatchFileName)
    {
        my $fh = FileHandle->new( "< $aMatchFileName")
            or die "FileHandle->new( \"< $aMatchFileName\"): $!";
        while (<$fh>)
        {
            chomp;
            s/\r//;
            if (($_ =~ m/^\s*\#/) || ($_ =~ m/^\s*$/))
            {
                next;           # comment or blank
            }
            my @cols = split( " ", $_);
            my $key = $cols[0];
            my $matchTgt;
            ($matchTgt = $_) =~ s/^\s*\S+\s+//;
            my $matchRE = MatchRE->new( $key, $matchTgt);
            push( @retval, $matchRE);
        }
        $fh->close();
    }
    else
    {
        @retval = ();
    }
    return @retval;
}

=item B<matchKey>( I<line>, I<reList>)

Static.  Returns the key corresponding to the match re that the given line
matches.  Returns undef if no match.

=cut
    
sub matchKey
{
    my( $anInputLine,           # Line of input.
        $anREList,              # Ref to List of MatchREs
        ) = @_;
    my $retval;
    for (my $i = 0; ($i < @$anREList) && (! $retval); $i++)
    {
        my $matchRE = $anREList->[$i]->getRE();
        if ($anInputLine =~ m/$matchRE/)
        {
            $retval = $anREList->[$i]->getKey();
        }
    }
    return $retval;
}

# ----------------------------------------------------------------------------
#  Public Methods
# ----------------------------------------------------------------------------

=item B<new>()

Instantiates new object and passes parameters to initialize().

=cut
    
sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    bless ($self, $class);
    $self->initialize( @_);
    return $self;
}

sub initialize
{
    my $self = shift;
    my ($aKey,                  # "key" of match (arbitrary string, acting as
                                #   an identifier or a title or a summary)
        $anRE,                  # Regexp that produces match
        ) = @_;
    
    $self->{_KEY} = $aKey;
    $self->{_RE} = $anRE;
}

=item B<getKey>()

Returns the "key" (non-unique) that a successful match should map to (or
"transform to").

=cut
    
sub getKey
{
    my $self = shift;
    return $self->{_KEY};
}

=item B<getRE>()

Returns the regular expression to be used for matching.

=cut

sub getRE
{
    my $self = shift;
    return $self->{_RE};
}


# ----------------------------------------------------------------------------
#  Private Methods
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
#  END
# ----------------------------------------------------------------------------

1;
__END__

=pod

=back

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
