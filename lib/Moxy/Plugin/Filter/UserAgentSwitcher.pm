package Moxy::Plugin::Filter::UserAgentSwitcher;
use strict;
use warnings;
use base qw/Moxy::Plugin/;
use Path::Class;
use URI;
use URI::Escape;
use CGI;

sub register {
    my ($class, $context) = @_;

    $context->register_hook(
        request_filter_process_agent => sub {
            my ($context, $args) = @_;

            my $user_agent = $context->storage->get('user_agent_' . $args->{user});

            # set UA to request.
            $args->{request}->header('User-Agent' => $user_agent) if $user_agent and $user_agent ne 'none';

            $context->log(debug => "UserAgent is $user_agent");
        },
        control_panel => sub {
            my ($context, $args) = @_;

            # generate control panel html.
            my %params = URI->new($args->{response}->request->uri)->query_form;

            return $class->render_template(
                $context,
                'panel.tt' => {
                    agents          => $context->ua_list,
                    moxy_user_agent => (
                        $args->{response}->request->header('User-Agent') || ''
                    ),
                    params      => \%params,
                    current_uri => $args->{response}->request->uri,
                }
            );
        },
        request_filter => sub {
            my ($context, $args) = @_;

            if ($args->{request}->uri =~ m{^http://uaswitcher\.moxy/(.+)}) {
                my $back = uri_unescape($1);

                # store settings
                my $r = CGI->new($args->{request}->content);
                $context->storage->set("user_agent_$args->{user}" => $r->param('moxy_user_agent'));

                # back
                my $response = HTTP::Response->new( 302, 'Moxy(UserID)' );
                $response->header(Location => $back);
                $response;
            }
        },
    );
}

1;
__END__

=head1 NAME

Moxy::Plugin::Filter::UserAgentSwitcher - change your user agent

=head1 DESCRIPTION

you can select your user agent.

=head1 AUTHOR

    Kan Fushihara
    Tokuhiro Matsuno

=head1 SEE ALSO

L<Moxy>

