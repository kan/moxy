package Moxy::Plugin::ControlPanel;
use strict;
use warnings;
use base qw/Moxy::Plugin/;
use Moxy::Util;

sub response_filter: Hook {
    my ($self, $context, $args) = @_;

    return unless (($args->{response}->header('Content-Type')||'') =~ /html/);

    $context->log("debug" => "generate ControlPanel");

    my @parts = do {
        my @r;
        for my $hook (@{$context->class_component_hooks->{'control_panel'}}) {
            my ($plugin, $method) = ($hook->{plugin}, $hook->{method});
            push @r, { title => sub { (my $x = ref $plugin) =~ s/.+:://; $x }->(), body => $plugin->$method($context, $args) };
        }
        @r;
    };

    my $output = $self->render_template(
        $context,
        'panelcontainer.tt' => {
            parts => \@parts, 
        }
    );

    # convert html charset to response charset.
    my $charset = $args->{response}->charset;
    my $enc = Encode::find_encoding($charset);
    $output = Encode::encode(($enc ? $enc->name : 'utf-8'), $output);

    # insert control panel to html response.
    my $content = $args->{response}->content;
    $content =~ s!(</body>)!$output$1!i;
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
