# =========================================================================
# scrape kddi model info.
#
# =========================================================================
use strict;
use warnings;
use utf8;
use Web::Scraper;
use URI;
use Encode;
use charnames ':full';
use YAML;

&main;

sub main {
    my $base_uri = 'http://www.au.kddi.com/ezfactory/tec/spec/new_win/ezkishu.html';

    my $scraper = scraper {
        process 'table[width="892"] > tr[bgcolor="#ffffff"]', 'au_info[]' => scraper {
            process 'td', 'elems[]' => 'TEXT';
            result 'elems[]';
        };
        result 'au_info[]';
    }->scrape( URI->new($base_uri) );

    my $result;
    for my $row (map { $_->{elems} } @{$scraper->{au_info}}) {
        my $one;
        $one->{'model'} = $row->[0];
        $one->{'browser_type'} = $row->[1];
        $one->{'display_color'} = $row->[2];
        ($one->{'display_char_transversal'}, $one->{display_char_longitudinal}) = &_split_by_times($row->[3]);
        ($one->{'display_browsing_width'}, $one->{display_browsing_height}) = &_split_by_times($row->[4]);
        ($one->{'display_wallpaper_width'}, $one->{display_wallpaper_height}) = &_split_by_times($row->[5]);
        $one->{'support_gif'} = $row->[6] eq '-' ? 0 : 1;
        $one->{'support_jpeg'} = $row->[7] eq '-' ? 0 : 1;
        $one->{'support_png'} = $row->[8] eq '-' ? 0 : 1;

        if ($row->[11] =~ /\N{WHITE CIRCLE}/) { # 1.1 normal
            $one->{'flash_lite_1.1'}++;
        } elsif ($row->[11] =~ /\N{BLACK CIRCLE}/) { # 2.0
            $one->{'flash_lite_1.1'}++;
            $one->{'flash_lite_chakuflash'}++;
            $one->{'flash_lite_2.0'}++;
        } elsif ($row->[11] =~ /\N{BULLSEYE}/) { # 1.1+chakuflash
            $one->{'flash_lite_1.1'}++;
            $one->{'flash_lite_chakuflash'}++;
        }
        push @$result, $one;
    }

    print YAML::Dump($result);
}

sub _split_by_times {
    my $x = shift;
    split /\N{MULTIPLICATION SIGN}/, $x;
}

