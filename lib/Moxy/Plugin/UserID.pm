package Moxy::Plugin::UserID;
use strict;
use warnings;
use base qw/Moxy::Plugin/;
use URI::Escape qw/uri_unescape/;
use CGI;

sub get_user_id :Hook('request_filter') {
    my ($self, $context, $args) = @_;

    my $key = join(',', __PACKAGE__, $args->{mobile_attribute}->user_agent);
    my $user_id = $args->{session}->get($key);
    if ($user_id) {
        $context->log('debug' => "your user id is $user_id");

        if ($args->{mobile_attribute}->is_ezweb) {
            # au subscriber id.
            $args->{request}->header('X-Up-Subno' => $user_id);
        } elsif ($args->{mobile_attribute}->is_docomo) {
            # docomo
            if ($args->{request}->uri =~ /guid=ON/i) {
                $context->log('debug' => "send x-dcmguid");
                $args->{request}->header('X-DCMGUID' => $user_id);
            } else {
                $context->log('debug' => "your uri does not contains guid=ON @{[ $args->{request}->uri ]}");
            }
        } elsif ($args->{mobile_attribute}->is_softbank) {
            # softbank
            $args->{request}->header('X-JPHONE-UID' => $user_id);
        }
    }
}

# save user id
sub save_user_id :Hook('url_handle') {
    my ($self, $context, $args) = @_;

    if ($args->{request}->uri =~ m{^http://userid\.moxy/(.+)}) {
        my $back = uri_unescape($1);

        my $r = CGI->new($args->{request}->content);

        # store to user stash.
        my $key = join(',', __PACKAGE__, $args->{mobile_attribute}->user_agent);
        $args->{session}->set($key => $r->param('user_id'));

        # save history
        do {
            my $key = join(',', __PACKAGE__, $args->{mobile_attribute}->user_agent, 'history');
            my $history = $args->{session}->get($key) || [];
            unshift @$history, $r->param('user_id');
            $args->{session}->set($key => $history);
        };

        my $response = HTTP::Response->new( 302, 'Moxy(UserID)' );
        $response->header(Location => $back);
        $response;
    }
}

sub control_panel :Hook {
    my ($self, $context, $args) = @_;
    return '' unless $args->{mobile_attribute}->is_ezweb || $args->{mobile_attribute}->is_docomo || $args->{mobile_attribute}->is_softbank;

    my $key = join(',', __PACKAGE__, $args->{mobile_attribute}->user_agent);
    my $user_id = $args->{session}->get($key);
    my $history = $args->{session}->get(join(',', __PACKAGE__, $args->{mobile_attribute}->user_agent, 'history'));

    return $self->render_template(
        $context,
        'panel.tt' => {
            user_id          => $user_id,
            referer          => $args->{response}->request->uri,
            mobile_attribute => $args->{mobile_attribute},
            history          => $history,
        }
    );
}

1;
__END__

=head1 NAME

Moxy::Plugin::UserID

=head1 SYNOPSIS

  - module: UserID

=head1 DESCRIPTION

Send X-Up-Subno

=head1 TODO

    softbank support

=head1 AUTHOR

Tokuhiro Matsuno

=head1 SEE ALSO

L<Moxy>, L<Moxy::Plugin::ControlPanel>
