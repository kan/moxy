package Moxy::Plugin::Server;
use strict;
use warnings;
use base 'Exporter';
use URI;
use HTML::Parser;
use URI::Escape;
use HTML::Entities;
use Scalar::Util qw/blessed/;
use LWP::UserAgent;
use HTML::Entities;
use URI::Escape;
use MIME::Base64;
use Params::Validate ':all';
our @EXPORT = qw/rewrite handle_request render_control_panel/;

sub rewrite {
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

sub render_control_panel {
    my ($base, $current_url) = @_;

    return sprintf(<<"...", encode_entities($current_url));
    <form method="get" action="$base">
        <input type="text" name="q" value="\%s" size="40" />
        <input type="submit" value="go" />
    </form>
...
}

sub handle_request {
    validate(
        @_,
        +{
            request => { isa => 'HTTP::Request' },
            context => { isa => 'Moxy' },
            config  => { type => HASHREF },
        }
    );
    my %args = @_;
    my $context = $args{context};

    my $uri = URI->new($args{request}->uri);
    $context->log(debug => "Request URI: $uri");

    my $base = $uri->clone;
    $base->query_form({});

    my $auth_header = $args{request}->header('Authorization');
    $context->log(debug => "Authorization header: $auth_header");
    if ($auth_header =~ /^Basic (.+)$/) {
        my $auth = decode_base64($1);
        $context->log(debug => "auth: $auth");
        my $url = +{$uri->query_form}->{q};
        $context->log(info => "REQUEST $auth, @{[ $url || '' ]}");
        my $response = _make_response(
            context  => $context,
            url      => $url,
            request  => $args{request},
            base_url => $base,
            user_id  => $auth,
            config   => $args{config}
        );
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

sub _make_response {
    validate(
        @_ => +{
            context  => { isa  => 'Moxy' },
            url      => qr{^https?://},
            request  => { isa  => 'HTTP::Request' },
            base_url => qr{^https?://},
            user_id  => { type => SCALAR },
            config   => { type => HASHREF },
        }
    );
    my %args = @_;
    my $context = $args{context};
    my $url = $args{url};
    my $base_url = $args{base_url};

    if ($url) {
        # do proxy
        my $res = _do_request(
            context => $context,
            url     => $url,
            request => $args{request},
            user_id => $args{user_id},
            config  => $args{config}
        );
        $context->log(debug => '-- response status: ' . $res->code);

        if ($res->code == 302) {
            # rewrite redirect
            $res->header( 'Location' => $base_url . '?q='
                  . uri_escape( $res->header('Location') ) );
        } else {
            my $content_type = $res->header('Content-Type');
            if ($content_type =~ /html/i) {
                $res->content( rewrite($base_url, $res->content, $url) );
            }
        }
        return $res;
    } else {
        # please input url.
        my $res = HTTP::Response->new(200, 'about:blank');
        $res->header('Content-Type' => 'text/html; charset=utf8');
        my $panel = render_control_panel($base_url, '');
        $res->content(qq{<html><head></head><body>$panel</body></html>});
        return $res;
    }
}

sub _do_request {
    validate(
        @_ => +{
            context  => { isa  => 'Moxy' },
            url      => qr{^https?://},
            request  => { isa  => 'HTTP::Request' },
            user_id  => { type => SCALAR },
            config   => { type => HASHREF },
        }
    );
    my %args = @_;
    my $context = $args{context};

    # make request
    my $req = $args{request}->clone;
    $req->uri($args{url});
    $req->header('Host' => URI->new($args{url})->host);

    $context->run_hook(
        'request_filter_process_agent',
        {   request => $req, # HTTP::Request object
            user    => $args{user_id},
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
                user    => $args{user_id},
            }
        );
        if ($response) {
            return $response; # finished
        }
    }

    # do request
    my $ua = LWP::UserAgent->new(
        timeout       => $args{config}->{timeout} || 10,
        max_redirects => 0,
    );
    my $response = $ua->request($req);
    my $bodyref = \($response->content);
    for my $hook ('response_filter', "response_filter_$carrier") {
        $context->run_hook(
            $hook,
            {   response    => $response, # HTTP::Response object
                content_ref => $bodyref, # response body's scalarref.
                agent       => $agent,
                user        => $args{user_id},
            }
        );
    }
    $response->content($$bodyref);
    $response;
}

1;
