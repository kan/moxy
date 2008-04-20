package Moxy::Util;
use strict;
use warnings;

# -------------------------------------------------------------------------
# detect response charset.
#   see Plagger::Util

my $Detector;
BEGIN {
    if ( eval { require Jcode; 1 } ) {
        $Detector = sub { my ($code, $nmatch) = Jcode::getcode($_[0]); $code };
    } elsif ( eval { require Encode::Detect::Detector; 1 } ) {
        $Detector = sub { Encode::Detect::Detector::detect($_[0]) };
    } else {
        require Encode::Guess;
        $Detector = sub {
            my @guess = qw(utf-8 euc-jp shift_jis); # xxx japanese only?
            eval { Encode::Guess::guess_encoding($_[0], @guess)->name };
        };
    }
}

sub HTTP::Response::charset {
    my ($self, ) = @_;

    return $self->{__charset} ||= do {
        my $charset;
        if ( $self->header('Content-Type') =~ /charset=([\w\-]+)/io ) {
            $charset = $1;
        }
        $charset ||= ( $self->content() =~ /<\?xml version="1.0" encoding="([\w\-]+)"\?>/ )[0];
        $charset ||= ( $self->content() =~ m!<meta http-equiv="Content-Type" content=".*charset=([\w\-]+)"!i)[0];
        $charset ||= $Detector->( $self->content() );
        $charset ||= 'cp932';
        $charset;
    };
}

1;
__END__

=head1 NAME

Moxy::Util - utility functions

=head1 SYNOPSIS

this is just a internal class.

=head1 AUTHORS

Tokuhiro Matsuno

=head1 SEE ALSO

L<Moxy>, L<HTTP::Proxy>

