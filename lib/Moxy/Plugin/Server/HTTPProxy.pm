package Moxy::Plugin::Server::HTTPProxy;
use strict;
use warnings;
use utf8;
use Moxy::Plugin::Server;
use Encode;
use HTTP::Proxy ':log';
use HTTP::Proxy::HeaderFilter::simple;
use HTTP::Proxy::BodyFilter::complete;
use URI;

sub register {
    my ($class, $context, $config) = @_;

    $context->register_hook(
        control_panel => sub {
            my ($context, $args) = @_;

            my $base = URI->new($args->{response}->request->uri);
            $base->query_form({});
            return render_control_panel($base, $args->{response}->request->uri);
        },
        run_server => sub { $class->run_server($context, $config) },
    );
}

sub run_server {
    my ($class, $context, $config) = @_;

    $context->log(debug => "setup proxy server");

    my $proxy = HTTP::Proxy->new(
        port        => $config->{port},
        host        => $config->{host} || '',
        max_clients => $config->{max_clients},
    );

    if ($config->{logmask}) {
        my $bitmask = 0;
        for my $const ( @{$config->{logmask}} ) {
            $bitmask |= HTTP::Proxy->$const;
        }
        $proxy->logmask($bitmask);
    }

    $proxy->push_filter(
        mime     => undef,
        response => HTTP::Proxy::BodyFilter::complete->new,
        request  => HTTP::Proxy::HeaderFilter::simple->new(
            sub {
                my ($filter, $x, $request) = @_;
                # $request is instance of HTTP::Request.
                my $response = handle_request(
                    request => $request,
                    context => $context,
                    config  => $config,
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

=head1 NAME

Moxy::Server::HTTPProxy - proxy server based on HTTP::Proxy

=head1 AUTHORS

Tokuhiro Matsuno

=head1 SEE ALSO

L<Moxy>, L<HTTP::Proxy>

