use strict;
use warnings;
use Test::More;
use Moxy::Storage::DBM_File;
eval "use GDBM_File";
plan skip_all => 'this test requires GDBM_File' if $@;
plan tests => 1;

package Foo;
sub log { }

package main;
my $storage = Moxy::Storage::DBM_File->new(bless({}, 'Foo'));
$storage->set('foo', 'bar');
is $storage->get('foo'), 'bar';

