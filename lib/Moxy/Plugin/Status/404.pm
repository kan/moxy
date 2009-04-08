package Moxy::Plugin::Status::404;
use strict;
use warnings;
use base qw/Moxy::Plugin/;

sub status_handler : Hook {
    my ( $self, $context, $args ) = @_;

    my $response = $args->{response};

    # handle internal server error
    # do not display f*cking plain html page when got a 404.
    if ($response->code eq 404 && $response->content !~ /<body>/) {
        $response->content_type('text/html');
        $response->content(qq{
            <html>
                <head><title>file not found occured</title></head>
                <body>
                    <div style="color: yellow; background-color: black; font-weight: bold; font-size: xx-large;">you got a 'file not found'</div>
                    <div>@{[ $response->content ]}</div>
                    <div>-- moxy</div>
                </body>
            </html>
        });
    }

    $response;
}

1;
