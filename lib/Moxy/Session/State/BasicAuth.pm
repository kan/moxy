package Moxy::Session::State::BasicAuth;
use Moose;
with 'HTTP::Session::Role::State';

has realm => (
    is  => 'rw',
    isa => 'Str',
    default => 'Moxy needs basic auth.Only for identification.Password is dummy.',
);

has '+permissive' => ( 'default' => 1 );

sub get_session_id {
    my ( $self, $req ) = @_;
    $ENV{HTTP_AUTHORIZATION} || $req->header('Authorization');
}

sub response_filter { }

no Moose;
__PACKAGE__->meta->make_immutable;
1;

