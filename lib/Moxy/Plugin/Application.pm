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

            if ( $uri->host eq $base_host && ($uri->port||80) == $base_port) {
                my $auth_header = $args->{request}->header('Authorization');
                if ($auth_header =~ /^Basic (.+)$/) {
                    my $auth = decode_base64($1);
                    $context->log(debug => "auth: $auth");
                    my $url = +{$uri->query_form}->{q};
                    $context->log(info => "REQUEST $auth, @{[ $url || '' ]}");
                    my $response =
                      $class->_make_response( $context, $url, $args->{request},
                        $base, $auth );
                    return $args->{filter}->proxy->response($response);
                } else {
                    my $response = HTTP::Response->new(401, 'Moxy needs authentication');
                    $response->header( 'WWW-Authenticate' =>
qq{Basic realm="Moxy needs basic auth.Only for identification.Password is dummy."}
                    );
                    $response->content('authentication required');
                    return $args->{filter}->proxy->response($response);
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
    my $ua = LWP::UserAgent->new(
        agent         => "Moxy/$Moxy::VERSION",
        timeout       => $TIMEOUT,
        max_redirects => 0,
    );
    $ua->proxy(['http'] => 'http://localhost:9999/');
    $ua;
}

sub _make_response {
    my ($class, $context, $url, $src_req, $base, $auth) = @_;

    if ($url) {
        my $req = $src_req->clone;
        $req->uri($url);
        $req->header('Host' => URI->new($url)->host);
        $req->header('Proxy-Authorization' => "Basic @{[ encode_base64 $auth ]}");
        my $ua = $class->_ua;
        my $res = $ua->request($req);
        if ($res->code == 302) {
            my $myres = HTTP::Response->new(200, 'Redirect by Moxy');
            $myres->header('Content-Type' => 'text/html; charset=utf8');
            $myres->content(
                sprintf(
q{<html><head></head><body>Redirect to <a href="%s?q=%s">%s</a></body></html>},
                    $base, uri_escape($res->header('Location')),
                    encode_entities($res->header('Location'))
                )
            );
            return $myres;
        } else {
            if ($res->header('Content-Type') =~ /html/i) {
                $res->content( _rewrite($base, $res->content, $url) );
            }
        }
        return $res;
    } else {
        my $res = HTTP::Response->new(200, 'about:blank');
        $res->header('Content-Type' => 'text/html; charset=utf8');
        my $panel = $class->_render_control_panel($base, '');
        $res->content(qq{<html><head></head><body>$panel</body></html>});
        return $res;
    }
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

