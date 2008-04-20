package Moxy::Component::Context;
use strict;
use warnings;

my $context;

sub new {
    my $class = shift;
    my $self = $class->NEXT('new' => @_);
    $context = $self;
    $self;
}

sub context { $context }

1;
