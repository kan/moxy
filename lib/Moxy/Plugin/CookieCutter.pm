package Moxy::Plugin::CookieCutter;
use strict;
use warnings;

sub register {
    my ($class, $context) = @_;

    $context->register_hook(
        request_filter => sub {
            my ($context, $args) = @_;

            # Do NOT send cookies got from client to the origin
            $args->{request}->remove_header('Cookie');
        }
    );
}

1;
__END__

=head1 NAME

Moxy::Plugin::CookieCutter

=head1 SYNOPSIS

  - module: CookieCutter

=head1 DESCRIPTION

do not send cookie.

=head1 AUTHOR

Tokuhiro Matsuno
