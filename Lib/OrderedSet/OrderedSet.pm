#!/perl/bin/perl -w
                                # -*- coding: raw-text-dos -*-

package OrderedSet;


=head1 NAME

OrderedSet - Set of numbers that can be binary-searched

=head1 SYNOPSIS

    use OrderedSet;
    my $set = OrderedSet->new();
    $num = 12;
    if ($set->add( $num)) {
        print "$num was added";
    }
    else {
        print "$num was already present";
    }
    ($lessThan12, $greaterThanOrEqualTo12) = $set->neighbors( 12);

=head1 DESCRIPTION

Crude implementation of an order set of numbers, basically so you can do
binary searches on inexact keys.

=head2 EXPORT

None by default.

=head1 AUTHOR

john.lusk@canopysystems.com

=head2 VERSION

$Header: v:/J80Lusk/CVSROOT/PerlModules/OrderedSet/OrderedSet.pm,v 1.4 2001/09/09 16:41:59 J80Lusk Exp $
    
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

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use WebServer::Log ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
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

=item B<initialize>( I<params...>)

(Re-)Initializes this object.

=cut
    
sub initialize
{
    my $self = shift;
    $self->{PRESENCE_HASH} = {};
    $self->{SET} = [];
    $self->{ANNEX} = [];
}

=item B<add>( I<elt>)

If given elt does not already exist in set, adds it and returns true.
Otherwise, elt already exists and this function returns false.

=cut
    
sub add
{
    my ($self, $elt) = @_;
    if ($self->{PRESENCE_HASH}->{$elt})
    {
        return 0;
    }
    else
    {
        $self->{PRESENCE_HASH}->{$elt} = 1;
        my $lastIx = @{$self->{SET}} - 1;
        my $insertPt = $self->_firstEltGE( $elt);
        my @newSet = (($insertPt >= 0 ? @{$self->{SET}}[0..$insertPt-1] : ()),
                      $elt,
                      @{$self->{SET}}[$insertPt..$lastIx]);
        $self->{SET} = \@newSet;
        return 1;
    }
}

# =item B<append>( I<elt>)
# 
# Similar to B<add>(), B<but...> element is appended to a special annex not
# scanned by the B<neighbors>() method.  If you want B<neighbors>() to find this
# element after appending it, call B<reorder>() before calling B<neighbors>().
# This avoids the cost of list insertion, with the assumption that the actual
# insertion can be deferred until it can be batched w/other insertions via a
# straight sort (O(n log n) vs. O( n^2)).
# 
# =cut
# 
# sub append
# {
#     my ($self, $elt) = @_;
#     if ($self->{PRESENCE_HASH}->{$elt})
#     {
#         return 0;
#     }
#     else
#     {
#         $self->{PRESENCE_HASH}->{$elt} = 1;
#         push( @{$self->{ANNEX}}, $elt);
#         return 1;
#     }
# }
# 
# =item B<reorder>()
# 
# Merges the contents of the annex (created with B<append>()) into the set, so
# that B<neighbors>() will scan (former) annex members the next time it is
# called.
# 
# =cut
# 
# sub reorder
# {
#     my ($self) = @_;
#     push( @{$self->{SET}}, @{$self->{ANNEX}});
#     my @list = sort { $a <=> $b } @{$self->{SET}};
#     $self->{SET} = \@list;
# }

=item B<neighbors>( I<elt>)

Find neighbors of I<elt> in set s.t. left neighbor is < I<elt> and right
neighbor is >= I<elt>.  (Note that if right neighber == I<elt>, right neighbor
B<is> I<elt>.)  Returns 2-elt list: (I<left, right>).  One or both of these
may be null.

=cut
    
sub neighbors
{
    my ($self, $elt) = @_;
    my $firstGE = $self->_firstEltGE( $elt);
    if ($firstGE == 0)
    {
        return (undef,
                $self->{SET}->[0]);
    }
    elsif ($firstGE >= @{$self->{SET}})
    {
        return ($self->{SET}->[@{$self->{SET}} - 1],
                undef);
    }
    else
    {
        return ($self->{SET}->[$firstGE - 1],
                $self->{SET}->[$firstGE]);
    }
}

=item B<asList>()

Returns copy of list comprising set.

=cut
    
sub asList
{
    my ($self) = @_;
    my @list = @{$self->{SET}};
    # push( @list, "<annex>", @{$self->{ANNEX}}, "</annex>");
    return @list;
}

# ----------------------------------------------------------------------------
#  Private Methods
# ----------------------------------------------------------------------------

# Return offset in list of first elt >= $tgt

sub _firstEltGE
{
    my ($self, $tgt) = @_;

    my ($low, $mid, $high, $foundVal);

    $low = 0;
    $high = @{$self->{SET}} - 1;
    $mid = int( ($low + $high) / 2);
    $foundVal = $self->{SET}->[$mid];
    while (($low < $high) && ($foundVal != $tgt))
    {
        if ($foundVal < $tgt)
        {
            $low = $mid + 1;
        }
        else
        {
            $high = $mid;
        }
        $mid = int( ($low + $high) / 2);
        $foundVal = $self->{SET}->[$mid];
    }
    if (defined( $foundVal) and $foundVal == $tgt)
    {
        return $mid;
    }
    else
    {
                                # $low >= $high
        if (defined( $self->{SET}->[$high])
            and $self->{SET}->[$high] >= $tgt)
        {
            return $high;
        }
        else
        {
            return $high+1;
        }
    }
    # TEST: {5}->find(6): should return 1.
    #          (0,0,0) ret 1
    #       {5}->find(5): should return 0
    #          (0,0,0) ret 0
    #       {5}->find(4): should return 0
    #          (0,0,0) ret 0
    #       {4,6}->find(3): should return 0
    #          (0,0,1) --> (0,0,0) ret 0
    #       {4,6}->find(4): should return 0
    #          (0,0,1) ret 0
    #       {4,6}->find(5): should return 1
    #          (0,0,1) --> (1,1,1) ret 1
    #       {4,6}->find(6): should return 1
    #          (0,0,1) --> (1,1,1) ret 1
    #       {4,6}->find(7): should return 2
    #          (0,0,1) --> (1,1,1) ret 2
    
    
}

# ----------------------------------------------------------------------------
#  END
# ----------------------------------------------------------------------------

1;
__END__

=pod

=back

=cut

# $Log: OrderedSet.pm,v $
# Revision 1.4  2001/09/09 16:41:59  J80Lusk
# Re-add after accidental remove.
#
# Revision 1.1.1.2  2001/09/09 16:40:58  J80Lusk
# Initial version
#
# Revision 1.2  2001/09/09 16:29:56  J80Lusk
# Binary search of ordered set (duh).
# Add commented-out "annex" code (useless, but I'll remove it later).
#
# Revision 1.1.1.1  2001/09/07 18:09:56  J80Lusk
# Initial version
#
