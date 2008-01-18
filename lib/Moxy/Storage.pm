package Moxy::Storage;
use strict;
use warnings;
use Carp;

sub new { croak 'this is abstract method' }
sub set { croak 'this is abstract method' }
sub get { croak 'this is abstract method' }

1;
__END__

=head1 NAME

Moxy::Storage - abstract base class of Storage classes

=head1 ABSTRACT METHODS

    new
    set
    get

=head1 AUTHORS

Tokuhiro Matsuno

=head1 SEE ALSO

L<Moxy>, L<HTTP::Proxy>

