use strict;
use warnings;
use Moxy;
use HTTP::Request;
use Test::Base;
use FindBin;
use File::Spec::Functions;
use HTTP::Response;

eval "use HTML::StripScripts::Parser";
plan skip_all => "this test requires HTML::StripScripts::Parser" if $@;
plan tests => 1*blocks;

my $m = Moxy->new(
    {
        global => {
            assets_path => catfile( $FindBin::Bin, '..', '..', 'assets' ),
            'log' => {
                level => 'info',
            },
        },
        plugins => [
            { module => 'StripScripts' },
        ],
    }
);

filters {
    input    => [qw/response response_filter fetch_content remove_space/],
    expected => [qw/remove_space/],
};

sub response {
    my $html = shift;
    my $res = HTTP::Response->new(200);
    $res->header('Content-Type' => 'text/html');
    $res->content($html);
    $res;
}

sub response_filter {
    my $res = shift;
    $m->run_hook('security_filter', {
        response         => $res,
        mobile_attribute => HTTP::MobileAttribute->new('DoCoMo/2.0 SH901iC(c100;TB;W24H12)'),
    });
    $res;
}

sub fetch_content {
    my $res = shift;
    $res->content;
}

sub remove_space { my $x = shift; $x =~ s/^\s+//mg; $x =~ s/\n//g; $x }

run_is input => 'expected';

__END__

===
--- input
<html><body>
<script>alert(document.cookie)</script>
<p>foobar</p>
</body></html>
--- expected
<html><body><!--filtered--><!--filtered--><p>foobar</p></body></html>

===
--- input
<html><body>
<IMG SRC="javascript:alert('XSS');">
</body></html>
--- expected
<html><body><img /></body></html>

===
--- SKIP
--- input
<html><body><marquee loop="3" behavior="scroll">foo</marquee></body></html>
--- expected
<html><body><img /></body></html>

===
--- SKIP
--- input
<html><head><link rel="stylesheet" href="/style.css" type="text/css" /></head><body></body></html>
--- expected
<html><body><img /></body></html>

