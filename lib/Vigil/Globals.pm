package Vigil::Globals;

use strict;
use warnings;

our $VERSION = '1.2.1';

sub new {
    my ($class) = @_;
    my $self = {
        _error => '',
    };
    bless $self, $class;
    return $self;
}

sub append {
    my ($self, $key, $value) = @_;
    return unless defined $key;

    my $existing = $self->{$key};

    if (ref $existing eq 'ARRAY') {
        # Existing value is an array reference
        if (ref $value eq 'ARRAY') {
            push @$existing, @$value;
        } else {
            push @$existing, $value;
        }
    } elsif (ref $existing eq 'HASH') {
        # Existing value is a hash reference
        if (ref $value eq 'HASH') {
            # Merge keys from $value into existing hash
            @$existing{keys %$value} = values %$value;
        } else {
            die "Cannot append non-hash value to a hashref";
        }
    } else {
        # Existing value is scalar or undef
        $existing //= '';
        $self->{$key} = $existing . $value;
    }
}

sub set { $_[0]->{$_[1]} = $_[2] if defined $_[1]; }

sub read { return $_[0]->{$_[1]} if defined $_[1]; }

sub delete { delete $_[0]->{$_[1]} unless $_[1] =~ /^_/; }

sub empty { delete $_[0]->{$_} for grep { $_ !~ /^_/ } keys %{$_[0]}; }

sub exists { return exists $_[0]->{$_[1]}; }

sub allkeys { return sort { lc($a) cmp lc($b) } grep { $_ !~ /^_/ } keys %{$_[0]}; }

sub allvalues { return map { $_[0]->{$_} } sort { lc($a) cmp lc($b) } grep { $_ !~ /^_/ } keys %{$_[0]}; }

1;

__END__

=head1 NAME

Vigil::Globals - Used to create a name space for global variables, accessible from one place.

=head1 SYNOPSIS

    use Vigil::Globals;
    my $global = Vigil::Globals->new;
	
    my $first_name = 'Harry';
    my $last_name = ' Jones';
	
    $obj->set('name', $first_name);
    print $obj->read('name');         #Prints: Harry
	
    $obj->append('name', $last_name);
    print $obj->read('name');         #Prints: Harry Jones

=head1 CLASS METHODS

=over 4

=item $obj->new;

The object constructor takes no arguments.

=back

=head1 OBJECT METHODS

=over 4

=item $obj->set(KEY, VALUE);

This method allows you to add a key/value pair to the object. The key will always be a string - if you pass numbers of floats (decimal numbers), they will be converted to strings for the purpose of a key. Anything else passed as a string will cause problems for you in trying to retrieve them.

Here are the different ways to add various types of values:

* This will always return a string with read()
  
    $obj->set($keyname, $value);
	
    #This will only store the first item passed, "foo."
	
    $obj->set($keyname, 'foo', 'bar', 'baz');
	
* These will always return an array ref
  
    $obj->set('key', \@array);
	
    $obj->set('key', ['little', 'boy', 'blue']);
	
    $obj->set('key', $array_ref);

* These will always return a hash ref
  
    $obj->set('key', \%hash);

    $obj->set('key', { 'foo' => 'bar', 'baz' => 'qux' });

    $obj->set('key', $hash_ref);

=item $obj->append(KEY, VALUE);

The rules for the C<append()> method are basically the same as for C<set()>.

If you append a string to a string, the method will concatenate exactly what is passed to it, to the existing value.

If you append a list ref or hash ref, they are joined appropriately.

    $obj->append($key, $value);          #If existing value is scalar (or undef), concatenates.

    $obj->append($key, \@more_items);    #Existing value is an array ref - pushes all elements from the array reference.

    $obj->append($key, $more_items_ref); #Existing value is an array ref - pushes all elements from the array reference.

    $obj->append($key, \%hash);          #Existing value is hash ref - merges the keys/values from the new hash reference.

    $obj->append($key, $more_hash_ref);  #Existing value is hash ref - merges the keys/values from the new hash reference.


=item $obj->read(KEY);

The read method will return exactly what was stored. If you store a string, it returns a string. If store an array ref or hash ref, that is what you will get back.

* String stored
  
    my $value = $obj->get($key);
    print $obj->get($key);
    push(@my_array, $obj->get($key));
	
* Array reference stored
  
    my $array_ref = $obj->get($array_ref_key);
    print $array_ref->[0];
    print $array_ref->[1];  #Etc.
    push (@somelist, @$items_ref);
    my @convert_to_list = @{ $obj->get($array_ref_key) };
  
* Hash reference is stored

    my $hash_ref = $obj->get($hash_ref_key);
    print $hash_ref->{foo};
    print $hash_ref->{baz};
    #Merge to existing %hash
    @hash{ keys %$hash_ref } = values %_hash_ref;
    my %convert_to_hash = %{ $obj->get($hash_ref_key) };

=item $obj->delete(KEY);

Removes the specified key/value pair from the object.

=item $obj->exists(KEY);

Returns true if the key is in the object, it returns false if not.

=item $obj->allkeys;

Returns all the user-added keys in a sorted asciibetical order.


=item $obj->allvalues;

Returns all the user-added values sorted in asciibetical order of the keys.

=back

=head2 Local Installation

If your host does not allow you to install from CPAN, then you can install this module locally two ways:

=over 4

=item * Same Directory

In the same directory as your script, create a subdirectory called "Vigil". Then add these two lines, in this order, to your script:

	use lib '.';            # Add current directory to @INC
	use Vigil::Globals; # Now Perl can find the module in the same dir
	
	#Then call it as normal:
	my $qs_obj = Vigil::Globals->new;

=item * In a different directory

First, create a subdirectory called "Vigil" then add it to C<@INC> array through a C<BEGIN{}> block in your script:

	#!/usr/bin/perl
	BEGIN {
		push(@INC, '/path/on/server/to/Vigil');
	}
	
	use Vigil::Globals;
	
	#Then call it as normal:
	my $qs_obj = Vigil::Globals->new;

=back

=head1 AUTHOR

Jim Melanson (jmelanson1965@gmail.com).

Created: October, 2019.

Last Update: August 2025.

License: Use it as you will, and don't pretend you wrote it - be a mensch.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut




