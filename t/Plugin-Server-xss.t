use strict;
use warnings;
use Moxy;
use Test::More tests => 1;

unlike(Moxy->render_start_page('http://example.com/', '<script>alert("FOO");</script>'), qr{<script>alert});

