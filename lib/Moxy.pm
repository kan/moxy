package Moxy;
use strict;
use warnings;
use Class::Component;

our $VERSION = '0.30';

use Path::Class;
use YAML;
use Encode;
use FindBin;
use UNIVERSAL::require;
use Carp;
use Scalar::Util qw/blessed/;
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
use URI::Heuristic qw(uf_uristr);
use File::Spec::Functions;
use YAML;
use HTTP::MobileAttribute plugins => [
    qw/CarrierLetter IS/,
    {
        module => 'Display',
        config => {
            DoCoMoMap => YAML::LoadFile(
                catfile( 'assets', 'common', 'docomo-display-map.yaml' )
            )
        }
    },
];

__PACKAGE__->load_components(qw/Plaggerize Autocall::InjectMethod Context/);

sub new {
    my ($class, $config) = @_;

    my $self = $class->NEXT( 'new' => { config => $config } );

    $self->_init_storage;

    return $self;
}

sub run {
    my $self = shift;

    unless ($self->can('run_server')) {
        die "Oops. please load Server Module\n";
    }

    $self->run_server();
}

sub assets_path {
    my $self = shift;

    return $self->{__assets_path} ||= do {
        $self->conf->{global}->{assets_path}
            || dir( $FindBin::RealBin, 'assets' )->stringify;
    };
}

# -------------------------------------------------------------------------

sub _init_storage {
    my ($self, ) = @_;

    my $mod = $self->{config}->{global}->{storage}->{module};
       $mod = $mod ? "Moxy::Storage::$mod" : 'Moxy::Storage::DBM_File';
    $mod->use or die $@;
    $self->{storage} = $mod->new($self, $self->conf->{global}->{storage} || {});
}

sub storage { shift->{storage} }

# -------------------------------------------------------------------------

sub run_hook_and_get_response {
    my ($self, $hook, @args) = @_;

    $self->log(debug => "Run hook and get response: $hook");
    for my $action (@{$self->class_component_hooks->{$hook}}) {
        my $code = $action->{plugin}->can($action->{method});
        my $response = $code->($action->{plugin}, $self, @args);
        return $response if blessed $response && $response->isa('HTTP::Response');
    }
    return; # not finished yet
}

