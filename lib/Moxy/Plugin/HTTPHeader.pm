package Moxy::Plugin::HTTPHeader;
use strict;
use warnings;
use base qw/Moxy::Plugin/;
use HTTP::MobileAgent;
use URI;
use URI::Escape;
use CGI;

sub register {
    my ($class, $context) = @_;

    $context->register_hook(
        request_filter => sub {
            my ($context, $args) = @_;

            my $http_header = $context->storage->get(__PACKAGE__. $args->{user});

            if ($http_header) {
                for my $header (split /\n/, $http_header) {
                    next unless $header;

                    if ($header =~ /^([^:]+)\s*:\s*(.+)$/) {
                        $args->{request}->header($1 => $2);
                        $context->log(debug => "set header: '$1' => '$2'");
                    }
                }
            }
        },
        control_panel => sub {
            my ($context, $args) = @_;

            # generate control panel html.
            my %params = URI->new($args->{response}->request->uri)->query_form;

            return $class->render_template(
                $context,
                'panel.tt' => {
                    moxy_user_agent => (
                        $args->{response}->request->header('User-Agent') || ''
                    ),
                    params      => \%params,
                    current_uri => $args->{response}->request->uri,
                    headers     => $context->storage->get(__PACKAGE__ . $args->{user}),
                }
            );
        },
        request_filter => sub {
            my ($context, $args) = @_;

            if ($args->{request}->uri =~ m{^http://http-header\.moxy/(.+)}) {
                my $back = uri_unescape($1);

                # store settings
                my $r = CGI->new($args->{request}->content);
                $context->storage->set(__PACKAGE__ . $args->{user} => $r->param('moxy_http_header'));

                # back
                my $response = HTTP::Response->new( 302, "Moxy(@{[ __PACKAGE__ ]})" );
                $response->header(Location => $back);
                return $response;
            }
        },
    );
}

1;
__END__

=encoding utf8

=head1 NAME

Moxy::Plugin::HTTPHeader - HTTP Header を操作する

=head1 SYNOPSIS

  - module: HTTPHeader

=head1 DESCRIPTION

set some http headers.

=head1 AUTHOR

Tokuhiro Matsuno

=head1 SEE ALSO

L<Moxy>

