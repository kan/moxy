package Moxy::Plugin::StickyUA;
use strict;
use warnings;
use base qw/Moxy::Plugin/;

use HTML::StickyQuery;

sub register {
    my ($class, $context) = @_;

    $context->register_hook(response_filter => sub { $class->response_filter(@_) });
}

# Add moxy_user_agent query to cross domain links
sub response_filter {
    my ($class, $context, $args) = @_;

    return unless $args->{response}->header('Content-Type') =~ /html/;

    # 'regexp' option for H::SQ doesn't work against URI domains :/
    my $filter = HTML::StickyQuery->new(
        abs => 1,
        keep_original => 1,
    );

    ${$args->{content_ref}} = $filter->sticky(
        scalarref => $args->{content_ref},
        param => {
            moxy_user_agent => $args->{agent}->{agent} || "",
        },
    );
}

1;

__END__

=head1 NAME

Moxy::Plugin::StickyUA - Save User-Agent between cross domain links

=head1 TODO

ON/OFF by ControlPanel

=head1 AUTHOR

Tatsuhiko Miyagawa

=cut
