package Moxy::Session::State::BasicAuth;
use HTTP::Session::State::Base;

sub realm { 'Moxy needs basic auth.Only for identification.Password is dummy.' }

sub new {
    bless {permissive => 1}, shift;
}

sub get_session_id {
    my ( $self, $req ) = @_;
    $ENV{HTTP_AUTHORIZATION} || $req->header('Authorization');
}

sub response_filter { }

1;

