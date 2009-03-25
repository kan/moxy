use strict;
use warnings;
use Test::More tests => 1;
use Moxy;
use HTTP::Request;
use FindBin;
use File::Spec::Functions;
use HTTP::Response;
use HTTP::Request;
use HTTP::Engine;

my $moxy = Moxy->new(
    {
        global => {
            assets_path => catfile( $FindBin::Bin, '..', '..', 'assets' ),
            'log' => {
                level => 'debug',
            },
            session => {
                store => {
                    module => 'Test',
                    config => {},
                },
            }
        },
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
    my $res = HTTP::Engine->new(
        interface => {
            module          => 'Test',
            args            => {},
            request_handler => sub {
                my $req = shift;
                $moxy->handle_request($req);
            },
        }
    )->run($req);
    is $res->header('Location'), $expected;
}

test('http://localhost/http://uaswitcher.moxy/http://d.hatena.ne.jp/', 'http://localhost/http%3A%2F%2Fd.hatena.ne.jp%2F');

