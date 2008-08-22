package Moxy::Plugin::Hosts;
use strict;
use warnings;
use base qw/Moxy::Plugin/;

sub request_filter :Hook {
    my ($self, $context, $args) = @_;

    my $hosts = $self->config->{config}->{hosts};
    my $uri   = $args->{request}->uri;
    if (my $ip = $hosts->{$uri->host}) {
        my $host = $uri->host;
        $context->log( debug => " $host -> $ip " );
        $uri->host($ip);
        $args->{request}->uri($uri);

        $args->{request}->header( Host => $host );
        $self->{original_host} = $host;
    }
}

sub response_filter :Hook {
    my ($self, $context, $args) = @_;

    my $uri = $args->{response}->request->uri;
    $uri->host($self->{original_host});
    $args->{response}->request->uri($uri);
}


1;
__END__

=for stopwords coderepos.org

=head1 NAME

Moxy::Plugin::Hosts - /etc/hosts file emulator

=head1 SYNOPSIS

    - module: Hosts
      config:
        hosts:
          coderepos.org: 192.168.0.1

=head1 AUTHOR

    Kazuhiro Osawa

=head1 SEE ALSO

L<Moxy>
