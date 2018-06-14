# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => last_test_to_print };
use OrderedSet;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

my $set = OrderedSet->new();

my @neighbors = $set->neighbors( 12);

ok( @neighbors == 2);
ok( ! defined( $neighbors[0]));
ok( ! defined( $neighbors[1]));

$set->add( 20);
$set->add( 10);
$set->add( 30);
$set->add( 15);

@neighbors = $set->neighbors( 12);
ok( $neighbors[0] == 10);
ok( $neighbors[1] == 15);

$set->add( 12);
@neighbors = $set->neighbors( 12);
ok( $neighbors[0] == 10);
ok( $neighbors[1] == 12);

my @list = $set->asList();
ok( @list == 5);                # <annex>, </annex> removed
print "Set contents: ", join( ", ", @list), "\n";
push( @list, -13);

my @list = $set->asList();
ok( @list == 5);

                                # ################ append/reorder
# $set->append( 18);
# print "Set contents: ", join( ", ", $set->asList()), "\n";
# 
# @neighbors = $set->neighbors( 20);
# ok( $neighbors[0] == 15);
# ok( $neighbors[1] == 20);
# 
# $set->reorder();
# @neighbors = $set->neighbors( 20);
# ok( $neighbors[0] == 18);
# ok( $neighbors[1] == 20);
                                # ################ binary search

$set->initialize();
$set->add( 5);

($left, $right) = $set->neighbors( 6);
ok( $left == 5 and ! defined( $right));

($left, $right) = $set->neighbors( 5);
ok( ! defined( $left) and $right == 5);

($left, $right) = $set->neighbors( 4);
ok( ! defined( $left) and $right == 5);

                                # ----------------

$set->initialize();
$set->add(4);
$set->add(6);

($left,$right) = $set->neighbors( 3);
ok( ! defined( $left) and $right == 4);

($left,$right) = $set->neighbors( 4);
ok( ! defined( $left) and $right == 4);

($left,$right) = $set->neighbors( 5);
ok( $left == 4 and $right == 6);

($left,$right) = $set->neighbors( 6);
ok( $left == 4 and $right == 6);

($left,$right) = $set->neighbors( 7);
ok( $left == 6 and ! defined( $right));

                                # ----------------
$set->add(1);                   # {1,4,6}

($left,$right) = $set->neighbors( 3);
ok( $left == 1 and $right == 4);

($left,$right) = $set->neighbors( 4);
ok( $left == 1 and $right == 4);

($left,$right) = $set->neighbors( 5);
ok( $left == 4 and $right == 6);

($left,$right) = $set->neighbors( 6);
ok( $left == 4 and $right == 6);

($left,$right) = $set->neighbors( 7);
ok( $left == 6 and ! defined( $right));

                                # ################
