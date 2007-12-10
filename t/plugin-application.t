use strict;
use warnings;
use Test::Base;
use Moxy::Plugin::Application;

sub rewrite {
    Moxy::Plugin::Application::_rewrite('http://localhost:9999/', shift, 'http://relative.example.jp/');
}

filters {
    input => ['rewrite'],
    expected => ['chomp'],
};

plan tests => 1*blocks;

run_is input => 'expected';

__END__

===
--- input
<a href="http://example.com/foo" title="foo">bar</a>
--- expected
<a href="http://localhost:9999/?q=http%3A%2F%2Fexample.com%2Ffoo" title="foo">bar</a>

=== relative
--- input
<a href="/foo" title="foo">bar</a>
--- expected
<a href="http://localhost:9999/?q=http%3A%2F%2Frelative.example.jp%2Ffoo" title="foo">bar</a>

===
--- input
<A href="http://example.com/foo" title="foo">bar</A>
--- expected
<a href="http://localhost:9999/?q=http%3A%2F%2Fexample.com%2Ffoo" title="foo">bar</A>

===
--- input
<a href="http://example.com/foo">bar</a>
--- expected
<a href="http://localhost:9999/?q=http%3A%2F%2Fexample.com%2Ffoo">bar</a>

===
--- input
<a>bar</a>
--- expected
<a>bar</a>

===
--- input
<form method="post" action="http://example.com/search"><input type="submit" value="go" /></form>
--- expected
<form action="http://localhost:9999/?q=http%3A%2F%2Fexample.com%2Fsearch" method="post"><input type="submit" value="go" /></form>

=== relative
--- input
<form method="post" action="/search"><input type="submit" value="go" /></form>
--- expected
<form action="http://localhost:9999/?q=http%3A%2F%2Frelative.example.jp%2Fsearch" method="post"><input type="submit" value="go" /></form>

=== relative img
--- input
<img src="/foo.jpg" />
--- expected
<img src="http://localhost:9999/?q=http%3A%2F%2Frelative.example.jp%2Ffoo.jpg">

=== abs img
--- input
<img src="http://example.com/bar.jpg" />
--- expected
<img src="http://localhost:9999/?q=http%3A%2F%2Fexample.com%2Fbar.jpg">
