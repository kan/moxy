package Moxy::Plugin::ControlPanel;
use strict;
use warnings;
use base qw/Moxy::Plugin/;
use Path::Class;
use B;
use Moxy::Util;

sub register {
    my ($class, $context) = @_;

    $context->register_hook(
        response_filter => sub {
            my ($context, $args) = @_;

            return unless (($args->{response}->header('Content-Type')||'') =~ /html/);

            $context->log("debug" => "generate ControlPanel");

            my @parts;
            for my $action ($context->get_hooks('control_panel')) {
                push @parts,
                    {
                    module => B::svref_2object($action)->GV->STASH->NAME,
                    html   => $action->( $context, $args )
                    };
            }

            my $output = $class->render_template(
                $context,
                'panelcontainer.tt' => {
                    parts => \@parts, 
                }
            );

            my $charset = Moxy::Util->detect_charset($args->{response}, ${$args->{content_ref}});

            # convert html charset to response charset.
            my $enc = Encode::find_encoding($charset);
            Encode::from_to($output, 'utf-8', $enc ? $enc->name : 'utf-8');

            # insert control panel to html response.
            ${ $args->{content_ref} } =~ s!(<body.*?>)!"$1$output"!ie;
        }
    );
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
