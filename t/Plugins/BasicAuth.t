use strict;
use warnings;
use Moxy;
use HTTP::Request;
use Test::More tests => 4;
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

# display the id/pw input form when you got a 401
{
    my $res = HTTP::Response->new(401);
    $res->header('WWW-Authenticate' => 'Basic realm="secret"');
    $res->request(
        HTTP::Request->new('GET', '/', HTTP::Headers->new(
            'Host' => 'example.com',
        ))
    );
    $m->run_hook('status_handler' => { response => $res, session => session()});
    like($res->content, qr{<input type="text" name="host" value="example.com" />});
}

# save id/pw
{
    my $req = POST 'http://basicauth.moxy/http://example.com/',
      [ 'id' => 'dankogai', 'pw' => 'kogaidan' ],
      ;
    my $res = $m->run_hook_and_get_response('url_handle' => { request => $req, session => session()});
    is $res->code, 302, 'save id/pw';
    is($res->header('Location'), 'http://example.com/', 'location');
}

# request filter works?
{
    my $req = GET '/',
        Headers => [
            'Host' => 'example.com',
        ],
      ;
    $m->run_hook(
        'request_filter' => {
            request          => $req,
            session          => session(),
            mobile_attribute => HTTP::MobileAttribute->new( $req->headers )
        }
    );
    is($req->authorization_basic, 'dankogai:kogaidan', 'authorization basic');
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

