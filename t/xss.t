use strict;
use warnings;
use Moxy::Plugin::Server;
use Test::More tests => 1;

unlike(Moxy::Plugin::Server::render_control_panel('http://example.com/', '<script>alert("FOO");</script>'), qr{<script>});
