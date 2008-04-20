use strict;
use warnings;
use Moxy;
use Test::More tests => 1;

unlike(Moxy->render_control_panel('http://example.com/', '<script>alert("FOO");</script>'), qr{<script>alert});

