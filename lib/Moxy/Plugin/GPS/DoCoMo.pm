package Moxy::Plugin::GPS::DoCoMo;
use strict;
use warnings;
use base qw/Moxy::Plugin/;

#  TODO: support navi_pos
#  TODO: support lcs
sub r:Hook('request_filter_I') {
    my ( $self, $context, $args ) = @_;

    if ($args->{request}->uri =~ m{^http://w1m\.docomo\.ne\.jp/cp/iarea}) {
        # TODO: support post?
        $context->log(debug => "request uri is @{[ $args->{request}->uri ]}");

        my %queries = URI->new($args->{request}->uri)->query_form;

        # validation
        my $errstr;
        if ($queries{ecode} ne 'OPENAREACODE') {
            $errstr = 'ecode should be OPENAREACODE';
        }
        if ($queries{msn} ne 'OPENAREAKEY') {
            $errstr = 'msn should be OPENAREAKEY';
        }
        if (not exists $queries{nl}) {
            $errstr = 'nl missing';
        }
        if ($queries{nl} !~ m[^http://]) {
            $errstr = 'nl should start with http://';
        }
        if (length($queries{nl})>=256) {
            $errstr = 'nl too long(256)';
        }

        my $redirect_to = $queries{nl} . "?";
        my $coordinates = "LAT=%2B35.39.55.197&LON=%2B139.43.54.653&GEO=wgs84&XACC=1";
        my $area = "AREACODE=06000";
        if (!$queries{posinfo}) {
            $redirect_to .= $area;
        } elsif ($queries{posinfo} == 1) {
            $redirect_to .= "$area&$coordinates";
        } elsif ($queries{posinfo} == 2) {
            $redirect_to .= $coordinates;
        }

        my $response = HTTP::Response->new( 302, 'Redirect by Moxy(GPS willcom)' );
        $response->header(Location => $redirect_to);
        $response;
    }
}

1;
