package Moxy::Plugin::QRCode;
use strict;
use warnings;
use base qw/Moxy::Plugin/;
use GD::Barcode;
use GD::Barcode::QRcode;
use URI::Escape;

sub register {
    my ($class, $context) = @_;

    $context->register_hook(
        control_panel => sub {
            my ($context, $args) = @_;

            return $class->render_template(
                $context,
                'panel.tt' => {
                    current => $args->{response}->request->uri,
                }
            );
        },
        request_filter => sub {
            my ($context, $args) = @_;

            if ($args->{request}->uri =~ m{^http://qrcode\.moxy/(.+)}) {
                my $url = uri_unescape($1);


                my $qrcode = GD::Barcode::QRcode->new( $url,
                    { Ecc => 'M', ModuleSize => 5, Version => 5 } )
                    ->plot->png;

                my $response = HTTP::Response->new( 200, 'Moxy QRcode ok' );
                $response->header('Content-Type' => 'image/png');
                $response->content($qrcode);
                return $args->{filter}->proxy->response($response);
            }
        },
    );
}

1;
__END__

=head1 NAME

Moxy::Plugin::QRCode - QRCode generator for Moxy

=head1 SYNOPSIS

    - module: QRCode

=head1 DESCRIPTION

QRCode generator for Moxy.

=head1 DEPENDENCY

This module uses L<GD::Barcode::QRcode>.

=head1 SEE ALSO

L<Moxy>, L<GD::Barcode::QRcode>
