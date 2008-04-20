package Moxy::Server::POE;
use strict;
use warnings;
use POE;
use POE::Filter::HTTPD;
use POE::Component::Server::TCP;

sub run {
    my ($class, $context, $config) = @_;

    $context->log(debug => "setup " . __PACKAGE__);

    my $session_id = POE::Component::Server::TCP->new(
        Alias        => 'moxy_httpd',
        Port         => $config->{port},
        ClientFilter => 'POE::Filter::HTTPD',
        ClientInput  => sub {
            my $response = $context->handle_request(
                request => $_[ARG0],
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

    $context->log(info => sprintf("Moxy running at http://%s:%d/\n", $config->{host}, $config->{port}));

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

L<Moxy>, L<POE>, L<POE::HTTPD>, L<POE::Component::Server::TCP>

