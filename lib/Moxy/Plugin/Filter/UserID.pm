package Moxy::Plugin::Filter::UserID;
use strict;
use warnings;
use base qw/Moxy::Plugin/;
use HTTP::MobileAgent;
use URI::Escape;
use CGI;

sub register {
    my ($class, $context) = @_;

    $context->register_hook(
        request_filter => sub {
            my ($context, $args) = @_;

            if ($args->{agent} && $args->{agent}->{agent}) {
                my $carrier = HTTP::MobileAgent->new($args->{agent}->{agent})->carrier;
                my $key = join(',', __PACKAGE__, $args->{user}, $args->{agent}->{agent});
                my $user_id = $context->storage->get($key);
                if ($user_id) {
                    # au subscriber id.
                    if ($carrier eq 'E') {
                        $args->{request}->header('X-Up-Subno' => $user_id);
                    }
                }
            }
        },
        request_filter => sub {
            my ($context, $args) = @_;

            if ($args->{request}->uri =~ m{^http://userid\.moxy/(.+)} && $args->{agent}) {
                my $back = uri_unescape($1);

                my $r = CGI->new($args->{request}->content);

                # store to user stash.
                my $key = join(',', __PACKAGE__, $args->{user}, $args->{agent}->{agent});
                $context->storage->set($key => $r->param('user_id'));

                my $response = HTTP::Response->new( 302, 'Moxy(UserID)' );
                $response->header(Location => $back);
                $response;
            }
        },
        control_panel => sub {
            my ($context, $args) = @_;

            if ($args->{agent} && $args->{agent}->{agent}) {
                my $key = join(',', __PACKAGE__, $args->{user}, $args->{agent}->{agent});
                my $user_id = $context->storage->get($key);

                return $class->render_template(
                    $context,
                    'panel.tt' => {
                        user_id => $user_id,
                        referer => $args->{response}->request->uri
                    }
                );
            } else {
                return '';
            }
        },
    );
}

1;
__END__

=head1 NAME

Moxy::Plugin::Filter::UserID

=head1 SYNOPSIS

  - module: UserID

=head1 DESCRIPTION

Send X-Up-Subno

=head1 AUTHOR

Tokuhiro Matsuno

=head1 SEE ALSO

L<Moxy>, L<Moxy::Plugin::Filter::ControlPanel>
