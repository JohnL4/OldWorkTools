#!/perl/bin/perl -w
                                # -*- coding: raw-text-dos -*-

=head1 NAME

massage-onLoad.pl - Massage JSPs depending on "onload"

=head1 SYNOPSIS

 massage-onLoad.pl <file>...

=head1 DESCRIPTION

Transforms "<body onload='Loading()'>"-style JSPs into JSPs that explicitly
call the on-load functionality at the bottom of their bodies, like this:

    <script>Loading();</script>
    </body>

=head2 IMPLEMENTATION

                                 <!-- Step 1:  All files that don't include -->
                                 <!-- this, should.   (Fool emacs:  ') -->
 <script src="/js/CanopyLoader.js"></script>
 
 <script>
 {
    
                                 // Step 2a:  Files whose body tags call
                                 // "Loading()" get the following replacement
                                 // line. 
    (new CanopyLoader).addLoader( Loading);
 
                                 // Step 2b:  Files whose body tags call
                                 // "loaded()" get the following replacement
                                 // line. 
    (new CanopyLoader).addLoader( loaded);
    
 }
 </script>
 
                                 <!-- Step 3:  All files get this just before
                                 the "/body" tag. -->
 <script>
    CanopyLoader.load();
 </script>
      

=head1 AUTHOR

john.lusk@canopysystems.com

=head2 VERSION

$Header: massage-onLoad.pl, 3, 4/9/2002 8:36:34 PM, John Lusk$
    
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

use Element;

# ----------------------------------------------------------------------------
#  Globals
# ----------------------------------------------------------------------------


# ----------------------------------------------------------------------------
#  Static Methods
# ----------------------------------------------------------------------------

# Generates a list of complaints about the validity of the given lines of
# html.  If no complaints are generated, returns the empty list.

sub complainAbout
{
    my ($aListOfLines) = @_;

    my @complaints;
    if (grep( m{</body>}i, @$aListOfLines) != 1)
    {
        push( @complaints, "No or too many </body> tags");
    }
    return @complaints;
}

# Adds call to source in CanopyLoader.js.  Dies on failure.

sub includeCanopyLoader
{
    my ($filelines) = @_;       # ref to list
    if (! grep( /<script.*src=.*CanopyLoader\.js/, @$filelines))
    {
        # Step 1: Insert "<script src="/js/CanopyLoader.js"></script>"
        # somewhere
        my $lineno = &search( $filelines, 0, "<script.*src=");
        my $dummy;
        if (!defined( $lineno))
        {
            $lineno = &search( $filelines, 0, "<script");
        }
        if (!defined( $lineno))
        {
            ($lineno, $dummy) = &findHead( $filelines);
            $lineno++;
        }
        splice( @$filelines, $lineno, 0,
                "<script src=\"/js/CanopyLoader.js\"></script>\n");
    }
}

# Returns the line no. of the onload attribute, undef if one doesn't exist.

sub getOnLoadLocn
{
    my ($filelines) = @_;       # ref to list
    my $bodyLocn = &search( $filelines, 0, "<body") - 1;
    my $onLoadLocn;
    do
    {
        $bodyLocn++;
        if ($filelines->[$bodyLocn] =~ m/onload="(.+)"/i
            or $filelines->[$bodyLocn] =~ m/onload='(.+)'/i)
        {
            $onLoadLocn = $bodyLocn;
        }
    } until ($filelines->[ $bodyLocn] =~ m/>/);
    return $onLoadLocn;
}

# Add a new CanopyLoader instantiation that replcates the on-load code.

sub addNewLoader
{
    my ($filelines,             # ref to list
        $onLoadLocn) = @_;      # line no. of "onload" attr in list

    my $onLoadCode;
    if ($filelines->[$onLoadLocn] =~ m/onload="(.+)"/i
        or $filelines->[$onLoadLocn] =~ m/onload='(.+)'/i)
    {
        $onLoadCode = $1;
    }
    else
    {
        die "Can't find on-load code in line $onLoadLocn";
    }
    $onLoadCode =~ s/(.*)CanopyLoader.load\(\);?(.*)/$1$2/;
    if ($onLoadCode !~ m/^[ ;]*$/)
    {
                                # After removing CanopyLoader.load() there's
                                # still something to be done.
        my ($dummy, $insertLocn) = &findHead( $filelines);
        my $newLoader = <<"EOF";

<script>
   // Added automatically by massage-onLoad.pl.
   (new CanopyLoader).addLoader( function() {
      $onLoadCode;
   });
</script>

EOF
        splice( @$filelines, $insertLocn, 0, $newLoader);
    }
}

# Add a call to CanopyLoader.load() at the bottom of the page, just before
# "</body>".

sub addCanopyLoaderCall
{
    my ($filelines) = @_;       # ref to list
    my $bodyEndLocn = &search( $filelines, 0, "</body>");
    if (! defined( $bodyEndLocn))
    {
        die "No body closer";
    }
    splice( @$filelines, $bodyEndLocn, 0,
            "<script>CanopyLoader.load();</script>\n");
}

# Do the actual work, w/out cluttering the main loop.

sub doTheActualMassaging
{
    my ($filelines) = @_;       # ref to list.

    my @validityComplaints = &complainAbout( $filelines);
    if (@validityComplaints)
    {
        die (scalar( @validityComplaints) . " complaints:\n\t"
             . join( "\n\t", @validityComplaints) . "\n");
    }
    my $bodyElt = Element::search( "body", $filelines, 0);
    my $lineno = $bodyElt->getEndLineNo();
    my $funcCall = << "EOF";

<script>
      // Added by massage-onLoad.pl.
      // Explicitly calls the "onload" handler for this page, and nulls it out
      // so it won't be called again when the browser considers the page to be
      // loaded.  The rationale for this is that sometimes our onLoad handlers
      // don't fire reliably.
function _callOnLoad()
{
    var onLoadHdlr = document.body.onload;
    document.body.onload = null;
    if (onLoadHdlr)
        onLoadHdlr();
}
_callOnLoad();
</script>

EOF
    splice( @$filelines, $lineno, 0, $funcCall);
}

# ----------------------------------------------------------------------------
#  Main
# ----------------------------------------------------------------------------

foreach my $filename (@ARGV)
{
    print "----------------  $filename  ----------------\n";
    my $fh = FileHandle->new( "< $filename") or do
    {
        warn "open( \"$filename\"): $!";
        next;
    };
    my @fileline = <$fh>;       # slurp!
    $fh->close();

    eval { &doTheActualMassaging( \@fileline); };
    if ($@)                     # Catch exceptions.
    {
        warn "$@ massaging \"$filename\"";
        next;
    }

                                # Re-write, with backup.
    rename $filename, "$filename.bak" or do
    {
        warn "rename \"$filename\", \"$filename.bak\": $!";
        next;
    };
    $fh = FileHandle->new( "> $filename");
    $fh->print( @fileline);
    $fh->close();
}


# ----------------------------------------------------------------------------
#  END
# ----------------------------------------------------------------------------

__END__


# $Log: 
#  3    CanopyIA R3.11.2         4/9/2002 8:36:34 PM  John Lusk       
#       2nd version, less ambitious in the perl domain, more ambitious in the
#       javascript domain.
#  2    CanopyIA R3.11.1         4/9/2002 4:32:49 PM  John Lusk       
#  1    CanopyIA R3.11.0         4/9/2002 4:31:48 PM  John Lusk       
# $
