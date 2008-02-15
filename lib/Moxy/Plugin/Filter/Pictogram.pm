package Moxy::Plugin::Filter::Pictogram;
use strict;
use warnings;
use base qw/Moxy::Plugin/;
use Moxy::Util;
use Path::Class;
use HTML::ReplacePictogramMobileJp;

sub register {
    my ($class, $context) = @_;

    # registering pictogram replacer.
    for my $carrier (qw/I E V H/) {
        $context->register_hook( "response_filter_$carrier" => sub {
            my ($context, $args, ) = @_;
            return unless (($args->{response}->header('Content-Type')||'') =~ /html/);

            my $charset = Moxy::Util->detect_charset($args->{response}, $args->{content_ref});
            $charset = ($charset =~ /utf-?8/i) ? 'utf8' : 'sjis';

            ${ $args->{content_ref} } = HTML::ReplacePictogramMobileJp->replace(
                html     => ${ $args->{content_ref} },
                carrier  => $carrier,
                charset  => $charset,
                callback => sub {
                    my ( $unicode, $carrier ) = @_;

                    my $pict_html = $class->render_template( $context, 'pict.tmpl' );
                    return sprintf( $pict_html, $carrier, $unicode, $unicode );
                }
            );
            ${ $args->{content_ref} };
        });
    }

    # deliver pictogram
    $context->register_hook(request_filter => sub {
        my ($context, $args) = @_;
        die "request missing" unless $args->{request};

        if ($args->{request}->uri =~ m{http://pictogram\.moxy/([IEV])/([0-9A-F]{4}).gif}) {
            my $content = file($class->assets_path($context), 'image', $1, "$2.gif")->slurp;

            my $response = HTTP::Response->new( 200, 'ok' );
            $response->header( 'Expires' => 'Thu, 15 Apr 2030 20:00:00 GMT' );
            $response->content_type("image/gif");
            $response->content($content);
            $response;
        }
    });
}

1;
__END__

=for stopwords  pictograms

=head1 NAME

Moxy::Plugin::Filter::Pictogram - show pictograms

=head1 SYNOPSIS

  - module: Pictogram

=head1 DESCRIPTION

show pictograms.

=head1 SEE ALSO

L<Moxy>
