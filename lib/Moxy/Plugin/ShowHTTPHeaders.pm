package Moxy::Plugin::ShowHTTPHeaders;
use strict;
use warnings;
use base qw/Moxy::Plugin/;

sub control_panel :Hook {
    my ($self, $context, $args) = @_;

    $context->log(debug => 'dump http headers');

    return $self->render_template(
        $context,
        'panel.tt' => {
            request =>
                $args->{response}->request->headers_as_string(),
            response => $args->{response}->headers_as_string(),
        }
    );
}

1;
__END__

=head1 NAME

Moxy::Plugin::ShowHTTPHeaders - show http headers in control panel.

=head1 SYNOPSIS

  - module: ShowHTTPHeaders

=head1 DESCRIPTION

show http headers on control panel, for debugging.

=head1 AUTHOR

Tokuhiro Matsuno
