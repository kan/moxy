package Moxy::Plugin::AuthorizationCutter;
use strict;
use warnings;
use base qw/Moxy::Plugin/;

sub request_filter: Hook {
    my ($self, $context, $args) = @_;

    $args->{request}->remove_header('Authorization');

}

1;
__END__

=head1 NAME

Moxy::Plugin::AuthorizationCutter

=head1 SYNOPSIS

  - module: AuthorizationCutter

=head1 DESCRIPTION

do not send Authorization.

=head1 AUTHOR

Sugano Yoshihisa(E)
