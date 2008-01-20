package Moxy::Plugin::Filter::GPS;
use strict;
use warnings;
use base qw/Moxy::Plugin/;
use URI::Escape;
use Carp;
use URI;
use Path::Class;

sub register {
    my ($class, $context) = @_;

    # au
    # TODO: gpsone
    $context->register_hook(
        'response_filter_E' => sub {
            my ( $context, $args ) = @_;

            ${ $args->{content_ref} }
                =~ s{device:location\?url=([^'"> ]+)}{"http://gps.moxy/au/?redirect_to=$1"}ge;
        },
        request_filter_E => sub {
            my ( $context, $args ) = @_;

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
    );

    # willcom
    $context->register_hook(
        request_filter_H => sub {
            my ( $context, $args ) = @_;

            if ($args->{request}->uri =~ m{^http://location\.request/dummy\.cgi\?my=(.+)&pos=\$location$}) {
                my $redirect_to = $1;

                $context->log(debug => "redirect uri is $redirect_to");

                $redirect_to .= '?pos=N35.37.12.543E139.43.29.920';

                my $response = HTTP::Response->new( 302, 'Redirect by Moxy(GPS willcom)' );
                $response->header(Location => $redirect_to);
                $response;
            }
        }
    );

    # docomo iarea
    #  TODO: support navi_pos
    #  TODO: support lcs
    $context->register_hook(
        request_filter_I => sub {
            my ( $context, $args ) = @_;

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
    );

    # softbank
    #   TODO: support vodafone(z attribute)
    $context->register_hook(
        response_filter_V => sub {
            my ( $context, $args ) = @_;

            ${ $args->{content_ref} }
                =~ s{location:(?:cell|gps|auto)\?url=([^'"> ]+)}{"http://gps.moxy/softbank/?redirect_to=" .uri_escape($1)}ge;
        },
        request_filter_V => sub {
            my ( $context, $args ) = @_;

            if ( $args->{request}->uri =~ m{^http://gps\.moxy/softbank/\?redirect_to=(.+)} ) {
                my $redirect_to = uri_unescape($1);
                warn "GPS.MoXY";

                # XXX this is suck, but vodafone ua works like this. orz.
                $redirect_to .= '?geo=wgs84&pos=N35.37.29.12E139.43.8.45';

                my $response = HTTP::Response->new( 302, 'Redirect by Moxy(GPS)' );
                $context->log(debug => "Redirect GPS to : $redirect_to");
                $response->header(Location => $redirect_to);
                $response;
            }
        }
    );
}

1;
__END__

=head1 NAME

Moxy::Plugin::Filter::GPS - gps simulation for Moxy

=head1 SYNOPSIS

  - module: GPS

=head1 DESCRIPTION

GPS simulation feature for Moxy.

=head1 TODO

    support gpsone(au)
    support posinfo(docomo)
    support select pos

=head1 SEE ALSO

L<Moxy>
