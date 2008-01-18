package Moxy::Storage;
use strict;
use warnings;
use Carp;

sub new { croak 'this is abstract method' }
sub set { croak 'this is abstract method' }
sub get { croak 'this is abstract method' }

1;
