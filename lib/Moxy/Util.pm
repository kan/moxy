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

sub detect_charset {
    my ($class, $response, $body) = @_;

    my $charset;
    if ($response->header('Content-Type') =~ /charset=([\w\-]+)/io) {
        $charset = $1;
    }
    $charset ||= ( $body =~ /<\?xml version="1.0" encoding="([\w\-]+)"\?>/ )[0]; 
    $charset ||= ( $body =~ m!<meta http-equiv="Content-Type" content=".*charset=([\w\-]+)"!i )[0]; 
    $charset ||= $Detector->($body); 
    $charset ||= 'utf-8'; 

    return $charset;
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

