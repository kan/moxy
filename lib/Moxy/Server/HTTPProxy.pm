package Moxy::Server::HTTPProxy;
use strict;
use warnings;
use utf8;
use Encode;
use HTTP::Proxy ':log';
use HTTP::Proxy::Headersimple;
use HTTP::Proxy::Bodycomplete;
use URI;
use Carp;

sub run {
    my ($class, $context, $config, ) = @_;

    $context->log(debug => "setup proxy server");

    my $proxy = HTTP::Proxy->new(
        port        => $config->{port},
        host        => $config->{host} || '',
        max_clients => $config->{max_clients},
    );

    $proxy->push_filter(
        mime     => undef,
        response => HTTP::Proxy::Bodycomplete->new,
        request  => HTTP::Proxy::Headersimple->new(
            sub {
                my ($filter, $x, $request) = @_;
                # $request is instance of HTTP::Request.
                my $response = $context->handle_request(
                    request => $request,
                );
                return $filter->proxy->response($response);
            }
        ),
    );

    $context->log(info => sprintf("Moxy running at http://%s:%d/\n", $proxy->host, $proxy->port));

    $proxy->start;
}

1;
__END__

=encoding utf8

=head1 NAME

Moxy::Plugin::Server::HTTPProxy - proxy server based on HTTP::Proxy

=head1 SYNOPSIS

    - module: Server::HTTPProxy
      config:
        port: 10000
        host: localhost
        max_clients: 80
        timeout: 10

=head1 DESCRIPTION

HTTP::Proxy をつかったプロキシサーバ。

=head1 AUTHORS

Tokuhiro Matsuno

=head1 SEE ALSO

L<Moxy>, L<HTTP::Proxy>

