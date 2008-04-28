package Moxy::Plugin::UserAgentSwitcher;
use strict;
use warnings;
use base qw/Moxy::Plugin/;
use Path::Class;
use URI;
use URI::Escape;
use CGI;

sub request_filter_process_agent :Hook {
    my ($self, $context, $args) = @_;

    my $user_agent = $context->storage->get('user_agent_' . $args->{user}) || 'KDDI-TS3G UP.Browser/6.2.0.7.3.129 (GUI) MMP/2.0';
    my $ua_info = $self->get_ua_info($context, $user_agent);

    # set UA to request.
    $args->{request}->header('User-Agent' => $user_agent);
    while (my ($key, $val) = each %{$ua_info->{header}}) {
        $args->{request}->header($key => $val);
    }

    $context->log(debug => "UserAgent is $user_agent");
}

sub control_panel :Hook {
    my ($self, $context, $args) = @_;

    # generate control panel html.
    my %params = URI->new($args->{response}->request->uri)->query_form;

    return $self->render_template(
        $context,
        'panel.tt' => {
            ua_list         => $self->ua_list($context),
            moxy_user_agent => (
                $args->{response}->request->header('User-Agent') || ''
            ),
            params      => \%params,
            current_uri => $args->{response}->request->uri,
        }
    );
}

sub request_filter :Hook {
    my ($self, $context, $args) = @_;

    if ($args->{request}->uri =~ m{^http://uaswitcher\.moxy/(.+)}) {
        my $back = uri_unescape($1);

        # store settings
        my $r = CGI->new($args->{request}->content); # CGI.pm は遅いやん。他になんかないんかねー
        $context->storage->set("user_agent_$args->{user}" => $r->param('moxy_user_agent'));

        # back
        my $response = HTTP::Response->new( 302, 'Moxy(UserID)' );
        $response->header(Location => $back);
        return $response;
    }
}

sub ua_list {
    my ($self, $context) = @_;
    return $self->{__ua_list} ||= YAML::LoadFile( $self->assets_path($context)->file('useragent.yaml') );
}

sub get_ua_info {
    my ($self, $context, $user_agent) = @_;

    $self->{__ua_hash} ||= do {
        my $ua_hash;
        for my $carrier_info ( @{ $self->ua_list($context) }) {
            for my $agent ( @{ $carrier_info->{agents} } ) {
                $ua_hash->{$agent->{agent}} = $agent;
            }
        }
        $ua_hash;
    };
    return $self->{__ua_hash}->{$user_agent||''};
}


1;
__END__

=head1 NAME

Moxy::Plugin::UserAgentSwitcher - change your user agent

=head1 DESCRIPTION

you can select your user agent.

=head1 AUTHOR

    Kan Fushihara
    Tokuhiro Matsuno

=head1 SEE ALSO

L<Moxy>

