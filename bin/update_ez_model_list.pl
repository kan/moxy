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

my $yaml_path = File::Spec->catfile($FindBin::Bin, '..', 'assets', 'common', 'useragent.yaml');
my $orig = YAML::Load(decode('euc-jp', read_file $yaml_path));
my $model_dat = WWW::MobileCarrierJP::EZWeb::Model->scrape;
my $device_id_dat =
  +{ map { $_->{model} => $_->{device_id} }
      @{ WWW::MobileCarrierJP::EZWeb::DeviceID->scrape } };

$orig->{ez} = [];
for my $model (@$model_dat) {
    my $res = {};
    my $device_id = $device_id_dat->{$model->{model_long}};
    if ($model->{browser_type} eq 'HDML') {
        $res->{agent} = "UP.Browser/3.04-$device_id UP.Link/3.4.5.9";
    } else {
        $res->{agent} = "KDDI-$device_id UP.Browser/6.2.0.7.3.129 (GUI) MMP/2.0";
    }
    $res->{name}   = $model->{model_long};
    $res->{flash}  = $model->{flash_lite};
    $res->{width}  = $model->{display_browsing}->{width};
    $res->{height} = $model->{display_browsing}->{height};
    $res->{cookie} = 1;

    push @{$orig->{ez}}, $res;
}
print encode('euc-jp', YAML::Dump($orig));

