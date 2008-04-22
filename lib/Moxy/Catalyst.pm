package Moxy::Catalyst;
use strict;
use warnings;
use Catalyst::Runtime '5.70';
use Catalyst qw/-Debug ConfigLoader/;

__PACKAGE__->config( name => 'Moxy::Catalyst', parse_on_demand => 1 );

__PACKAGE__->setup;


1;
__END__

=head1 NAME

Moxy::Catalyst - Catalyst based application

=head1 SYNOPSIS

    script/moxy_catalyst_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<Moxy::Catalyst::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Tokuhiro Matsuno

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
