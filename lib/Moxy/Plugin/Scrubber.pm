package Moxy::Plugin::Scrubber;
use strict;
use warnings;
use base qw/Moxy::Plugin/;
use Moxy::Util;
use HTML::Scrubber;

sub rules {
    return (
        img => {
            src => qr{^http://},    # only URL with http://
            alt => 1,               # alt attributes allowed
            '*' => 0,               # deny all others
        },
        style  => 0,
        script => 0,
        link => {
            href => qr{^http://},    # only URL with http://
            rel => 1,
            type => 1,
        },
    );
}

sub default {
    return (
        '*'    => 0,                        # default rule, deny all attributes
        'href' => qr{^(?!(?:java)?script)}i,
        'src'  => qr{^(?!(?:java)?script)}i,
        'cite'     => '(?i-xsm:^(?!(?:java)?script))',
        'language' => 0,
        'name'        => 1,                 # could be sneaky, but hey ;)
        'onblur'      => 0,
        'onchange'    => 0,
        'onclick'     => 0,
        'ondblclick'  => 0,
        'onerror'     => 0,
        'onfocus'     => 0,
        'onkeydown'   => 0,
        'onkeypress'  => 0,
        'onkeyup'     => 0,
        'onload'      => 0,
        'onmousedown' => 0,
        'onmousemove' => 0,
        'onmouseout'  => 0,
        'onmouseover' => 0,
        'onmouseup'   => 0,
        'onreset'     => 0,
        'onselect'    => 0,
        'onsubmit'    => 0,
        'onunload'    => 0,
        'src'         => 0,
        'type'        => 0,
        'style'       => 0,
        'loop'        => qr{^\d+$},
        'behaivour'   => qr{^(?:scroll|alternate|slide)$},
    );
}

sub security_filter : Hook {
    my ($self, $context, $args) = @_;

    return unless (($args->{response}->header('Content-Type')||'') =~ /html/);

    $context->log("debug" => "strip scripts");

    $args->{response}->content(do {
        my $scrubber = HTML::Scrubber->new();
        $scrubber->rules( rules() );
        $scrubber->default( default() );
        $scrubber->scrub( $args->{response}->content );
    });
}

1;
__END__

=head1 NAME

Moxy::Plugin::Scrubber - Strip scripting constructs out of HTML

=head1 SYNOPSIS

  - module: Scrubber

=head1 DESCRIPTION

XXX THIS PLUGIN STRIPS A LOT OF TAGS! TOOOOO STRICT!! DO NO USE THIS ! XXX

remove javascript from response.

=head1 AUTHOR

    Tokuhiro Matsuno

=head1 SEE ALSO

L<Moxy>, L<HTML::Scrubber>

