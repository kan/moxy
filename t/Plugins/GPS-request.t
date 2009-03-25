# Redirector
use strict;
use warnings;
use Moxy;
use Test::Base;
use FindBin;
use File::Spec::Functions;
use HTTP::Request;

plan tests => 1*blocks;

my $m = Moxy->new(
    {
        global => {
            assets_path => catfile( $FindBin::Bin, '..', 'assets' ),
            'log' => {
                level => 'info',
            },
        },
        plugins => [
            { module => 'GPS' },
        ],
    }
);

filters {
    input    => [qw/yaml request fetch_location remove_space/],
    expected => [qw/remove_space/],
};

sub request {
    my $input = shift;
    my $request = HTTP::Request->new(200);
    $request->header('Content-Type' => 'text/html');
    $request->uri($input->{uri});
    my $response = $m->run_hook_and_get_response("url_handle_$input->{carrier}", { request => $request });
    $response;
}

sub fetch_location {
    my $req = shift;
    $req->header('Location');
}

sub remove_space { my $x = shift; $x =~ s/^\s+//mg; $x =~ s/\n//g; $x }

run_is input => 'expected';

__END__

===
--- input
carrier: H
uri: http://location.request/dummy.cgi?my=http://example.com/&pos=$location
--- expected: http://example.com/?pos=N35.37.12.543E139.43.29.920

===
--- input
carrier: I
uri: http://w1m.docomo.ne.jp/cp/iarea?ecode=OPENAREACODE&msn=OPENAREAKEY&nl=http://example.com/
--- expected: http://example.com/?AREACODE=06000

===
--- input
carrier: I
uri: http://w1m.docomo.ne.jp/cp/iarea?ecode=OPENAREACODE&msn=OPENAREAKEY&nl=http://example.com/&posinfo=2
--- expected: http://example.com/?LAT=%2B35.39.55.197&LON=%2B139.43.54.653&GEO=wgs84&XACC=1

===
--- input
carrier: E
uri: http://gps.moxy/au/?redirect_to=http%3A%2F%2Fexample.com%2F
--- expected: http://example.com/?datum=tokyo&unit=dms&lat=35.37.16.00&lon=139.43.38.25

===
--- input
carrier: V
uri: http://gps.moxy/softbank/?redirect_to=http%3A%2F%2Fexample.com%2F
--- expected: http://example.com/?geo=wgs84&pos=N35.37.29.12E139.43.8.45

