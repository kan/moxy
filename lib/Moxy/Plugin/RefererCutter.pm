package Moxy::Plugin::RefererCutter;
use strict;
use warnings;
sub register {
    my ($class, $context) = @_;

    $context->register_hook(
        request_filter => sub {
            my ($context, $args) = @_;

            $args->{request}->remove_header('Referer');
        }
    );
}

1;
__END__

=head1 DESCRIPTION

do not send referer.

=head1 AUTHOR

Tokuhiro Matsuno
