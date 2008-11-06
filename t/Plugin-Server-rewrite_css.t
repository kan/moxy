use strict;
use warnings;
use Test::Base;
use Moxy;

sub _rewrite {
    Moxy::rewrite_css('http://localhost:9999/', shift, 'http://relative.example.jp/');
}

sub remove_crlf {
    my $x = shift;
    $x =~ s/[\r\n]//g;
    $x;
}

filters {
    input => ['_rewrite', 'remove_crlf'],
    expected => ['chomp'],
};

plan tests => 1*blocks;

run_is input => 'expected';

__END__

===
--- input
body { background-image: url(/foo.css); }
--- expected
body { background-image: url(http://localhost:9999/http%3A%2F%2Frelative.example.jp%2Ffoo.css); }

===
--- input
body { background-image: url(http://example.jp/foo.css); }
--- expected
body { background-image: url(http://localhost:9999/http%3A%2F%2Fexample.jp%2Ffoo.css); }

