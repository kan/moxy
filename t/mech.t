use strict;
use warnings;
use utf8;
use Test::Requires 'Test::WWW::Mechanize::PSGI';
use Test::More;
use Moxy;
use FindBin;
use File::Spec::Functions qw/catfile/;

binmode Test::More->builder->$_, ":utf8" for qw/output failure_output todo_output/;

my $moxy = Moxy->new();
my $app = $moxy->to_app();

# -------------------------------------------------------------------------

my $mech = Test::WWW::Mechanize::PSGI->new(app => $app);
$mech->get('/');
is $mech->res->code(), 401;
$mech->credentials('oh', 'my god');
$mech->get_ok('/');
$mech->content_contains('http%3A%2F%2Fuaswitcher.moxy%2F', "user agent switcher's url is converted");
$mech->get_ok('/http://wassr.jp/');
$mech->content_contains('お気軽');

done_testing;
