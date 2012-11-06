use strict;
use warnings;
use utf8;
use Test::Requires 'Test::WWW::Mechanize::PSGI', 'HTTP::Server::PSGI', 'Test::TCP';
use Test::More;
use Moxy;
use FindBin;
use File::Spec::Functions qw/catfile/;
use Test::TCP;

binmode Test::More->builder->$_, ":utf8" for qw/output failure_output todo_output/;

my $moxy = Moxy->new();
my $app = $moxy->to_app();

# -------------------------------------------------------------------------

my $server = Test::TCP->new(
    code => sub {
        my $port = shift;
        my $server = HTTP::Server::PSGI->new(
            host => '127.0.0.1',
            port => $port,
            timeout => 10,
        );
        $server->run(sub {
             no utf8;
             my $content = '<html><head></head><body>お気軽メッセージングハブ</body></html>';
             return [200, [
                'Content-Type' => 'text/html; charset=utf-8',
                'Content-Length' => length($content)
            ], [$content]];
        });
    },
);
my $port = $server->port;

# -------------------------------------------------------------------------

my $mech = Test::WWW::Mechanize::PSGI->new(app => $app);
$mech->get('/');
is $mech->res->code(), 401;
$mech->credentials('oh', 'my god');
$mech->get_ok('/');
$mech->content_contains('http%3A%2F%2Fuaswitcher.moxy%2F', "user agent switcher's url is converted");
$mech->get_ok("/http://127.0.0.1:$port/");
$mech->content_contains('お気軽');

done_testing;
