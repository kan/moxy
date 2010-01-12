#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use WWW::MobileCarrierJP::DoCoMo::Display;
use YAML;
use FindBin;
use File::Spec;
use Data::Dumper;
use Encode;
use File::Slurp;

setup();exit;

sub setup {
    my $fname = File::Spec->catfile( $FindBin::Bin, '..', 'assets', 'common',
        'docomo-display-map.yaml' );

    write_file($fname, YAML::Dump(mkdata()));
}

sub mkdata {
    my $dat = WWW::MobileCarrierJP::DoCoMo::Display->scrape;
    my %map;
    for my $phone (@$dat) {
        my $model = uc $phone->{model};
        $model =~ s/-//; # $ma->model は - をふくまないものがおくられてきてる
        $map{ $model } = +{
            width  => $phone->{width},
            height => $phone->{height},
            color  => $phone->{is_color},
            depth  => $phone->{depth},
        };
    }
    \%map;
}
