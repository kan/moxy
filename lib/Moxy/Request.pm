package Moxy::Request;
use strict;
use warnings;
use base qw/Plack::Request/;

sub as_http_request {
    my $self = shift;
    return HTTP::Request->new(
        $self->method,
        $self->uri,
        $self->headers,
        $self->content,
    );
}

1;
