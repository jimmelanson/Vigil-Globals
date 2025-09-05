#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

#use FindBin;
#use lib "$FindBin::Bin/../lib";

use Vigil::Globals;

my $globals = Vigil::Globals->new;

print "Individual key/value pairs\n";
$globals->set('foo', 'bar');
$globals->set('baz', 'qux');
$globals->set('zap', 'zip');

print $globals->read('foo'), "\n";
print $globals->read('baz'), "\n";
print $globals->read('zap'), "\n\n";

print "Appending a string to a key/value pair\n";
$globals->append('foo', ' is the loneliest place to be.');
print $globals->read('foo'), "\n\n";

print "Exists example\n";
if($globals->exists('baz')) {
	print "Yes, baz is present.\n";
}
if(!$globals->exists('apple')) {
	print "There is no apple\n\n";
}

print "Delete example\n";
print "BAZ: ", $globals->read('baz'), "\n";
$globals->delete('baz');
print "BAZ: ", $globals->read('baz'), "\n\n";

print "Getting all keys and all values\n";
my @all_keys = $globals->allkeys;
my @all_values = $globals->allvalues;
print "All keys: ", join(',', @all_keys), "\n";
print "All values: ", join(',', @all_values), "\n\n";

print "Now emptying the whole structure\n";
$globals->empty;
@all_keys = ();
@all_values = ();
@all_keys = $globals->allkeys;
@all_values = $globals->allvalues;
print "All keys: ", join(',', @all_keys), "\n";
print "All values: ", join(',', @all_values), "\n\n";

print "Now working with array refs and hashrefs\n";
$globals->set('colours', ['blue', 'red', 'green']);
my $colours_ref = $globals->read('colours');
print "colour 1: $colours_ref->[0]\n";
print "colour 2: $colours_ref->[1]\n";
print "colour 3: $colours_ref->[2]\n\n";

my @breads = ('artisan', 'white', 'whole wheat');
$globals->set('breads', \@breads);
my $breads_ref = $globals->read('breads');
print "bread 1: $breads_ref->[0]\n";
print "bread 2: $breads_ref->[1]\n";
print "bread 3: $breads_ref->[2]\n\n";

my %names = ('John' => 'Brown', 'Bob' => 'Murphy', 'Lady' => 'Jane');
$globals->set('names', \%names);
my $names_ref = $globals->read('names');
print "John $names_ref->{John}\n";
print "Bob $names_ref->{Bob}\n";
print "Lady $names_ref->{Lady}\n\n";

print "Add to colours list and names hash\n";
$globals->append('colours', 'fuschia');
my @new_colours = ('magenta', 'cyan', 'peridot');
$globals->append('colours', \@new_colours);
$colours_ref = undef;
$colours_ref = $globals->read('colours');
print "All colours: ", join(',', @{$colours_ref}), "\n\n";

$globals->append('names', {'Arthur' => 'Dent', 'Ford' => 'Prefect', 'Bob' => 'Dylan'} );
my %new_names = ('Trillian' => 'aka Tricia mcMillan', 'Zaphod' => 'Beeblebrox', 'Martin' => 'Paranoid Robot');
$globals->append('names', \%new_names);
print "All names:\n";
for my $key (sort keys %$names_ref) {
    my $value = $names_ref->{$key};
    print "$key => $value\n";
}
print "\n";
$globals->set('key1', 'value1');
$globals->set('key2', 'value2');
$globals->set('key3', 'value3');
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
print Dumper $globals;
print "\n\n";

use MIME::Base64;
print decode_base64('RGVtbyBmaW5pc2hlZDogTXkgS3VuZy1GdSBpcyBzdHJvbmcuLi4='), "\n";
