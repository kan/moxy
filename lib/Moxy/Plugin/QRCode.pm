package Moxy::Plugin::QRCode;
use strict;
use warnings;
use base qw/Moxy::Plugin/;
use URI::Escape;

sub control_panel :Hook {
    my ($self, $context, $args) = @_;

    return $self->render_template(
        $context,
        'panel.tt' => {
            current => $args->{response}->request->uri,
        }
    );
}

sub request_filter :Hook {
    my ($self, $context, $args) = @_;

    if ($args->{request}->uri =~ m{^http://qrcode\.moxy/(.+)}) {
        my $url = uri_unescape($1);

        my $engine = $self->config->{config}->{engine} || 'GD';
        my $qrcode = _generate_qr($url, $engine);

        my $response = HTTP::Response->new( 200, 'Moxy QRcode ok' );
        $response->header('Content-Type' => 'image/png');
        $response->content($qrcode);
        $response;
    }
}

sub _generate_qr {
    my ($url, $engine) = @_;

    if ($engine =~ /Imager/i) {
        require Imager::QRCode;
        my $qrcode = Imager::QRCode->new(
            level => 'M',
            casesensitive => 1,
        );

        my $image = $qrcode->plot($url);
        $image->write( data => \my $data, type => 'png' );
        return $data;
    } elsif ($engine =~ /^GD$/i) {
        require GD::Barcode;
        require GD::Barcode::QRcode;
        return GD::Barcode::QRcode->new( $url,
            { Ecc => 'M', ModuleSize => 5, Version => 5 } )
            ->plot->png;
    } else {
        die "unknown qrcode engine type: $engine";
    }
}

1;
__END__

=head1 NAME

Moxy::Plugin::QRCode - QRCode generator for Moxy

=head1 SYNOPSIS

    - module: QRCode
      engine: Imager

    - module: QRCode
      engine: GD

=head1 DESCRIPTION

QRCode generator for Moxy.

=head1 DEPENDENCY

This module uses L<GD::Barcode::QRcode>.

=head1 AUTHORS

Kan Fushihara

Tokuhiro Matsuno

Daisuke Murase

=head1 SEE ALSO

L<Moxy>, L<GD::Barcode::QRcode>
