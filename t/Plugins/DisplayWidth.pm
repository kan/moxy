use strict;
use warnings;
use Moxy;
use HTTP::Request;
use Test::Base;
use FindBin;
use File::Spec::Functions;
use HTTP::Response;

plan tests => 1*blocks;

my $m = Moxy->new(
    {
        global => {
            assets_path => catfile( $FindBin::Bin, '..', 'assets' ),
            storage => {
                module    => 'DBM_File',
                file      => 't/testing.ndbm',
                dbm_class => 'NDBM_File',
            },
            'log' => {
                level => 'info',
            },
        },
        plugins => [
            { module => 'DisplayWidth' },
        ],
    }
);

filters {
    input    => [qw/yaml response fetch_content remove_space/],
    expected => [qw/remove_space/],
};

sub response {
    my $input = shift;
    my $res = HTTP::Response->new(200);
    $res->header('Content-Type' => 'text/html');
    $res->content($input->{html});
    $m->run_hook('response_filter', { response => $res, mobile_attribute => HTTP::MobileAttribute->new( $input->{ua} ) });
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
<html><head></head><body><div style="border: 1px black solid; width: 240px"></div></body></html>

