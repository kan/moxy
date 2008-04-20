package Moxy::Plugin::Filter::GPS;
use strict;
use warnings;
use base qw/Moxy::Plugin/;
use Moxy::Plugin::Filter::GPS::EZweb;

sub register {
    my ($class, $c) = @_;
    $c->load_plugins(map { "Filter::GPS::$_"} qw/EZweb AirHPhone DoCoMo ThirdForce/);
}

1;
__END__

=head1 NAME

Moxy::Plugin::Filter::GPS - gps simulation for Moxy

=head1 SYNOPSIS

  - module: GPS

=head1 DESCRIPTION

GPS simulation feature for Moxy.

=head1 AUTHOR

Tokuhiro Matsuno

=head1 TODO

    support gpsone(au)
    support select pos

=head1 SEE ALSO

L<Moxy>
