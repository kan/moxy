package Moxy::Plugin::ResponseTime;
use strict;
use warnings;
use base qw/Moxy::Plugin/;

sub control_panel :Hook {
    my ($self, $context, $args) = @_;

    return $self->render_template(
        $context,
        'panel.tt' => {
            response_time => $context->response_time,
        }
    );
}

1;
__END__

=head1 NAME

Moxy::Plugin::RseponseTime

=head1 SYNOPSIS

  - module: ResponseTime

=head1 DESCRIPTION

show response time

=head1 AUTHOR

Tokuhiro Matsuno

