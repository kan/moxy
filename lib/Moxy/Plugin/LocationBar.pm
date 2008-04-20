package Moxy::Plugin::LocationBar;
use strict;
use warnings;
use base qw/Moxy::Plugin/;
use Carp;
use HTML::Entities;

sub control_panel: Hook('control_panel') {
    my ($self, $context, $args) = @_;
    croak "invalid args" if ref $args ne 'HASH';

    my $base = URI->new($args->{response}->request->uri);
    $base->query_form({});
    return render_control_panel($base, $args->{response}->request->uri);
}

sub render_control_panel {
    my ($base, $current_url) = @_;

    return sprintf(<<"...", encode_entities($current_url));
    <form method="get" action="$base">
        <input type="text" name="q" value="\%s" size="40" />
        <input type="submit" value="go" />
    </form>
...
}

1;
