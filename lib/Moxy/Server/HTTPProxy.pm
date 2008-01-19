package Moxy::Server::HTTPProxy;
use strict;
use warnings;
use utf8;
use Encode;
use HTTP::Proxy ':log';
use HTTP::Proxy::HeaderFilter::simple;
use HTTP::Proxy::BodyFilter::complete;
use Scalar::Util qw/blessed/;
use LWP::UserAgent;
use URI;
use HTML::Parser;
use HTML::Entities;
use URI::Escape;
use MIME::Base64;

our $TIMEOUT = 10; # TODO: configurable

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
        my $bitmask = 0;
        for my $const ( @{$config->{logmask}} ) {
            $bitmask |= HTTP::Proxy->$const;
        }
        $proxy->logmask($bitmask);
    }

    $context->register_hook(
        control_panel => sub {
            my ($context, $args) = @_;

            my $base = URI->new($args->{response}->request->uri);
            $base->query_form({});
            return $class->_render_control_panel($base, $args->{response}->request->uri);
        },
    );

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
                        $auth );
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

    $self->{proxy} = $proxy;

    return $self;
}

sub run {
    my ($self, $context) = @_;

    my $proxy = $self->{proxy};

    $context->log(info => sprintf("Moxy running at http://%s:%d/\n", $proxy->host, $proxy->port));

    $proxy->start;
}

sub _render_control_panel {
    my ($class, $base, $current_url) = @_;

    return sprintf(<<"...", encode_entities($current_url));
    <form method="get" action="$base">
        <input type="text" name="q" value="\%s" size="40" />
        <input type="submit" value="go" />
    </form>
...
}

sub _ua {
    my ($class, $proxy_url) = @_;

    my $ua = LWP::UserAgent->new(
        timeout       => $TIMEOUT,
        max_redirects => 0,
    );
    $ua;
}

sub _make_response {
    my ($class, $context, $url, $src_req, $base, $auth) = @_;

    if ($url) {
        # do proxy
        my $res = $class->_do_request($context, $src_req, $url, $auth);
        $context->log(debug => '-- response status: ' . $res->code);

        if ($res->code == 302) {
            # rewrite redirect
            $res->header( 'Location' => $base . '?q='
                  . uri_escape( $res->header('Location') ) );
        } else {
            my $content_type = $res->header('Content-Type');
            if ($content_type =~ /html/i) {
                $res->content( _rewrite($base, $res->content, $url) );
            }
        }
        return $res;
    } else {
        # please input url.
        my $res = HTTP::Response->new(200, 'about:blank');
        $res->header('Content-Type' => 'text/html; charset=utf8');
        my $panel = $class->_render_control_panel($base, '');
        $res->content(qq{<html><head></head><body>$panel</body></html>});
        return $res;
    }
}

sub _do_request {
    my ($class, $context, $src_req, $url, $auth) = @_;

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
    my $ua = $class->_ua;
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

sub _rewrite {
    my ($base, $html, $url) = @_;

    my $output = '';
    my $base_url = URI->new($url);
    my $parser = HTML::Parser->new(
        api_version   => 3,
        start_h       => [ sub {
            my ($tagname, $attr, $orig) = @_;

            if ($tagname eq 'a' || $tagname eq 'A') {
                $output .= "<$tagname";
                my @parts;
                my $href = delete $attr->{href};
                if ($href) {
                    $output .= " ";
                    push @parts,
                      sprintf( qq{href="$base?q=%s"},
                        uri_escape(URI->new($href)->abs($base_url)) );
                }
                push @parts, map { sprintf qq{%s="%s"}, encode_entities($_), encode_entities($attr->{$_}) } keys %$attr;
                $output .= join " ", @parts;
                $output .= ">";
            } elsif ($tagname =~ /form/i) {
                $output .= "<$tagname";
                my @parts;
                my $action = delete $attr->{action};
                if ($action) {
                    $output .= " ";
                    push @parts, sprintf(qq{action="$base?q=%s"},
                        uri_escape(URI->new($action)->abs($base_url))
                    );
                }
                push @parts, map { sprintf qq{$_="%s"}, encode_entities($attr->{$_}) } keys %$attr;
                $output .= join " ", @parts;
                $output .= ">";
            } elsif ($tagname =~ /img/i) {
                $output .= "<$tagname";
                my @parts;
                my $src = delete $attr->{src};
                if ($src) {
                    $output .= " ";
                    push @parts, sprintf(qq{src="$base?q=%s"},
                        uri_escape(URI->new($src)->abs($base_url))
                    );
                }
                push @parts, map { sprintf qq{%s="%s"}, encode_entities($_), encode_entities($attr->{$_}) } grep !/^\/$/, keys %$attr;
                $output .= join " ", @parts;
                $output .= ">";
            } else {
                $output .= $orig;
                return;
            }
        }, "tagname, attr, text" ],
        end_h  => [ sub { $output .= shift }, "text"],
        text_h => [ sub { $output .= shift }, "text"],
    );

    $parser->boolean_attribute_value('__BOOLEAN__');
    $parser->parse($html);
    $output;
}

1;
__END__

=head1 NAME

Moxy::Server::HTTPProxy - proxy server based on HTTP::Proxy

=head1 AUTHORS

Tokuhiro Matsuno

=head1 SEE ALSO

L<Moxy>, L<HTTP::Proxy>

