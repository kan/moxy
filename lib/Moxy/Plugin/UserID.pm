package Moxy::Plugin::UserID;
use strict;
use warnings;
use base qw/Moxy::Plugin/;
use URI::Escape qw/uri_unescape/;
use CGI;

sub get_user_id :Hook('request_filter') {
    my ($self, $context, $args) = @_;

    my $key = join(',', __PACKAGE__, $args->{user}, $args->{mobile_attribute}->user_agent);
    my $user_id = $context->storage->get($key);
    if ($user_id) {
        # au subscriber id.
        if ($args->{mobile_attribute}->is_ezweb) {
            $args->{request}->header('X-Up-Subno' => $user_id);
        } elsif ($args->{mobile_attribute}->is_docomo && $args->{request}->uri =~ /guid=ON/i) {
            $args->{request}->header('X-DCMGUID' => $user_id);
        }
    }
}

# save user id
sub save_user_id :Hook('request_filter') {
    my ($self, $context, $args) = @_;

    if ($args->{request}->uri =~ m{^http://userid\.moxy/(.+)}) {
        my $back = uri_unescape($1);

        my $r = CGI->new($args->{request}->content);

        # store to user stash.
        my $key = join(',', __PACKAGE__, $args->{user}, $args->{mobile_attribute}->user_agent);
        $context->storage->set($key => $r->param('user_id'));

        my $response = HTTP::Response->new( 302, 'Moxy(UserID)' );
        $response->header(Location => $back);
        $response;
    }
}

sub control_panel :Hook {
    my ($self, $context, $args) = @_;
    return '' unless $args->{mobile_attribute}->is_ezweb || $args->{mobile_attribute}->is_docomo;

    my $key = join(',', __PACKAGE__, $args->{user}, $args->{mobile_attribute}->user_agent);
    my $user_id = $context->storage->get($key);

    return $self->render_template(
        $context,
        'panel.tt' => {
            user_id          => $user_id,
            referer          => $args->{response}->request->uri,
            mobile_attribute => $args->{mobile_attribute},
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
