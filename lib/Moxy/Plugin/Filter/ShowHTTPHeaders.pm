package Moxy::Plugin::Filter::ShowHTTPHeaders;
use strict;
use warnings;
use base qw/Moxy::Plugin/;

sub register {
    my ($class, $context) = @_;

    $context->register_hook(
        control_panel => sub {
            my ($context, $args) = @_;

            $context->log(debug => 'dump http headers');

            return $class->render_template(
                $context,
                'panel.tt' => {
                    request =>
                        $args->{response}->request->headers_as_string(),
                    response => $args->{response}->headers_as_string(),
                }
            );
        }
    );
}

1;
__END__

=head1 NAME

Moxy::Plugin::Filter::ShowHTTPHeaders - show http headers in control panel.

=head1 SYNOPSIS

  - module: ShowHTTPHeaders

=head1 DESCRIPTION

show http headers on control panel, for debugging.

=head1 AUTHOR

Tokuhiro Matsuno
