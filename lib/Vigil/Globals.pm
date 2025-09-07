package Vigil::Globals;

use strict;
use warnings;
use JSON;

our $VERSION = '1.3.0';

sub new {
    my ($class) = @_;
    my $self = {
        _error => [],
    };
    bless $self, $class;
    return $self;
}

sub set { $_[0]->{$_[1]} = $_[2] if defined $_[1]; }

sub append {
    my ($self, @args) = @_;

    # Flatten single argument if it's a hash or array ref
    if (@args == 1) {
        if (ref $args[0] eq 'ARRAY') {
            @args = @{$args[0]};
        }
        elsif (ref $args[0] eq 'HASH') {
            @args = %{$args[0]};
        }
    }

    my %pairs = @args;

    for my $key (keys %pairs) {
        my $val      = $pairs{$key};
        my $existing = $self->{$key};

        unless (defined $existing) {
            $self->{$key} = $val;
            next;
        }

        # Scalar handling
        if (!ref $existing) {
            if (!ref $val) {
                $self->{$key} .= $val;
            }
            elsif (ref $val eq 'ARRAY') {
                $self->{$key} = [ $existing, @$val ];
            }
            elsif (ref $val eq 'HASH') {
                push @{ $self->{_error} }, "Cannot append hashref to scalar key '$key'";
            }
            next;
        }

        # Array handling
        if (ref $existing eq 'ARRAY') {
            $self->_merge_array($existing, $val);
            next;
        }

        # Hash handling
        if (ref $existing eq 'HASH') {
            if (!ref $val) {
                push @{ $self->{_error} }, "Cannot append scalar to hash key '$key'";
            }
            elsif (ref $val eq 'ARRAY') {
                if (@$val % 2) {
                    push @{ $self->{_error} }, "Array must have even number of elements to append as hash key '$key'";
                } else {
                    while (@$val) {
                        my $k = shift @$val;
                        my $v = shift @$val;
                        $existing->{$k} = $v;
                    }
                }
            }
            elsif (ref $val eq 'HASH') {
                $self->_merge_hash($existing, $val);
            }
            next;
        }

        push @{ $self->{_error} }, "Unsupported type for key '$key'";
    }
}

sub append_json {
    my ($self, $json) = @_;
    return unless defined $json && length $json;

    my $data = eval { JSON::decode_json($json) };
    if ($@) {
        push @{ $self->{_error} }, "Failed to parse JSON: $@";
        return;
    }

    unless (ref $data eq 'HASH') {
        push @{ $self->{_error} }, "Top-level JSON must be an object/hash";
        return;
    }

    for my $key (keys %$data) {
        my $val = $data->{$key};

        if (exists $self->{$key}) {
            my $existing = $self->{$key};

            if (!ref($existing) && !ref($val)) {
                # Concatenate scalars
                $self->{$key} .= $val;
            }
            elsif (ref($existing) eq 'ARRAY' && ref($val) eq 'ARRAY') {
                # Merge arrays
                $self->_merge_array($existing, $val);
            }
            elsif (ref($existing) eq 'HASH' && ref($val) eq 'HASH') {
                # Merge hashes recursively
                $self->_merge_hash($existing, $val);
            }
            else {
                # Incompatible types → overwrite
                $self->{$key} = $val;
            }
        }
        else {
            # Key doesn't exist → create it
            $self->{$key} = $val;
        }
    }
}

sub export_as_json { return encode_json({ map { $_ => $_[0]->{$_} } grep { $_ ne '_error' } keys %{$_[0]} }); }

sub to_jsonORIGINAL {
    my ($self) = @_;
    
    # Copy all keys except _error
    my %data = map { $_ => $self->{$_} } grep { $_ ne '_error' } keys %$self;

    # Convert to JSON string
    return encode_json(\%data);
}

sub read {
    my ($self, $key) = @_;
    return unless defined $key;            
    my $val = $self->{$key};

    return $val if ref($val) eq 'ARRAY' || ref($val) eq 'HASH';

    return defined $val ? $val : '';
}

sub delete { delete $_[0]->{$_[1]} unless $_[1] =~ /^_/; }

sub empty { delete $_[0]->{$_} for grep { $_ !~ /^_/ } keys %{$_[0]}; }

sub exists { return exists $_[0]->{$_[1]}; }

sub allkeys { return sort { lc($a) cmp lc($b) } grep { $_ !~ /^_/ } keys %{$_[0]}; }

sub allvalues { return map { $_[0]->{$_} } sort { lc($a) cmp lc($b) } grep { $_ !~ /^_/ } keys %{$_[0]}; }

sub _merge_array {
    my ($self, $target, $source) = @_;

    if (!ref $source) {
        push @$target, $source;
    }
    elsif (ref $source eq 'ARRAY') {
        push @$target, @$source;
    }
    else {
        push @{ $self->{errors} }, "Cannot merge non-array into array";
    }
}

sub _merge_hash {
    my ($self, $target, $source) = @_;

    for my $k (keys %$source) {
        if (exists $target->{$k} && ref $target->{$k} eq 'HASH' && ref $source->{$k} eq 'HASH') {
            $self->_merge_hash($target->{$k}, $source->{$k});  # recursive merge
        } else {
            $target->{$k} = $source->{$k};
        }
    }
}

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

=item $obj->append_json(JSON_STRING);

No key names are needed, they are taken from the JSON string itself. This method will merge the contents of the JSON string with existing keys, or create new keys if none exist.

I<NOTE: If you want to replace data with the contents of the JSON string, you should first C<delete(KEYNAME)> that key/value pair or completely C<empty()> the object.>

=item my $json_string = $obj->export_as_json;

This will export the entire contents of the object (except for the errors) to a propely formatted JSON string.

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
