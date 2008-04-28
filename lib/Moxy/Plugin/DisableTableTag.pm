package Moxy::Plugin::DisableTableTag;
use strict;
use warnings;
use base qw/Moxy::Plugin/;
use HTML::Parser;

my $TABLE_TAGS = +{ map { $_ => 1 } qw/table thead tbody tfoot tr th td/ };

sub _is_table_tag {
    my ($tag, ) = @_;
    $TABLE_TAGS->{ lc $tag } ? 1 : 0;
}

sub response_filter :CarrierHook('I') {
    my ( $self, $context, $args ) = @_;

    # only for html.
    return unless (($args->{response}->header('Content-Type')||'') =~ /html/);

    my $output = '';
    my $parser = HTML::Parser->new(
        api_version   => 3,
        start_h       => [ sub {
            my ($tagname, $attr, $orig) = @_;
            unless (_is_table_tag($tagname)) {
                $output .= $orig;
            }
        }, "tagname, attr, text" ],
        end_h  => [ sub {
            my ($tagname, $orig) =  @_;
            unless (_is_table_tag($tagname)) {
                $output .= $orig;
            }
        }, "tagname, text"],
        text_h => [ sub { $output .= shift }, "text"],
    );

    $parser->boolean_attribute_value('__BOOLEAN__');
    $parser->parse( $args->{response}->content );

    $args->{response}->content( $output );
}

1;
__END__

=encoding utf8

=for stopwords docomo

=head1 NAME

Moxy::Plugin::DisableTableTag - docomo can't use <TABLE>

=head1 SYNOPSIS

  - module: DisableTableTag

=head1 DESCRIPTION

DoCoMo real machine can't use <TABLE><TR><TH><TD> tags.
This plugin can simulate it.

This plugin cut these tags.

=head1 AUTHOR

Kan Fushihara

