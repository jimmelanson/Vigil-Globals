#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

#use FindBin;
#use lib "$FindBin::Bin/../lib";

use Vigil::Globals;

my $globals = Vigil::Globals->new;

#Test 1
$globals->set('thiskey', 'thatvalue');
ok( $globals->read('thiskey') eq 'thatvalue', 'set() works and read() works');

#Test 2
$globals->append('thiskey', 'tested');
ok( $globals->read('thiskey') eq 'thatvaluetested', 'append() works');

#Test 3
$globals->set('testdelete', 'istrue');
$globals->delete('testdelete');
ok( !defined $globals->read('testdelete'), 'delete() works');

#Test 4
ok($globals->exists('thiskey'), 'exists() works');

#Test 5
$globals->set('secondkey', 'moreinfo');
my @this_keys = $globals->allkeys;
ok( scalar @this_keys == 2, 'allkeys() works');

#Test 6
my @this_values = $globals->allvalues;
ok( scalar @this_values == 2, 'allvalues() works');

#Test 7
$globals->empty;
ok( !defined $globals->read('thiskey'), 'First key cleared by empty()');

#Test 8
ok( !defined $globals->read('secondkey'), 'Second key cleared by empty()');

done_testing();
