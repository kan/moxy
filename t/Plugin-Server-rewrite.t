use strict;
use warnings;
use Test::Base;
use Moxy;

sub _rewrite {
    Moxy::rewrite_html('http://localhost:9999/', shift, 'http://relative.example.jp/');
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
<a href="http://example.com/foo" title="foo">bar</a>
--- expected
<html><a href="http://localhost:9999/http%3A%2F%2Fexample.com%2Ffoo" title="foo">bar</a></html>

=== relative
--- input
<a href="/foo" title="foo">bar</a>
--- expected
<html><a href="http://localhost:9999/http%3A%2F%2Frelative.example.jp%2Ffoo" title="foo">bar</a></html>

=== upper case tag
--- input
<A href="http://example.com/foo" title="foo">bar</A>
--- expected
<html><a href="http://localhost:9999/http%3A%2F%2Fexample.com%2Ffoo" title="foo">bar</a></html>

===
--- input
<a href="http://example.com/foo">bar</a>
--- expected
<html><a href="http://localhost:9999/http%3A%2F%2Fexample.com%2Ffoo">bar</a></html>

=== no href.
--- input
<a>bar</a>
--- expected
<html><a>bar</a></html>

===
--- input
<form method="post" action="http://example.com/search"><input type="submit" value="go" /></form>
--- expected
<html><form action="http://localhost:9999/http%3A%2F%2Fexample.com%2Fsearch" method="post"><input type="submit" value="go" /></form></html>

=== relative
--- input
<form method="post" action="/search"><input type="submit" value="go" /></form>
--- expected
<html><form action="http://localhost:9999/http%3A%2F%2Frelative.example.jp%2Fsearch" method="post"><input type="submit" value="go" /></form></html>

=== relative img
--- input
<img src="/foo.jpg" />
--- expected
<html><img src="http://localhost:9999/http%3A%2F%2Frelative.example.jp%2Ffoo.jpg" /></html>

=== abs img
--- input
<img src="http://example.com/bar.jpg">
--- expected
<html><img src="http://localhost:9999/http%3A%2F%2Fexample.com%2Fbar.jpg" /></html>

=== p img
--- input
<p>foo</p>
--- expected
<html><p>foo</p></html>

