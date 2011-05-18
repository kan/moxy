package Moxy;
use 5.00800;
use strict;
use warnings;
use base qw/Class::Accessor::Fast/;
use Class::Component 0.16;

our $VERSION = '0.57';

use Carp;
use Encode;
use File::Spec::Functions;
use File::Basename;
use FindBin;
use HTML::Entities;
use HTML::Parser;
use HTML::TreeBuilder::XPath;
use HTML::TreeBuilder;
use HTTP::Cookies;
use HTTP::Session;
use LWP::UserAgent;
use MIME::Base64;
use Moxy::Util;
use Params::Validate ':all';
use Path::Class;
use Scalar::Util qw/blessed/;
use UNIVERSAL::require;
use URI::Escape;
use URI::Heuristic qw(uf_uristr);
use URI;
use YAML;
use Time::HiRes ();
use Plack::Response;
use Moxy::Request;
use HTTP::Message::PSGI;
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

__PACKAGE__->load_plugins(qw/
    DisplayWidth ControlPanel LocationBar Pictogram
    Status::401 Status::500 Status::404
    UserID XMLisHTML UserAgentSwitcher RefererCutter CookieCutter FlashUseImgTag
    DisableTableTag GPS HTTPHeader QRCode ShowHTTPHeaders
/);
__PACKAGE__->mk_accessors(qw/response_time/);

sub new {
    my ($class, $config) = @_;

    if ( $config->{global}->{plugins} ) {
        $class->load_plugins(@{ $config->{global}->{plugins} });
    }

    $config->{global}->{log}->{level} ||= 'info';

    $config->{global}->{assets_path} ||= do {
        my $libpath = $INC{'Moxy.pm'};
        $libpath =~ s!(?:blib/)?lib/+Moxy\.pm$!!;
        $libpath ||= './';
        $libpath = File::Spec->rel2abs($libpath);
        File::Spec->catdir($libpath, 'assets');
    };

    my $self = $class->NEXT( 'new' => { config => $config } );

    $self->conf->{global}->{session}->{store} = +{
        module => 'DBM',
        config => {
            file => do {
                require File::Temp;
                my $db = File::Temp->new();
                $self->{__session} = $db;
                "$db", # we need stringify for file::temp
            },
            dbm_class => 'NDBM_File',
        },
    };

    $self->conf->{global}->{log}->{fh} ||= \*STDERR;

    return $self;
}

sub assets_path { shift->conf->{global}->{assets_path} }

sub res {
    Plack::Response->new(@_);
}
sub HTTP::Response::to_plack_response {
    my $self = shift;
    return res(
        $self->code,
        $self->headers,
        $self->content,
    );
}

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

sub rewrite_css {
    my ($base, $css, $url) = @_;
    my $base_url = URI->new($url);

    $css =~ s{url\(([^\)]+)\)}{
        my $x = $1;
        sprintf "url(%s%s%s)",
            $base,
            ($base =~ m{/$} ? '' : '/'),
            uri_escape( URI->new($x)->abs($base_url) )
    }ge;

    $css;
}

