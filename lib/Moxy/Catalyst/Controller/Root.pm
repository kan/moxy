package Moxy::Catalyst::Controller::Root;
use strict;
use warnings;
use base 'Catalyst::Controller';
__PACKAGE__->config->{namespace} = '';

use Moxy;
use YAML;

sub Catalyst::Request::as_http_request {
    my $self = shift;
    HTTP::Request->new( $self->method, $self->uri, $self->headers, $self->read());
}

sub Catalyst::Response::set_http_response {
    my ($self, $res) = @_;
    $self->status( $res->code );
    $self->headers( $res->headers );
    $self->body( $res->content );
    $self;
}

sub default : Private {
    my ( $self, $c ) = @_;

    my $config = YAML::LoadFile($c->path_to('config.yaml'));
    my $moxy = Moxy->new($config);
    local *Moxy::assets_path = sub {
        $c->path_to('assets')
    };
    my $res = $moxy->handle_request(request => $c->req->as_http_request);
    $c->res->set_http_response( $res );
}

sub end : ActionClass('RenderView') {}

1;
