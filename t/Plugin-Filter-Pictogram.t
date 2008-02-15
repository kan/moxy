use strict;
use warnings;
use Test::More tests => 5;
use HTTP::Request;
use Moxy;
use File::Spec;
use FindBin;

my $c = Moxy->new(
    {
        global => {
            assets_path => File::Spec->catfile( $FindBin::Bin, '..', 'assets' )
        },
        plugins => [
            { module => 'Server::HTTPProxy' },
            { module => 'Filter::Pictogram' },
        ]
    }
);
&check_request;
&check_response;

# -------------------------------------------------------------------------

sub check_request {
    my @hooks = $c->get_hooks('request_filter');
    is scalar(@hooks), 1;

    my $response = $hooks[0]->(
        $c => {
            request =>
              HTTP::Request->new( 'GET', 'http://pictogram.moxy/E/EC69.gif' )
        }
    );
    is $response->code,         200;
    is $response->content_type, 'image/gif';
}

# -------------------------------------------------------------------------

sub check_response {
    my @hooks = $c->get_hooks('response_filter_E');
    is scalar(@hooks), 1;

    my $content = '&#xE001;';
    my $response= HTTP::Response->new(200);
    $response->header('Content-Type' => 'text/html');
    $hooks[0]->(
        $c => {
            response    => $response,
            content_ref => \$content,
        }
    );
    is $content, qq{<img src='http://pictogram.moxy/E/E001.gif' style='width:1em; height:1em; border: none;' alt="E001" />\n};
}

