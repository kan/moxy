use strict;
use warnings;
use Moxy::Plugin::RefererCutter;
use Moxy;
use HTTP::Request;
use Test::More tests => 2;
use HTTP::Session::State::Test;
use HTTP::Session::Store::Test;
use CGI;

Moxy->load_plugins(qw/RefererCutter/);
my $m = Moxy->new(
    {
        global => {
            assets_path => File::Spec->catfile( $FindBin::Bin, '..', 'assets' ),
            'log' => {
                level => 'info',
            },
        },
    }
);
my $req = HTTP::Request->new();
$req->header('Referer' => 'http://wassr.jp/');
$req->header('X-Moe' => 'nishiohirokazu');
$m->run_hook('request_filter' => { request => $req, session => HTTP::Session->new(
    state => HTTP::Session::State::Test->new(
        session_id => 'fkldsaaljasdfafaa',
    ),
    store => HTTP::Session::Store::Test->new,
    request => CGI->new(),
)});
is $req->header('X-Moe') => 'nishiohirokazu';
ok !$req->header('Referer');

