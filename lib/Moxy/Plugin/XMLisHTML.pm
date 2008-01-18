package Moxy::Plugin::XMLisHTML;
use strict;
use warnings;

sub register {
    my ($class, $context) = @_;

    $context->register_hook(
        response_filter_header => sub {
            my ($context, $args) = @_;

            $args->{response}->header( 'Content-Type' => 'text/html' ) if $args->{response}->header( 'Content-Type' ) =~ /xml/;
        }
    );
}

1;
__END__

=head1 DESCRIPTION

If you want to use the CSS, DoCoMo UA needs to use 'application/xhtml+xml' for Content-Type.
But, DoCoMo's XHTML is not valid, likes '<a href="/login" utn>login</a>', Firefox reject this... orz.

This plugin replace Content-Type header.

