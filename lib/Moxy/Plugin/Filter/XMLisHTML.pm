package Moxy::Plugin::Filter::XMLisHTML;
use strict;
use warnings;

sub register {
    my ($class, $context) = @_;

    $context->register_hook(
        response_filter => sub {
            my ($context, $args) = @_;

            $args->{response}->header( 'Content-Type' => 'text/html' ) if $args->{response}->header( 'Content-Type' ) =~ /xml/;
        }
    );
}

1;
__END__

=for stopwords: html xml

=head1 NAME

Moxy::Plugin::Filter::XMLisHTML - XML is HTML

=head1 SYNOPSIS

    - module: XMLisHTML

=head1 DESCRIPTION

If you want to use the CSS, DoCoMo UA needs to use 'application/xhtml+xml' for Content-Type.
But, DoCoMo's XHTML is not valid, likes '<a href="/login" utn>login</a>', Firefox reject this... orz.

This plugin replace Content-Type header.

=head1 AUTHORS

Tokuhiro Matsuno

=head1 SEE ALSO

L<Moxy>

