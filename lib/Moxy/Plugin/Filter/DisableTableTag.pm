package Moxy::Plugin::Filter::DisableTableTag;
use strict;
use warnings;
use base qw/Moxy::Plugin/;
use HTML::Parser;

sub register {
    my ($class, $context) = @_;

    $context->register_hook(
        response_filter_I => sub {
            my ( $context, $args ) = @_;

            # only for html.
            return unless (($args->{response}->header('Content-Type')||'') =~ /html/);

            my $output = '';
            my $parser = HTML::Parser->new(
                api_version   => 3,
                start_h       => [ sub {
                    my ($tagname, $attr, $orig) = @_;

                    if ($tagname =~ /^(table|thead|tbody|tfoot|tr|th|td)$/i) {
                        return;
                    } else {
                        $output .= $orig;
                        return;
                    }

                }, "tagname, attr, text" ],
                end_h  => [ sub { $output .= shift }, "text"],
                text_h => [ sub { $output .= shift }, "text"],
            );

            $parser->boolean_attribute_value('__BOOLEAN__');
            $parser->parse(${ $args->{content_ref} });

            ${ $args->{content_ref} } = $output;
        }
    );
}

1;
__END__

=encoding utf8

=for stopwords docomo

=head1 NAME

Moxy::Plugin::Filter::DisableTableTag - docomo can't use <TABLE>

=head1 SYNOPSIS

  - module: DisableTableTag

=head1 DESCRIPTION

DoCoMo real machine can't use <TABLE><TR><TH><TD> tags.
This plugin can simulate it.

This plugin cut these tags.

=head1 AUTHOR

Kan Fushihara

