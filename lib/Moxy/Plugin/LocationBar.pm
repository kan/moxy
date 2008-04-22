package Moxy::Plugin::LocationBar;
use strict;
use warnings;
use base qw/Moxy::Plugin/;
use Carp;
use HTML::Entities;

sub control_panel: Hook('control_panel') {
    my ($self, $context, $args) = @_;
    croak "invalid args" if ref $args ne 'HASH';

    return render_control_panel($args->{response}->request->uri);
}

sub render_control_panel {
    my $current_url = shift;

    return sprintf(<<"...", encode_entities($current_url));
    <form method="get">
        <input type="text" value="\%s" size="40" name="moxy_q" />
        <input type="submit" value="go" />
    </form>
...
}

1;
