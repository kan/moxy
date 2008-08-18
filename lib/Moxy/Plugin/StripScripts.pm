package Moxy::Plugin::StripScripts;
use strict;
use warnings;
use base qw/Moxy::Plugin/;
use Moxy::Util;
use HTML::StripScripts::Parser;

sub security_filter : Hook {
    my ($self, $context, $args) = @_;

    return unless (($args->{response}->header('Content-Type')||'') =~ /html/);

    $context->log("debug" => "strip scripts");

    $args->{response}->content(do {
        my $hss = HTML::StripScripts::Parser->new(
            {
                Context             => 'Document',
                AllowSrc            => 1,
                AllowHref           => 1,
            },
            strict_comments => 1,
            strict_names    => 1,
        );
        $hss->parse( $args->{response}->content );
        $hss->eof;
        $hss->filtered_document;
    });
}

1;
__END__

=head1 NAME

Moxy::Plugin::StripScripts - Strip scripting constructs out of HTML

=head1 SYNOPSIS

  - module: StripScripts

=head1 DESCRIPTION

XXX THIS PLUGIN STRIPS A LOT OF TAGS! TOOOOO STRICT!! DO NO USE THIS ! XXX

remove javascript from response.

=head1 AUTHOR

    Tokuhiro Matsuno

=head1 SEE ALSO

L<Moxy>, L<HTML::StripScripts>, L<HTML::StripScripts::Parser>

