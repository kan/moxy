package Moxy::Plugin::Server::POE;
use strict;
use warnings;
use Moxy::Plugin::Server;
use POE;
use POE::Filter::HTTPD;
use POE::Component::Server::TCP;

sub register {
    my ($class, $context, $config) = @_;

    $context->register_hook(
        control_panel => sub {
            my ($context, $args) = @_;

            my $base = URI->new($args->{response}->request->uri);
            $base->query_form({});
            return render_control_panel($base, $args->{response}->request->uri);
        },
        run_server => sub { $class->run_server($context, $config) },
    );
}

sub run_server {
    my ($class, $context, $config) = @_;

    $context->log(debug => "setup " . __PACKAGE__);

    my $session_id = POE::Component::Server::TCP->new(
        Alias        => 'moxy_httpd',
        Port         => $config->{port},
        ClientFilter => 'POE::Filter::HTTPD',
        ClientInput  => sub {
            my $response = handle_request(
                request => $_[ARG0],
                context => $context,
                config  => $config,
            );

            use bytes;
            $response->header('Content-Length' => bytes::length($response->content));

            $_[HEAP]->{client}->put($response);
            $_[KERNEL]->yield('shutdown');
        },
        Error        => sub {
            die( "$$: " . 'Server ',
                $_[SESSION]->ID, " got $_[ARG0] error $_[ARG1] ($_[ARG2])\n" );
        }
    );

    $context->log(info => sprintf("Moxy running at http://localhost:%d/\n", $config->{port}));

    POE::Kernel->run;
}

1;
__END__

=encoding utf-8

=head1 NAME

Moxy::Plugin::Server::POE - Moxy engine based on POE

=head1 SYNOPSIS

    - module: Server::POE
      config:
        port: 10000

=head1 DESCRIPTION

POE でできた Moxy のサーバーです。

=head1 AUTHORS

Tokuhiro Matsuno

=head1 SEE ALSO

L<Moxy>, L<POE>, L<POE::Filter::HTTPD>, L<POE::Component::Server::TCP>

