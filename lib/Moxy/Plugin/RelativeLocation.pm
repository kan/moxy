package Moxy::Plugin::RelativeLocation;
use strict;
use warnings;
use base qw/Moxy::Plugin/;

use URI;

sub response_filter :Hook {
    my ($self, $context, $args) = @_;

    my $location = $args->{response}->header('Location');
    return unless $location;

    unless ($location =~ m!^https?://!) {
        my $base = $args->{response}->request->uri;
        my $url = sprintf '%s://%s', $base->scheme, $base->host;
        unless (($base->scheme eq 'http' && $base->port eq '80') ||
               ($base->scheme eq 'https' && $base->port eq '443')) {
            $url .= ':' . $base->port;
        }
        $url .= $base->path;
        $location = URI->new_abs($location, $url);
    }
    $args->{response}->header( Location => $location );
}


1;
