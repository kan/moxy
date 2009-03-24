#!/usr/bin/perl
use strict;
use warnings;
use WWW::MobileCarrierJP::EZWeb::Model;
use WWW::MobileCarrierJP::EZWeb::DeviceID;
use YAML;
use FindBin;
use File::Spec;
use Data::Dumper;
use Encode;
use File::Slurp;

local $Web::Scraper::UseLibXML = 1;

&main; exit;

sub main {
    my $fname = File::Spec->catfile( $FindBin::Bin, '..', 'assets', 'plugins',
        'UserAgentSwitcher', 'useragent.yaml' );

    print "generate $fname\n";
    my $dat = make_data($fname);
    dump_data($fname => $dat);
}

sub make_data {
    my $fname = shift;
    my $orig = YAML::Load(decode_utf8(read_file $fname));
    my @dat = grep { $_->{carrier} ne 'ez' } @$orig;
    unshift @dat, +{ carrier => 'ez', agents => ez_data() };
    \@dat;
}

sub dump_data {
    my ($fname, $dat) = @_;
    open my $fh, '>:utf8', $fname or die $!;
    print $fh YAML::Dump($dat);
    close $fh;
}

sub ez_data {
    warn 'start fetch';
    my $model_dat = model_data();
    my $device_id_dat = device_id_data();

    my @result;
    for my $model (@$model_dat) {
        my $res = {};
        my $device_id = $device_id_dat->{$model->{model_long}};
        if ($model->{browser_type} eq 'HDML') {
            $res->{agent} = "UP.Browser/3.04-$device_id UP.Link/3.4.5.9";
        } else {
            if (ref $device_id) {
                warn "ahh? : " .Dumper($device_id);
                $device_id = $device_id->[0];
            }
            $res->{agent} = "KDDI-$device_id UP.Browser/6.2.0.7.3.129 (GUI) MMP/2.0";
        }
        $res->{name}   = $model->{model_long};
        $res->{cookie} = 1;
        $res->{header}->{'X-UP-DEVCAP-SCREENPIXELS'} = join(',', 
            $model->{display_browsing}->{width},
            $model->{display_browsing}->{height},
        );
        if ($model->{flash_lite}) {
            $res->{header}->{Accept} = 'application/x-shockwave-flash';
        }

        push @result, $res;
    }
    return \@result;
}

sub model_data {
    WWW::MobileCarrierJP::EZWeb::Model->scrape;
}

sub device_id_data {
    return +{
        map { $_->{model} => $_->{device_id} }
        @{ WWW::MobileCarrierJP::EZWeb::DeviceID->scrape }
    };
}

