package Moxy::Plugin::Filter::QRCode::Imager;
use strict;
use warnings;
use base qw/Moxy::Plugin/;

use Imager::QRCode;
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

                my $qrcode = Imager::QRCode->new(
                    level => 'M',
                    casesensitive => 1,
                );

                my $image = $qrcode->plot($url);
                $image->write( data => \my $data, type => 'png' );

                my $response = HTTP::Response->new( 200, 'Moxy QRcode ok' );
                $response->header('Content-Type' => 'image/png');
                $response->content($data);
                $response;
            }
        },
    );
}

1;
__END__

=head1 NAME

Moxy::Plugin::Filter::QRCode - QRCode generator for Moxy

=head1 SYNOPSIS

    - module: QRCode::Imager

=head1 DESCRIPTION

Yet Another QRCode generator for Moxy.

=head1 DEPENDENCY

This module uses L<Imager::QRCode>.

=head1 SEE ALSO

L<Moxy>, L<Imager>, L<Imager::QRCode>.
