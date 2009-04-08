package Moxy::Plugin::Status::500;
use strict;
use warnings;
use base qw/Moxy::Plugin/;

sub status_handler : Hook {
    my ( $self, $context, $args ) = @_;

    my $response = $args->{response};

    # handle internal server error
    # do not display f*cking plain html page when got a 500.
    if ($response->code eq 500 && $response->content !~ /<body>/) {
        $response->content_type('text/html');
        $response->content(qq{
            <html>
                <head><title>internal server error occured</title></head>
                <body>
                    <div style="color: red; font-weight: bold; font-size: xx-large;">you got a 500 internal server error</div>
                    <div>@{[ $response->content ]}</div>
                    <div>-- moxy</div>
                </body>
            </html>
        });
    }

    $response;
}

1;
