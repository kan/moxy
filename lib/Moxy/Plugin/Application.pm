package Moxy::Plugin::Application;
use strict;
use warnings;
use LWP::UserAgent;
use URI;
use HTML::Parser;
use HTML::Entities;
use URI::Escape;
use MIME::Base64;

our $TIMEOUT = 10;

# TODO: support https

sub register {
    my ($class, $context) = @_;

    my $base_host = $context->config->{global}->{application}->{host};
    my $base_port = $context->config->{global}->{application}->{port};
    my $base = "http://$base_host:$base_port/";

    $context->register_hook(
        request_filter_before_auth => sub {
            my ($context, $args) = @_;

            my $uri = URI->new($args->{request}->uri);
            $context->log(debug => "Request URI: $uri");

            if ( $uri->host eq $base_host && ($uri->port||80) == $base_port) {
                my $auth_header = $args->{request}->header('Authorization');
                $context->log(debug => "Authorization header: $auth_header");
                if ($auth_header =~ /^Basic (.+)$/) {
                    my $auth = decode_base64($1);
                    $context->log(debug => "auth: $auth");
                    my $url = +{$uri->query_form}->{q};
                    $context->log(info => "REQUEST $auth, @{[ $url || '' ]}");
                    my $response =
                      $class->_make_response( $context, $url, $args->{request},
                        $base, $auth );
                    return $response;
                } else {
                    my $response = HTTP::Response->new(401, 'Moxy needs authentication');
                    $response->header( 'WWW-Authenticate' =>
qq{Basic realm="Moxy needs basic auth.Only for identification.Password is dummy."}
                    );
                    $response->content('authentication required');
                    return $response;
                }
            }
            return; # DECLINED
        },
        control_panel => sub {
            my ($context, $args) = @_;

            return $class->_render_control_panel($base, $args->{response}->request->uri);
        },
    );
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
        my $res = $class->do_request($context, $src_req, $url, $auth);
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

sub do_request {
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
    my $response_filter = sub {
        my $key = shift;
        for my $hook ($key, "${key}_$carrier") {
            $context->run_hook(
                $hook,
                {   response    => $response, # HTTP::Response object
                    content_ref => $bodyref, # response body's scalarref.
                    agent       => $agent,
                    user        => $auth,
                }
            );
        }
    };
    $response_filter->('response_filter');
    $response_filter->('response_filter_header');
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

Moxy::Plugin::Application - web proxy mode.

=head1 SYNOPSIS

  - module: ControlPanel


=head1 DESCRIPTION

This is web proxy mode plugin.

=head1 DISCLAIMER

THIS MODULE IS EXPERIMENTAL. STILL ALPHA QUALITY.

=head1 KNOWN BUGS

Basic 認証かかってると、うまく見えない。

=head1 AUTHOR

    Tokuhiro Matsuno

=head1 SEE ALSO

L<Moxy>

