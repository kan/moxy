package Moxy::Plugin::ShowHTMLSource;
use strict;
use warnings;
use base qw/Moxy::Plugin/;
use Encode;

# FIXME: mojibake

sub control_panel :Hook {
    my ($self, $context, $args) = @_;

    $context->log(debug => 'dump html source');

    my $charset = $args->{response}->charset;
    my $enc = Encode::find_encoding($charset);
    return $self->render_template(
        $context,
        'panel.tt' => {
            html => decode($enc, $args->{response}->content()),
        }
    );
}

1;
__END__

=head1 NAME

Moxy::Plugin::ShowHTMLSource - show html source in control panel.

=head1 SYNOPSIS

  - module: ShowHTMLSource

=head1 DESCRIPTION

show html source on control panel, for debugging.

=head1 AUTHOR

Tokuhiro Matsuno
