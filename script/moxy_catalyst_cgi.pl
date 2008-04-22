#!/usr/bin/perl -w

BEGIN { $ENV{CATALYST_ENGINE} ||= 'CGI' } ## no critic.

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Moxy::Catalyst;

Moxy::Catalyst->run;

1;

=for stopwords cgi

=head1 NAME

moxy_catalyst_cgi.pl - Catalyst CGI

=head1 SYNOPSIS

See L<Catalyst::Manual>

=head1 DESCRIPTION

Run a Catalyst application as a cgi script.

=head1 AUTHOR

Sebastian Riedel, C<sri@oook.de>

=head1 COPYRIGHT


This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
