package Moxy::Plugin::OpenSocial;
use strict;
use warnings;
use base 'Moxy::Plugin';

use URI::Escape;
use OAuth::Lite::Consumer;
use HTML::TreeBuilder;
use Encode;

sub control_panel :Hook {
    my ($self, $context, $args) = @_;

    # generate control panel html.
    my %params = URI->new($args->{response}->request->uri)->query_form;

    return $self->render_template(
        $context,
        'panel.tt' => {
            params          => \%params,
            current_uri     => $args->{response}->request->uri,
            app_id          => $args->{session}->get('opensocial_app_id'),
            owner_id        => $args->{session}->get('opensocial_owner_id'),
            consumer_key    => $args->{session}->get('opensocial_consumer_key'),
            consumer_secret => $args->{session}->get('opensocial_consumer_secret'),
        },
    );
}

sub url_handle :Hook {
    my ($self, $context, $args) = @_;

    if ($args->{request}->uri =~ m!^http://opensocial\.moxy/(.+)!) {
        my $back = uri_unescape($1);

        my $r = CGI->new($args->{request}->content);
        $args->{session}->set( opensocial_app_id => $r->param('app_id') );
        $args->{session}->set( opensocial_owner_id => $r->param('owner_id') );
        $args->{session}->set( opensocial_consumer_key => $r->param('consumer_key') );
        $args->{session}->set( opensocial_consumer_secret => $r->param('consumer_secret') );

        # back
        my $response = HTTP::Response->new( 302, 'Moxy(UserID)' );
        $response->header(Location => $back);
        return $response;
    }
}

sub request_filter :Hook {
    my ($self, $context, $args) = @_;

    my $consumer_key    = $args->{session}->get('opensocial_consumer_key');
    my $consumer_secret = $args->{session}->get('opensocial_consumer_secret');

    return unless $consumer_key && $consumer_secret;

    my $consumer = OAuth::Lite::Consumer->new(
        consumer_key    => $consumer_key,
        consumer_secret => $consumer_secret,
    );

    my $req = $args->{request};
    my %param = $req->uri->query_form;
    $param{opensocial_app_id}    = $args->{session}->get('opensocial_app_id');
    $param{opensocial_owner_id}  = $args->{session}->get('opensocial_owner_id');
    $param{opensocial_viewer_id} = $args->{session}->get('opensocial_owner_id');

    my %body_param = %{$self->_parse_request_body($req)};
    for my $key (keys %body_param) {
        my $value = $body_param{$key};
        if (exists $param{$key}) {
            my @values = ref $value eq 'ARRAY' ? @$value : ($value);
            my $v = $param{$key};
            $v = [$v] unless ref $v eq 'ARRAY';
            push @$v, @values;
            $param{$key} = $v;
        }
        else {
            $param{$key} = $value;
        }
    }

    my $oauth_req = $consumer->gen_oauth_request(
        method  => $req->method,
        url     => $req->uri->scheme . '://'
            . $req->uri->authority . $req->uri->path,
        headers => [map { $_ => $req->header($_) } $req->header_field_names],
        params  => \%param,
    );

    $req->uri( $oauth_req->uri );
    $req->header( $_ => $oauth_req->header($_) ) for $oauth_req->header_field_names;
    $req->content($oauth_req->content);
}

sub response_filter :Hook {
    my ($self, $context, $args) = @_;

    my $res = $args->{response};
    if ($res->header('Content-Type') =~ /html/) {
        my $tree = HTML::TreeBuilder->new;
        $tree->implicit_tags(0);
        $tree->no_space_compacting(1);
        $tree->ignore_ignorable_whitespace(0);
        $tree->store_comments(1);
        $tree->ignore_unknown(0);
        $tree->parse_content($res->decoded_content);

        for my $t (['a', 'href'], ['form', 'action']) {
            my $tag  = $t->[0];
            my $attr = $t->[1];

            my @links = $tree->look_down(
                _tag   => $tag,
                $attr  => qr/^\?/,
            );
            for my $link (@links) {
                my $u      = URI->new( $link->attr($attr) );

                my %params = $u->query_form;

                my $uri = URI->new( delete $params{url} );
                %params = ($uri->query_form, %params);
                $uri->query_form(%params);

                $link->attr($attr, $uri);
            }
        }
        my $result = '';
        for my $elm ($tree->guts) {
            $result .= ref $elm ? $elm->as_HTML(q{<>"&'}, '', {}) : $elm;
        }
        $tree->delete;

        $res->content(encode($res->charset, $result));
    }
}

sub _parse_request_body {
    my ($self, $r) = @_;

    my $content_type   = $r->header('Content-Type');
    my $content_length = $r->header('Content-Length');

    my $body = HTTP::Body->new($content_type, $content_length);
    $body->add($r->content);

    return $body->param;
}

1;
__END__

=head1 NAME

Moxy::Plugin::OpenSoscial - OpenSocial plugin for moxy

=head1 SYNOPSIS

  - module: OpenSocial

=head1 DESCRIPTION

By this plugin moxy could emulates opensocial gadget server.

=head1 AUTHOR

    Daisuke Murase
    Shinichiro Sei
    Soh Kitahara
    Wataru Seto
    Masayuki Matsuki

=head1 SEE ALSO

L<Moxy>
