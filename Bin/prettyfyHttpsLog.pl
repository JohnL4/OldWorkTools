
# $Header: v:/J80Lusk/CVSROOT/Tools/Bin/prettyfyHttpsLog.pl,v 1.1 2001/09/04 16:01:37 J80Lusk Exp $

package Convenience::FormatCollector::Trivial;

use strict;

# has the option to *Collect* various
# logfields and then produce a pretty
# output.
#
# two methods- "Collect" and "Produce"

sub new
{
    my $class = shift;
    my $title = shift;
    
    return (bless {_title => $title}, $class);
}

# returns the data it has collected
sub Consume
{
    my $self  = shift;
    my $title = shift;
    my $data  = shift;

    $self->{_strictTitles} and
        $title != $self->{_title} and
            die("Title mismatch! format for $self->{_title} recieved $title");
    
    $self->{_data} = $data;

    return $data;
}

sub Produce
{
    my $self = shift;
    return $self->{_data};
}

sub Title
{
    my $self = shift;
    return $self->{_title};
}

package Convenience::FormatCollector::CookieParser;

sub new
{
    my $class       = shift;
    my $delimiter   = shift;
    my @cookieNames = @_;

    my $self = {
        _cookiePatterns => {},
        _cookieOrder    => [@cookieNames],
        _delimiter      => $delimiter
        };

    @{$self->{_cookiePatterns}}{@cookieNames} =
         map { qr/\b\Q$_=\E([^;]*)(;|$)/ } @cookieNames;

    return (bless $self, $class);
}


# returns an array composed of each cookie name matched
# in order
sub Consume
{
    my $self  = shift;
    my $title = shift;
    my $data  = shift;
 
    $self->{_raw} = $data;
    
    my $patterns = $self->{_cookiePatterns};

    $self->{_matches} = {};

    # Doing linear scans over an associative array is like
    # trying to club someone to death with a loaded Uzi. --Larry Wall 
    foreach my $cookieName (@{$self->{_cookieOrder}})
    {
        my @matched = ();

        (my $pattern = $patterns->{$cookieName})         
            or next;

#        print STDERR "Got pattern $pattern for $cookieName....\n";
        
        if($data =~ /$pattern/)
        {
#            print STDERR "Got $pattern matched $data with $1\n";            
            $self->{_matches}{$cookieName} = $1;
#            sleep(1);
        }
    }

    return grep { $self->{_matches}{$_} } $self->{_cookieOrder};
}


sub Produce
{
    my $self = shift;

    return
        join($self->{_delimiter},
             map { $self->{_matches}{$_} } @{$self->{_cookieOrder}});
}

sub Title
{
    my $self = shift;
    return join($self->{_delimiter}, @{$self->{_cookieOrder}});
}

package main;
use strict;

# BEGIN DO-IT-YOURSELF
# Edit these variables to change the parsing behavior
#

# if true, prints a diagnostic 'raw' line before each parsed line
my $gdebug = 1;#undef; 

my $outdelimiter = ',';

my @cookiesOfInterest = (
                         'jsessionid',
                         'ActuateUsername',
                         );

my @trivials = 
               qw(
                  date
                  time        
                  c-ip        
                  cs-method   
                  cs-uri-stem 
                  sc-status   
                  cs-bytes                            
                  sc-bytes    
                  time-taken  
                  );

my $cookieField = 'cs(Cookie)';

my @outputOrder = (@trivials, $cookieField);

# if true, preceed output with titles
my $useTitles = 'yes sir!'; 

# END DO-IT-YOURSELF
# I'll handle the rock from here...

MAIN:
{
    my $cookieFormatter =
      Convenience::FormatCollector::CookieParser->new($outdelimiter, @cookiesOfInterest);
    
    my %fieldFormatters =
        (
         $cookieField => $cookieFormatter,
         map {
             ($_, Convenience::FormatCollector::Trivial->new($_))
             }@trivials
         );
                
    my @fields; # read in Fields directive

    if($useTitles)
    {
        my @titles = map {  $fieldFormatters{$_}->Title() } @outputOrder;
        print join(',', @titles);
        print "\n";
    }
        
    while(<>)
    {
        $gdebug and print "@@", $_;
        chomp;
        
        if(/^\#Fields:(.*)/) {
            my $fieldLine = $1;
            @fields = split(" ", $fieldLine);
        }
        elsif(/^\#/) {
            next;
        }
        else {
            @fields or
                die "Couldn't find '#Fields' line in your log - Talk to Joe if you need to do this.";
            
            my %line = ();
            @line{@fields} = split;

            for(@outputOrder)
            {
                $fieldFormatters{$_}->Consume($_, $line{$_});
            } 

            print join($outdelimiter, map { $fieldFormatters{$_}->Produce() } @outputOrder), "\n";
        }        
    }
}





