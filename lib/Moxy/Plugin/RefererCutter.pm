package Moxy::Plugin::RefererCutter;
use strict;
use warnings;
use base qw/Moxy::Plugin/;

sub request_filter:Hook('request_filter') {
    my ($self, $context, $args) = @_;

    $args->{request}->remove_header('Referer');
}

1;
__END__

=head1 NAME

Moxy::Plugin::RefererCutter - remove referer

=head1 DESCRIPTION

do not send referer.

=head1 AUTHOR

Tokuhiro Matsuno

=head1 SEE ALSO

L<Moxy>

