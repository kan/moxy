use strict;
use warnings;
use File::Spec::Functions;
use FindBin;
use HTTP::Request;
use HTTP::Response;
use Moxy::Plugin::DisplayWidth;
use Test::Base;
use YAML;
use HTTP::MobileAttribute plugins => [
    qw/IS/, {
        module => 'Display',
        config => {
            DoCoMoMap => YAML::LoadFile(
                catfile( 'assets', 'common', 'docomo-display-map.yaml' )
            )
        }
    }
];

plan tests => 1*blocks;

filters {
    input    => [qw/yaml response fetch_content remove_space/],
    expected => [qw/remove_space/],
};

sub response {
    my $input = shift;
    my $res = HTTP::Response->new(200);
    $res->header('Content-Type' => 'text/html');
    $res->content($input->{html});
    Moxy::Plugin::DisplayWidth->response_filter(
        {},
        {
            response         => $res,
            mobile_attribute => HTTP::MobileAttribute->new( $input->{ua} )
        }
    );
    $res;
}

sub fetch_content {
    my $res = shift;
    $res->content;
}

sub remove_space { my $x = shift; $x =~ s/^\s+//mg; $x =~ s/\n//g; $x }

run_is input => 'expected';

__END__

=== regression test.
--- input
ua: 'Mozilla/4.0 (compatible; MSIE 4.0; MSN 2.5; Windows 95)'
html: |+
  <html>
    <head></head>
    <body></body>
  </html>
--- expected
<html>
  <head></head>
  <body></body>
</html>

=== docomo
--- input
ua: 'DoCoMo/2.0 SH901iC(c100;TB;W24H12)'
html: |+
  <html>
    <head></head>
    <body></body>
  </html>
--- expected
<html><head></head><body><div style="border: 1px black solid; width: 240px; margin: 0 auto;float: left; height: 90%; overflow: auto;"></div></body></html>

=== wx310k(willcom)
--- input
ua: 'Mozilla/3.0(WILLCOM;KYOCERA/WX310K/2;1.1.5.15.000000/0.1/C100) Opera 7.0'
html: |+
  <html>
    <head></head>
    <body></body>
  </html>
--- expected
<html><head></head><body><div style="border: 1px black solid; width: 320px; margin: 0 auto;float: left; height: 90%; overflow: auto;"></div></body></html>

