use strict;
use warnings;
use Moxy::Plugin::RefererCutter;
use Moxy;
use HTTP::Request;
use Test::More tests => 2;

Moxy->load_plugins(qw/RefererCutter/);
my $m = Moxy->new(
    {
        global => {
            assets_path => File::Spec->catfile( $FindBin::Bin, '..', 'assets' ),
            storage => {
                module    => 'DBM_File',
                file      => 't/testing.ndbm',
                dbm_class => 'NDBM_File',
            },
            'log' => {
                level => 'info',
            },
        },
    }
);
my $req = HTTP::Request->new();
$req->header('Referer' => 'http://wassr.jp/');
$req->header('X-Moe' => 'nishiohirokazu');
$m->run_hook('request_filter' => { request => $req });
is $req->header('X-Moe') => 'nishiohirokazu';
ok !$req->header('Referer');

