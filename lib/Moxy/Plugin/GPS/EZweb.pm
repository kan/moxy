package Moxy::Plugin::GPS::EZweb;
use strict;
use warnings;
use base qw/Moxy::Plugin/;
use URI::Escape qw/uri_unescape/;

# TODO: gpsone
sub response_filter :CarrierHook('E') {
    my ( $self, $context, $args ) = @_;

    my $content = $args->{response}->content;
    $content =~ s{device:location\?url=([^'"> ]+)}{"http://gps.moxy/au/?redirect_to=$1"}ge;
    $args->{response}->content($content);
}

sub request_filter :CarrierHook('E') {
    my ( $self, $context, $args ) = @_;

    if ( $args->{request}->uri =~ m{^http://gps\.moxy/au/\?redirect_to=(.+)} ) {
        my $redirect_to = uri_unescape($1);

        # XXX this is suck, but au ua works like this. orz.
        $redirect_to .= '?datum=tokyo&unit=dms&lat=35.37.16.00&lon=139.43.38.25';

        my $response = HTTP::Response->new( 302, 'Redirect by Moxy(GPS)' );
        $context->log(debug => "Redirect GPS to : $redirect_to");
        $response->header(Location => $redirect_to);
        $response;
    }
}

1;
