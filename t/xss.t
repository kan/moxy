use strict;use warnings;
use Moxy::Plugin::Application;
use Test::More tests => 1;

unlike(Moxy::Plugin::Application->_render_control_panel('http://example.com/', '<script>alert("FOO");</script>'), qr{<script>});
