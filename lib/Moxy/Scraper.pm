package Moxy::Scraper;
use strict;
use warnings;

use URI;
use Web::Scraper;
use LWP::UserAgent;
use FindBin;
use Path::Class;

sub new { bless {}, shift }

sub run {
    my ($self, @carrier) = @_;

    for my $carrier (@carrier) {
        dir( $self->_assets_path, $carrier )->mkpath;

        $self->call("scrape_$carrier");
    }
}

sub call {
    my $self = shift;
    my $method = shift;
    $self->$method(@_);
}

sub _assets_path {
    my $self = shift;
    $self->{_assets_path} ||= dir( $FindBin::Bin, qw/assets server pictogram/ );
}

sub _ua {
    my $self = shift;

    $self->{_ua} ||= LWP::UserAgent->new( agent => ref $self );
}

sub scrape_i {
    my $self = shift;

    for my $base_uri (
        'http://www.nttdocomo.co.jp/service/imode/make/content/pictograph/basic/',
        'http://www.nttdocomo.co.jp/service/imode/make/content/pictograph/extention/'
        )
    {
        warn "call $base_uri";
        my $scraper = scraper {
            process 'tr.acenter', 'i_pictograms[]' => scraper {
                process 'td > span.txt', 'fields[]' => 'TEXT';
                process 'td > img',      'image'    => '@src';
            };
            result 'i_pictograms[]';
        }->scrape( URI->new($base_uri) );
        use Data::Dumper;warn Dumper($scraper);

        for my $pictogram ( @{ $scraper->{i_pictograms} } ) {
            next unless $pictogram->{fields};
            my $filename = $self->_assets_path->file( 'i',
                hex( $pictogram->{fields}->[1] ) . '.gif' );
            print "fetch $filename\n";
            $self->_ua->get( $base_uri . '/' . $pictogram->{image},
                ':content_file' => $filename->stringify );
            print "convert $filename\n";
            qx{convert -transparent white $filename $filename.t.gif};
            rename "$filename.t.gif", $filename;
        }
    }
}

sub scrape_e {
    my $self = shift;
    my $filename = file($FindBin::Bin, 'ezicon.lzh');
    my $output = dir( $FindBin::Bin, 'icon_image' );
    $self->_ua->get(
        'http://www.au.kddi.com/ezfactory/tec/spec/lzh/icon_image.lzh',
        ':content_file' => $filename->stringify );
    qx{ lha -xq -w=@{[$output->stringify]} $filename };

    $output->recurse(
        callback => sub {
            my $file = shift;
            return unless -f $file;

            if ( $file->basename =~ /(\d+).+\.ai$/ ) {
                my $number  = $1;
                my $newfile = $self->_assets_path->file( "e",
                    sprintf( "%03d.gif", $number ) );
                rename $file, $output->file("$number.ai");
                qx{ convert -trim -geometry 16x16 +repage @{[$output->stringify]}/$number.ai $newfile };
                print "convert $number\n";
            }
        }
    );
    $output->rmtree;
}

sub scrape_v {
    my $self = shift;

    my $base_uri = 'http://developers.softbankmobile.co.jp/dp/tool_dl/web';

    for my $num ( 1 .. 6 ) {
        my $uri = sprintf( "$base_uri/picword_%02d.php", $num );
        my $scraper = scraper {
            process 'table[width="100%"] > tr', 'v_pictograms[]' => scraper {
                process 'td > font.j10', 'fields[]' => 'TEXT';
                process 'td > img',      'image'    => '@src';
            };
            result 'v_pictograms[]';
        }
        ->scrape( URI->new($uri) );

        for my $pictogram ( @{ $scraper->{v_pictograms} } ) {
            next unless $pictogram->{fields};
            my $filename = $self->_assets_path->file('v', sprintf("%s.gif", hex( $pictogram->{fields}->[0] )));
            print "fetch $filename\n";
            $self->_ua->get( $base_uri . '/' . $pictogram->{image},
                ':content_file' => $filename->stringify );
            print "convert $filename\n";
            qx{convert -transparent white $filename $filename.t.gif};
            rename "$filename.t.gif", $filename;
        }
    }
}

1;
