package Moxy::Plugin::Server::HTTPProxy;
use strict;
use warnings;
use utf8;
use Moxy::Plugin::Server;
use Encode;
use HTTP::Proxy ':log';
use HTTP::Proxy::HeaderFilter::simple;
use HTTP::Proxy::BodyFilter::complete;
use Scalar::Util qw/blessed/;
use LWP::UserAgent;
use URI;
use HTML::Entities;
use URI::Escape;
use MIME::Base64;

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

                my $uri = URI->new($request->uri);
                $context->log(debug => "Request URI: $uri");

                my $base = $uri->clone;
                $base->query_form({});

                my $auth_header = $request->header('Authorization');
                $context->log(debug => "Authorization header: $auth_header");
                if ($auth_header =~ /^Basic (.+)$/) {
                    my $auth = decode_base64($1);
                    $context->log(debug => "auth: $auth");
                    my $url = +{$uri->query_form}->{q};
                    $context->log(info => "REQUEST $auth, @{[ $url || '' ]}");
                    my $response =
                    $class->_make_response( $context, $url, $request, $base,
                        $auth, $config );
                    return $filter->proxy->response($response); # finished
                } else {
                    my $response = HTTP::Response->new(401, 'Moxy needs authentication');
                    $response->header( 'WWW-Authenticate' =>
qq{Basic realm="Moxy needs basic auth.Only for identification.Password is dummy."}
                    );
                    $response->content('authentication required');
                    return $filter->proxy->response($response); # finished
                }
            }
        ),
    );

    $context->log(info => sprintf("Moxy running at http://%s:%d/\n", $proxy->host, $proxy->port));

    $proxy->start;
}

sub _ua {
    my ($class, $config) = @_;

    my $ua = LWP::UserAgent->new(
        timeout       => $config->{timeout} || 10,
        max_redirects => 0,
    );
    $ua;
}

sub _make_response {
    my ($class, $context, $url, $src_req, $base, $auth, $config) = @_;

    if ($url) {
        # do proxy
        my $res = $class->_do_request($context, $src_req, $url, $auth, $config);
        $context->log(debug => '-- response status: ' . $res->code);

        if ($res->code == 302) {
            # rewrite redirect
            $res->header( 'Location' => $base . '?q='
                  . uri_escape( $res->header('Location') ) );
        } else {
            my $content_type = $res->header('Content-Type');
            if ($content_type =~ /html/i) {
                $res->content( rewrite($base, $res->content, $url) );
            }
        }
        return $res;
    } else {
        # please input url.
        my $res = HTTP::Response->new(200, 'about:blank');
        $res->header('Content-Type' => 'text/html; charset=utf8');
        my $panel = render_control_panel($base, '');
        $res->content(qq{<html><head></head><body>$panel</body></html>});
        return $res;
    }
}

sub _do_request {
    my ($class, $context, $src_req, $url, $auth, $config) = @_;

    # make request
    my $req = $src_req->clone;
    $req->uri($url);
    $req->header('Host' => URI->new($url)->host);

    $context->run_hook(
        'request_filter_process_agent',
        {   request => $req, # HTTP::Request object
            user    => $auth,
        }
    );
    my $agent = $context->get_ua_info($req->header('User-Agent'));
    my $carrier = $agent->{agent} ? HTTP::MobileAgent->new($agent->{agent})->carrier : 'N';
    for my $hook ('request_filter', "request_filter_$carrier") {
        my $response = $context->run_hook_and_get_response(
            $hook,
            +{
                request => $req,    # HTTP::Request object
                agent   => $agent,
                user    => $auth,
            }
        );
        if ($response) {
            return $response; # finished
        }
    }

    # do request
    my $ua = $class->_ua($config);
    my $response = $ua->request($req);
    my $bodyref = \($response->content);
    for my $hook ('response_filter', "response_filter_$carrier") {
        $context->run_hook(
            $hook,
            {   response    => $response, # HTTP::Response object
                content_ref => $bodyref, # response body's scalarref.
                agent       => $agent,
                user        => $auth,
            }
        );
    }
    $response->content($$bodyref);
    $response;
}

1;
__END__

=head1 NAME

Moxy::Server::HTTPProxy - proxy server based on HTTP::Proxy

=head1 AUTHORS

Tokuhiro Matsuno

=head1 SEE ALSO

L<Moxy>, L<HTTP::Proxy>

