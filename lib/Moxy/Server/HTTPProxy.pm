package Moxy::Server::HTTPProxy;
use strict;
use warnings;
use utf8;
use Encode;
use HTTP::Proxy ':log';
use HTTP::Proxy::BodyFilter::simple;
use HTTP::Proxy::HeaderFilter::simple;
use HTTP::Proxy::BodyFilter::complete;

sub new {
    my ($class, $context, $config) = @_;
    my $self = bless {config => $config}, $class;

    $context->log(debug => "setup proxy server");

    my $proxy = HTTP::Proxy->new(
        port        => $config->{port},
        host        => $config->{host} || '',
        max_clients => $config->{max_clients},
    );

    if ($config->{logmask}) {
        my $mask = 0; # this is bitmask.
        for my $const ( @{$config->{logmask}} ) {
            $mask |= HTTP::Proxy->$const;
        }
        $proxy->logmask($mask);
    }

    $proxy->push_filter(
        mime     => undef,
        response => HTTP::Proxy::BodyFilter::complete->new,
        request  => HTTP::Proxy::HeaderFilter::simple->new(
            sub {
                my ($filter, $x, $request) = @_;

                $context->run_hook(
                    'request_filter_before_auth',
                    {   request => $request, # HTTP::Request object
                        filter  => $filter, # filter object itself
                    }
                );
                return if $filter->proxy->response;

                my ($user, $pass) = $_[0]->proxy->hop_headers->proxy_authorization_basic();
                if ($user) {
                    $_[0]->proxy->stash(user => $user);
                } else {
                    my $response = HTTP::Response->new( 407, 'Moxy Authentication required' );
                    $response->header('Proxy-Authenticate' => 'Basic realm="Moxy(password is dummy)"');
                    return $_[0]->proxy->response($response);
                }

                $context->run_hook(
                    'request_filter_process_agent',
                    {   request => $_[2], # HTTP::Request object
                        filter  => $_[0], # filter object itself
                    }
                );

                my $agent = $context->get_ua_info($_[1]->header('User-Agent'));
                my $carrier = $agent->{agent} ? HTTP::MobileAgent->new($agent->{agent})->carrier : 'N';

                for my $hook ('request_filter', "request_filter_$carrier") {
                    $context->run_hook(
                        $hook,
                        {   request => $_[2], # HTTP::Request object
                            filter  => $_[0], # filter object itself
                            agent   => $agent,
                        }
                    );
                }
            }
        ),
        response => HTTP::Proxy::BodyFilter::simple->new(
            sub {
                my $agent = $context->get_ua_info($_[2]->request->header('User-Agent'));
                my $carrier = $agent->{agent} ? HTTP::MobileAgent->new($agent->{agent})->carrier : 'N';

                for my $hook ('response_filter', "response_filter_$carrier") {
                    $context->run_hook(
                        $hook,
                        {   response    => $_[2], # HTTP::Response object
                            content_ref => $_[1], # response body's scalarref.
                            filter      => $_[0], # filter object itself.
                            agent       => $agent,
                        }
                    );
                }
            }
        ),
        response => HTTP::Proxy::HeaderFilter::simple->new(
            sub {
                my $agent = $context->get_ua_info($_[2]->request->header('User-Agent'));
                my $carrier = $agent->{agent} ? HTTP::MobileAgent->new($agent->{agent})->carrier : 'N';

                for my $hook ('response_filter_header', "response_filter_header_$carrier") {
                    $context->run_hook(
                        $hook,
                        {   response    => $_[2],
                            content_ref => $_[1],
                            filter      => $_[0],
                            agent       => $agent,
                        }
                    );
                }
            }
        ),
    );

    $self->{proxy} = $proxy;

    return $self;
}

sub run {
    my ($self, $context) = @_;

    my $proxy = $self->{proxy};

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

