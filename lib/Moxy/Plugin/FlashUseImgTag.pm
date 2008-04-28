package Moxy::Plugin::FlashUseImgTag;
use strict;
use warnings;
use base qw/Moxy::Plugin/;
use HTML::Parser;

sub response_filter :CarrierHook('E') {
    my ( $self, $context, $args ) = @_;

    # only for html.
    return unless (($args->{response}->header('Content-Type')||'') =~ /html/);

    my $output = '';
    my $parser = HTML::Parser->new(
        api_version   => 3,
        start_h       => [ sub {
            my ($tagname, $attr, $orig) = @_;

            if ($tagname =~ /^img$/i && $attr->{src} =~ /\.swf$/) {
                $output .= qq|
                    <object data="@{[$attr->{src}]}" width="@{[$attr->{width}]}" height="@{[$attr->{height}]}" 
                            type="application/x-shockwave-flash">
                        <param name="bgcolor" value="#ffffff" />
                        <param name="loop" value="off" />
                        <param name="quality" value="high" />
                        <param name="salign" value="t" />
                    </object>
                |;
            } else {
                $output .= $orig;
                return;
            }

        }, "tagname, attr, text" ],
        end_h  => [ sub { $output .= shift }, "text"],
        text_h => [ sub { $output .= shift }, "text"],
    );

    $parser->boolean_attribute_value('__BOOLEAN__');
    $parser->parse( $args->{response}->content );

    $args->{response}->content( $output );
}

1;
__END__

=head1 NAME

Moxy::Plugin::FlashUseImgTag - ezweb can use <img src="/boofy.swf">

=head1 SYNOPSIS

  - module: FlashUseImgTag

=head1 DESCRIPTION

EZweb real machine can use <img src="/boofy.swf" /> style.
This plugin can simulate it.

This plugin replace img tag to object tag.

=head1 AUTHOR

Kan Fushihara

