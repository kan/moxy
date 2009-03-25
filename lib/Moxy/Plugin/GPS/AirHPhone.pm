package Moxy::Plugin::GPS::AirHPhone;
use strict;
use warnings;
use base qw/Moxy::Plugin/;
use HTTP::Response;

sub url_handle :CarrierHook('H') {
    my ( $self, $context, $args ) = @_;

    if ($args->{request}->uri =~ m{^http://location\.request/dummy\.cgi\?my=(.+)&pos=\$location$}) {
        my $redirect_to = $1;

        $context->log(debug => "redirect uri is $redirect_to");

        $redirect_to .= '?pos=N35.37.12.543E139.43.29.920';

        my $response = HTTP::Response->new( 302, 'Redirect by Moxy(GPS willcom)' );
        $response->header(Location => $redirect_to);
        $response;
    }
}

1;
