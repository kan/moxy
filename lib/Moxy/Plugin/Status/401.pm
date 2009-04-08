package Moxy::Plugin::Status::401;
use strict;
use warnings;
use base qw/Moxy::Plugin/;
use URI::Escape 'uri_unescape';

sub status_handler : Hook {
    my ( $self, $context, $args ) = @_;

    my $response = $args->{response};
    if ( $response->code eq 401 ) {
        my $host = $response->request->header('Host');
        my $referer = $response->request->uri;
        $response->code(200);
        $response->content(
            qq{<html>
            <head><title>you need a authentication</title></head>
            <body>
                <h1>you should input the authentication info</h1>
                <form method="post" action="http://basicauth.moxy/$referer">
                    <table>
                    <tr>                                                                                              <th>id</th>
                        <td><input type="text" name="id" /></td>
                    </tr>
                    <tr>
                        <th>pw</th>
                        <td><input type="password" name="pw" /></td>
                    </tr>
                    <tr>
                        <td colspan="2">
                            <input type="text" name="host" value="@{[ $host ]}" />
                            <input type="submit" value="submit" />
                        </td>
                    </tr>
                    </table>
                </form>
            </body>
        </html>
        }
        );
    }
}

sub url_handle : Hook {
    my ( $self, $context, $args ) = @_;

    if ( $args->{request}->uri =~ m{^http://basicauth\.moxy/(.+)} ) {
        my $back = uri_unescape($1);
        my $r    = CGI->new( $args->{request}->content );

        # store to user stash.
        my $key = join( ',', __PACKAGE__, $r->param('host') );
        $args->{session}
          ->set( $key => $r->param('id') . ':' . $r->param('pw') );

        my $response = HTTP::Response->new( 302, 'Moxy(BasicAuth)' );
        $response->header( Location => $back );
        $response;
    }
}

sub request_filter : Hook {
    my ( $self, $context, $args ) = @_;

    my $key = join( ',', __PACKAGE__, $args->{request}->header('Host') );
    my $idpw = $args->{session}->get($key);
    if ($idpw) {
        $context->log( 'debug' => "your user id:pw is $idpw" );
        $args->{request}->authorization_basic(split /:/, $idpw);
    }
}

1;
__END__

=head1 NAME

Moxy::Plugin::BasicAuth - basic auth

=head1 DESCRIPTION

basic auth handler for moxy.

This plugin is a part of default plugins.This plugin load automatically :)

=head1 AUTHOR

tokuhirom

=head1 SEE ALSO

L<Moxy>

