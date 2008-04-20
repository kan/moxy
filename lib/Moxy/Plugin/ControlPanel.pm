package Moxy::Plugin::ControlPanel;
use strict;
use warnings;
use base qw/Moxy::Plugin/;
use Moxy::Util;

sub render: Hook('response_filter') {
    my ($self, $context, $args) = @_;

    return unless (($args->{response}->header('Content-Type')||'') =~ /html/);

    $context->log("debug" => "generate ControlPanel");

    my $output = $self->render_template(
        $context,
        'panelcontainer.tt' => {
            parts => $context->run_hook('control_panel' => $args), 
        }
    );

    # convert html charset to response charset.
    my $charset = $args->{response}->charset;
    my $enc = Encode::find_encoding($charset);
    Encode::from_to($output, 'utf-8', $enc ? $enc->name : 'utf-8');

    # insert control panel to html response.
    my $content = $args->{response}->content;
    $content =~ s!(<body.*?>)!"$1$output"!ie;
    $args->{response}->content($content);
}

1;
__END__

=head1 NAME

Moxy::Plugin::ControlPanel - control panel for moxy

=head1 SYNOPSIS

  - module: ControlPanel

=head1 DESCRIPTION

Moxy's control panel.

A lot of plugins depend to this plugin.We recommends you enable this plugin.

=head1 AUTHOR

    Kan Fushihara
    Tokuhiro Matsuno

=head1 SEE ALSO

L<Moxy>
