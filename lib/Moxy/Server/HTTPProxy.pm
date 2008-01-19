package Moxy::Server::HTTPProxy;
use strict;
use warnings;
use utf8;
use Encode;
use HTTP::Proxy ':log';
use HTTP::Proxy::BodyFilter::simple;
use HTTP::Proxy::HeaderFilter::simple;
use HTTP::Proxy::BodyFilter::complete;
use Scalar::Util qw/blessed/;

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
        request  => HTTP::Proxy::HeaderFilter::simple->new(
            sub {
                my ($filter, $x, $request) = @_;

                my $response = $context->run_hook_and_get_response(
                    'request_filter_before_auth',
                    +{
                        request => $request,    # HTTP::Request object
                    }
                );
                if ($response) {
                    return $filter->proxy->response($response); # finished
                }

                # password is ignored by Moxy.
                my ($user, $pass) = $filter->proxy->hop_headers->proxy_authorization_basic();
                if ($user) {
                    $filter->proxy->stash(user => $user);
                } else {
                    my $response = HTTP::Response->new( 407, 'Moxy Authentication required' );
                    $response->header('Proxy-Authenticate' => 'Basic realm="Moxy(password is dummy)"');
                    return $filter->proxy->response($response);
                }

                $context->run_hook(
                    'request_filter_process_agent',
                    {   request => $request, # HTTP::Request object
                        user    => $user,
                    }
                );

                my $agent = $context->get_ua_info($_[1]->header('User-Agent'));
                my $carrier = $agent->{agent} ? HTTP::MobileAgent->new($agent->{agent})->carrier : 'N';

                for my $hook ('request_filter', "request_filter_$carrier") {
                    my $response = $context->run_hook_and_get_response(
                        $hook,
                        +{
                            request => $request,    # HTTP::Request object
                            agent   => $agent,
                            user    => $user,
                        }
                    );
                    if ($response) {
                        return $filter->proxy->response($response); # finished
                    }
                }
            }
        ),
        response => HTTP::Proxy::BodyFilter::complete->new,
        response => HTTP::Proxy::BodyFilter::simple->new(
            make_response_filter($context, 'response_filter')
        ),
        response => HTTP::Proxy::HeaderFilter::simple->new(
            make_response_filter($context, 'response_filter_header')
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

sub make_response_filter {
    my ($context, $key) = @_;

    return sub {
        my ($filter, $bodyref, $response) = @_;

        my $agent = $context->get_ua_info($response->request->header('User-Agent'));
        my $carrier = $agent->{agent} ? HTTP::MobileAgent->new($agent->{agent})->carrier : 'N';

        for my $hook ($key, "${key}_$carrier") {
            $context->run_hook(
                $hook,
                {   response    => $response,
                    content_ref => $bodyref,
                    agent       => $agent,
                    user        => $filter->proxy->stash('user'),
                }
            );
        }
    };
}

1;
__END__

=head1 NAME

Moxy::Server::HTTPProxy - proxy server based on HTTP::Proxy

=head1 AUTHORS

Tokuhiro Matsuno

=head1 SEE ALSO

L<Moxy>, L<HTTP::Proxy>

