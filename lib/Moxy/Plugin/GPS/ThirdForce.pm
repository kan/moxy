package Moxy::Plugin::GPS::ThirdForce;
use strict;
use warnings;
use base qw/Moxy::Plugin/;
use URI::Escape qw/uri_escape uri_unescape/;

#   TODO: support vodafone(z attribute)
sub response_filter :CarrierHook('V') {
    my ( $self, $context, $args ) = @_;

    my $content = $args->{response}->content;
    $content =~ s{location:(?:cell|gps|auto)\?url=([^'"> ]+)}{"http://gps.moxy/softbank/?redirect_to=" .uri_escape($1)}ge;
    $args->{response}->content($content);
}

sub url_handle :CarrierHook('V') {
    my ( $self, $context, $args ) = @_;

    if ( $args->{request}->uri =~ m{^http://gps\.moxy/softbank/\?redirect_to=(.+)} ) {
        my $redirect_to = uri_unescape($1);

        # XXX this is suck, but vodafone ua works like this. orz.
        $redirect_to .= '?geo=wgs84&pos=N35.37.29.12E139.43.8.45';

        my $response = HTTP::Response->new( 302, 'Redirect by Moxy(GPS)' );
        $context->log(debug => "Redirect GPS to : $redirect_to");
        $response->header(Location => $redirect_to);
        $response;
    }
}

1;
