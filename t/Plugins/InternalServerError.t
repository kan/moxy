use strict;
use warnings;
use Moxy;
use HTTP::Request;
use Test::More tests => 1;
use HTTP::Session::State::Test;
use HTTP::Session::Store::Test;
use CGI;
use HTTP::Request::Common;

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
my $session_store = HTTP::Session::Store::Test->new();

# display control panel when 500!
{
    my $res = HTTP::Response->new(500);
    $res->content('you got a error');
    $m->run_hook('status_handler' => { response => $res, session => session()});
    like($res->content, qr{-- moxy});
}

sub session {
    HTTP::Session->new(
        state => HTTP::Session::State::Test->new(
            session_id => 'fkldsaaljasdfafaa',
            permissive => 1,
        ),
        store   => $session_store,
        request => CGI->new(),
    )
}

