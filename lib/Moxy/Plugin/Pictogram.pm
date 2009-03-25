package Moxy::Plugin::Pictogram;
use strict;
use warnings;
use base qw/Moxy::Plugin/;
use Moxy::Util;
use Path::Class;
use HTML::ReplacePictogramMobileJp 0.04;
use HTTP::MobileAttribute;

sub response_filter :Hook {
    my ( $self, $context, $args, ) = @_;
    return unless ( ( $args->{response}->header('Content-Type') || '' ) =~ /html/ );
    return if $args->{mobile_attribute}->is_non_mobile;

    my $carrier = $args->{mobile_attribute}->carrier;

    my $charset = $args->{response}->charset;
    $charset = ( $charset =~ /utf-?8/i ) ? 'utf8' : 'sjis';

    my $pict_html = $self->render_template( $context, 'pict.tmpl' );

    $args->{response}->content(
        HTML::ReplacePictogramMobileJp->replace(
            html     => $args->{response}->content,
            carrier  => $carrier,
            charset  => $charset,
            callback => sub {
                my ( $unicode, $carrier ) = @_;

                return sprintf( $pict_html, $carrier, $unicode, $unicode );
            }
        )
    );
}

sub url_handle :Hook {
    my ($self, $context, $args) = @_;
    die "request missing" unless $args->{request};

    if ($args->{request}->uri =~ m{http://pictogram\.moxy/([IEV])/([0-9A-F]{4}).gif}) {
        my $content = file($self->assets_path($context), 'image', $1, "$2.gif")->slurp;

        my $response = HTTP::Response->new( 200, 'ok' );
        $response->header( 'Expires' => 'Thu, 15 Apr 2030 20:00:00 GMT' );
        $response->content_type("image/gif");
        $response->content($content);
        $response;
    }
}

1;
__END__

=for stopwords  pictograms

=head1 NAME

Moxy::Plugin::Pictogram - show pictograms

=head1 SYNOPSIS

  - module: Pictogram

=head1 DESCRIPTION

show pictograms.

=head1 SEE ALSO

L<Moxy>