sub rewrite_html {
    my ($base, $html, $url) = @_;

    my $base_url = URI->new($url);

    # parse.
    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->implicit_tags(0);
    $tree->no_space_compacting(1);
    $tree->ignore_ignorable_whitespace(0);
    $tree->store_comments(1);
    $tree->ignore_unknown(0);
    $tree->parse($html);
    $tree->eof;

    # define replacer.
    my $replace = sub {
        my ( $tag, $attr_name ) = @_;

        for my $node ( $tree->findnodes("//$tag") ) {
            if ( my $attr = $node->attr($attr_name) ) {
                next if $attr =~ /^mailto:/;
                if ($attr =~ /^tel:([0-9-]+)$/) {
                    my $tel = $1;
                    $node->attr(
                        'onclick' => qq{prompt('tel', '$1');return false;}
                    );
                } else {
                    # maybe /https?/
                    my $target_url = URI->new($attr);
                       $target_url = $target_url->abs($base_url) if $base_url;
                    $node->attr(
                        $attr_name => sprintf( qq{%s%s%s},
                            $base,
                            ($base =~ m{/$} ? '' : '/'),
                            uri_escape( $target_url ) )
                    );
                }
            }
        }
    };

    # replace.
    $replace->( 'img'    => 'src' );
    $replace->( 'script' => 'src' );
    $replace->( 'form'   => 'action' );
    $replace->( 'a'      => 'href' );
    $replace->( 'link'   => 'href' );

    # dump.
    my $result = $tree->as_HTML(q{<>"&'}, '', {});
    $tree = $tree->delete; # cleanup :-) HTML::TreeBuilder needs this.

    # return result.
    return $result;
}

sub to_app {
    my ($self) = @_;
    sub {
        my $env = shift;
        my $req = Moxy::Request->new($env);
        my $res = $self->handle_request($req);
           $res->content_length( length($res->content) ); # adjust content-length.
           $res->finalize();
    };
}

sub handle_request {
    my ($self, $req) = @_;

    $self->log(debug => "---------------------------");

    my $conf = $self->conf->{global}->{session};
    my $state_type = $conf->{state}->{module} || 'BasicAuth';
    my $state = sub {
        if ($state_type eq 'Cookie') {
            require HTTP::Session::State::Cookie;
            HTTP::Session::State::Cookie->new(
                $conf->{state}->{config}
            );
        } else {
            require Moxy::Session::State::BasicAuth;
            Moxy::Session::State::BasicAuth->new(
                $conf->{state}->{config} || {}
            );
        }
    }->();
    my $store = sub {
        my $postfix = $conf->{store}->{module} or die "missing session store module name";
        my $klass = "HTTP::Session::Store::${postfix}";
        $klass->require or die $@;
        $klass->new( $conf->{store}->{config} );
    }->();

    my $auth = join(',', $req->headers->authorization_basic);
    if ($state->isa('Moxy::Session::State::BasicAuth') && !$auth) {
        $self->log(debug => 'basicauth');
        return res(
            401,
            [
                WWW_Authenticate => qq{Basic realm="Moxy needs basic auth.Only for identification.Password is dummy."},
            ],
            'authentication required',
        );
    } else {
        $self->log(debug => "session: state: $state, store: $store");
        my $session = HTTP::Session->new(
            state   => $state,
            store   => $store,
            request => $req,
        );
        $self->log(debug => "session: $session");
        my $res = $self->_make_response(
            req     => $req,
            session => $session,
        );
        $session->response_filter($res);
        $session->finalize;

        return $res;
    }
}

sub _make_response {
    my $self = shift;
    my %args = validate(
        @_ => +{
            req     => { isa => 'Moxy::Request', },
            session => { type => OBJECT },
        }
    );
    my $req = $args{req};

    my $base = $req->uri->clone;
    $base->path('');
    $base->query_form({});

    (my $url = $req->uri->path_query) =~ s!^/!!;
    $url = uf_uristr(uri_unescape($url));

    if ($url) {
        # do proxy
        my $res = $self->_do_request(
            url     => $url,
            request => $req->as_http_request,
            session => $args{session},
        );
        $self->log(debug => '-- response status: ' . $res->code);

        if ($res->code == 302) {
            # rewrite redirect
            my $location = URI->new($res->header('Location'));
            $self->log(debug => "redirect to $location");
            my $uri = URI->new($url);
            if (not defined $location->scheme) {
                # path only redirect is invalid!
                #   e.g.   Location: /foo/
                $self->log(error => "----------------------------");
                $self->log(error => "INVALID REDIRECT!! $location");
                $self->log(error => "----------------------------");
                $location = URI->new( $location->as_string, $uri->scheme );
                $location->scheme($uri->scheme);
                $location->host($uri->host);
                $location->port($uri->port);
                $self->log(error => "FIXED TO: $location");
                $self->log(error => "----------------------------");
            } else {
                if ($uri->port != 80 && $location->port != $uri->port) {
                    $location->port($uri->port);
                }
            }
            my $redirect = $base . '/' . uri_escape($location);
            $self->log(debug => "redirect to $redirect");
            return res(
                302, [
                    Location => $redirect,
                ],
            );
        } else {
            my $content_type = $res->header('Content-Type');
            $self->log(debug => "Content-Type: $content_type");
            if ($content_type =~ /html/i) {
                $res->content( encode($res->charset, rewrite_html($base, decode($res->charset, $res->content), $url), Encode::FB_HTMLCREF) );
            } elsif ($content_type =~ m{text/css}) {
                $res->content( encode($res->charset, rewrite_css($base, decode($res->charset, $res->content), $url), Encode::FB_HTMLCREF) );
            }

            return $res->to_plack_response();
        }
    } else {
        # please input url.
        my $response = HTTP::Response->new(
            200 => 'ok', HTTP::Headers->new(
                'content-type' => 'text/html;charset=utf-8',
            ), q{<?xml version="1.0" encoding="utf-8"?>
                <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
                <html lang="ja" xml:lang="ja" xmlns="http://www.w3.org/1999/xhtml">
                <head>
                    <title>moxy start page</title>
                </head>
                <body>
                <div>
                <h1>moxy start page</h1>
                <p>please input url to location bar</p>
                </div>
                </body>
            </html>},
        );
        $response->request($req->as_http_request);
        $self->_post_process(
            response         => $response,
            mobile_attribute => HTTP::MobileAttribute->new('KDDI-KC26 UP.Browser/6.2.0.7.3.129 (GUI) MMP/2.0'),
            session          => $args{session},
        );
        $response->content( encode($response->charset, rewrite_html($base, decode($response->charset, $response->content), ''), Encode::FB_HTMLCREF) );
        return $response->to_plack_response();
    }
}

sub _do_request {
    my $self = shift;
    my %args = validate(
        @_ => +{
            url      => qr{^https?://},
            request  => { isa  => 'HTTP::Request' },
            session  => { type => OBJECT },
        }
    );

    # make request
    my $req = $args{request}->clone;
    $req->uri($args{url});
    $req->header('Host' => do {
            my $u = URI->new($args{url});
            my $header = $u->host;
            $header .= ':' . $u->port if $u->port != 80;
            $header;
        }
    );

    $self->run_hook(
        'request_filter_process_agent',
        {   request => $req, # HTTP::Request object
            session => $args{session},
        }
    );

    my $mobile_attribute = HTTP::MobileAttribute->new($req->headers);
    my $carrier = $mobile_attribute->carrier;
    my $cookie_jar = $args{session}->get('cookies') || HTTP::Cookies->new(); # load cookies
    if ($mobile_attribute->is_docomo) {
        undef $cookie_jar; # docomo phone doesn't support cookies
    }

    for my $hook ('url_handle', "url_handle_$carrier") {
        my $response = $self->run_hook_and_get_response(
            $hook,
            +{
                request          => $req,              # HTTP::Request object
                mobile_attribute => $mobile_attribute,
                session          => $args{session},
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
        parse_head        => 0,
        cookie_jar        => $cookie_jar,
    );
    $ua->add_handler( request_prepare => sub {
        my ($req, $ua, $h) = @_;

        for my $hook ('request_filter', "request_filter_$carrier") {
            my $response = $self->run_hook_and_get_response(
                $hook,
                +{
                    request          => $req,              # HTTP::Request object
                    mobile_attribute => $mobile_attribute,
                    session          => $args{session},
                }
            );
            if ($response) {
                return $response; # finished
            }
        }
        $req->remove_header('Accept-Encoding'); # I HATE gziped CONTENT
        $req->remove_header('Cookie');          # remove Cookie from the client

        $req;
    });
    $ua->add_handler( response_done => sub {
        my ($response, $ua, $h) = @_;
        my $location = $response->header('Location');
        if ($location) {
            my $content = $response->content || '';
            $self->log(info => "redirect to '$location', $content");
        }
        $response;
    });

    $self->log(debug => "request to @{[ $req->uri ]}");
    my $t1 = Time::HiRes::gettimeofday();
    my $response = $ua->request($req);
    my $t2 = Time::HiRes::gettimeofday();
    $self->response_time( $t2-$t1 );
    $self->log(debug => "and, request was @{[ $response->request->uri ]}");

    $args{session}->set('cookies' => $cookie_jar); # save cookies

    $self->_post_process(
        response         => $response,
        mobile_attribute => $mobile_attribute,
        session          => $args{session},
    );
    $self->response_time( -1 ); # clear response time

    $response;
}

sub _post_process {
    my $self = shift;
    my %args = validate(
        @_ => {
            response         => 1,
            mobile_attribute => 1,
            session          => 1,
        },
    );

    my $carrier = $args{mobile_attribute}->carrier;
    for my $hook (
        'status_handler',  'security_filter',
        'response_filter', "response_filter_$carrier",
        'render_location_bar'
      )
    {
        $self->run_hook( $hook, \%args );
    }
}

1;
__END__

=for stopwords nyarla-net

=head1 NAME

Moxy - Mobile web development proxy

=head1 DESCRIPTION

Moxy is a mobile web development proxy.

=head1 AUTHOR

    Kan Fushihara
    Tokuhiro Matsuno

=head1 THANKS TO

Kazuhiro Osawa
nyarla-net

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://coderepos.org/share/wiki/ssb>
