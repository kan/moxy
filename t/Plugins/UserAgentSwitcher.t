use strict;
use warnings;
use Test::More tests => 1;
use Moxy;
use HTTP::Request;
use FindBin;
use File::Spec::Functions;
use HTTP::Response;
use HTTP::Request;
use HTTP::Message::PSGI;

my $moxy = Moxy->new(
    {
        plugins => [
            { module => 'UserAgentSwitcher' },
        ],
    }
);

sub test {
    my ($input, $expected) = @_;
    my $req = HTTP::Request->new(
        GET => $input
    );
    $req->authorization_basic('foobar');
    my $app = $moxy->to_app();
    my $res = res_from_psgi($app->($req->to_psgi));
    is $res->header('Location'), $expected;
}

test('http://localhost/http://uaswitcher.moxy/http://d.hatena.ne.jp/', 'http://localhost/http%3A%2F%2Fd.hatena.ne.jp%2F');