sub rewrite {
    my ($base, $html, $url) = @_;

    my $output = '';
    my $base_url = URI->new($url);
    my $parser = HTML::Parser->new(
        api_version   => 3,
        start_h       => [ sub {
            my ($tagname, $attr, $orig) = @_;

            if ($tagname eq 'a' || $tagname eq 'A' || $tagname =~ /link/i) {
                $output .= "<$tagname";
                my @parts;
                my $href = delete $attr->{href};
                if ($href) {
                    push @parts,
                      sprintf( qq{href="$base?q=%s"},
                        uri_escape(URI->new($href)->abs($base_url)) );
                }
                push @parts, map { sprintf qq{%s="%s"}, encode_entities($_), encode_entities($attr->{$_}) } keys %$attr;
                $output .= " " . join " ", @parts;
                $output .= ">";
            } elsif ($tagname =~ /form/i) {
                $output .= "<$tagname";
                my @parts;
                my $action = delete $attr->{action};
                if ($action) {
                    push @parts, sprintf(qq{action="$base?q=%s"},
                        uri_escape(URI->new($action)->abs($base_url))
                    );
                }
                push @parts, map { sprintf qq{$_="%s"}, encode_entities($attr->{$_}) } keys %$attr;
                $output .= " " . join " ", @parts;
                $output .= ">";
            } elsif ($tagname =~ /(img|script)/i) {
                $output .= "<$tagname";
                my @parts;
                my $src = delete $attr->{src};
                if ($src) {
                    push @parts, sprintf(qq{src="$base?q=%s"},
                        uri_escape(URI->new($src)->abs($base_url))
                    );
                }
                push @parts, map { sprintf qq{%s="%s"}, encode_entities($_), encode_entities($attr->{$_}) } grep !/^\/$/, keys %$attr;
                $output .= " " . join " ", @parts;
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
    <script>
        window.onload = function () {
            document.getElementById('moxy_url').focus();
        };
    </script>
    <form method="get" action="$base">
        <input type="text" name="q" value="\%s" size="40" id="moxy_url" />
        <input type="submit" value="go" />
    </form>
...
}

sub handle_request {
    my $self = shift;
    my %args = validate(
        @_,
        +{
            request => { isa => 'HTTP::Request' },
        }
    );

    my $uri = URI->new($args{request}->uri);
    $self->log(debug => "Request URI: $uri");

    my $base = $uri->clone;
    $base->query_form({});

    my $auth_header = $args{request}->header('Authorization');
    $self->log(debug => "Authorization header: $auth_header");
    if ($auth_header =~ /^Basic (.+)$/) {
        my $auth = decode_base64($1);
        $self->log(debug => "auth: $auth");
        my $url = uf_uristr(+{$uri->query_form}->{q});
        $self->log(info => "REQUEST $auth, @{[ $url || '' ]}");
        my $response = $self->_make_response(
            url      => $url,
            request  => $args{request},
            base_url => $base,
            user_id  => $auth,
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
    my $self = shift;
    my %args = validate(
        @_ => +{
            url      => qr{^https?://},
            request  => { isa  => 'HTTP::Request' },
            base_url => qr{^https?://},
            user_id  => { type => SCALAR },
        }
    );
    my $url = $args{url};
    my $base_url = $args{base_url};

    if ($url) {
        # do proxy
        my $res = $self->_do_request(
            url     => $url,
            request => $args{request},
            user_id => $args{user_id},
        );
        $self->log(debug => '-- response status: ' . $res->code);

        if ($res->code == 302) {
            # rewrite redirect
            my $location = URI->new($res->header('Location'));
            my $uri = URI->new($url);
            if ($uri->port != 80 && $location->port != $uri->port) {
                $location->port($uri->port);
            }
            $res->header( 'Location' => $base_url . '?q='
                  . uri_escape( $location ) );
        } else {
            my $content_type = $res->header('Content-Type');
            if ($content_type =~ /html/i) {
                $res->content( rewrite($base_url, $res->content, $url) );
            }
            use bytes;
            $res->header('Content-Length' => bytes::length($res->content));
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
    my $self = shift;
    my %args = validate(
        @_ => +{
            url      => qr{^https?://},
            request  => { isa  => 'HTTP::Request' },
            user_id  => { type => SCALAR },
        }
    );

    # make request
    my $req = $args{request}->clone;
    $req->uri($args{url});
    $req->header('Host' => URI->new($args{url})->host);

    $self->run_hook(
        'request_filter_process_agent',
        {   request => $req, # HTTP::Request object
            user    => $args{user_id},
        }
    );
    my $mobile_attribute = HTTP::MobileAttribute->new($req->headers);
    my $carrier = $mobile_attribute->carrier;
    for my $hook ('request_filter', "request_filter_$carrier") {
        my $response = $self->run_hook_and_get_response(
            $hook,
            +{
                request          => $req,              # HTTP::Request object
                mobile_attribute => $mobile_attribute,
                user             => $args{user_id},
            }
        );
        if ($response) {
            return $response; # finished
        }
    }

    # do request
    my $ua = LWP::UserAgent->new(
        timeout           => $self->conf->{global}->{timeout} || 10,
        max_redirects     => 0,
        protocols_allowed => [qw/http https/],
    );
    my $response = $ua->request($req);
    for my $hook ( 'response_filter', "response_filter_$carrier" ) {
        $self->run_hook(
            $hook,
            {
                response         => $response,           # HTTP::Response object
                mobile_attribute => $mobile_attribute,
                user             => $args{user_id},
            }
        );
    }
    $response;
}


1;
__END__

=head1 NAME

Moxy - Mobile web development proxy

=head1 DESCRIPTION

Moxy is a mobile web development proxy.

=head1 AUTHOR

    Kan Fushihara
    Tokuhiro Matsuno

=head1 THANKS TO

Kazuhiro Osawa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://coderepos.org/share/wiki/ssb>
