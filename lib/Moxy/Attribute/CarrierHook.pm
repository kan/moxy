package Moxy::Attribute::CarrierHook;
use strict;
use warnings;
use base 'Class::Component::Attribute';

sub register {
    my($class, $plugin, $c, $method, $param, $code) = @_;

    $c->register_hook( "${method}_${param}", { plugin => $plugin, method => $method } );
}

1;
