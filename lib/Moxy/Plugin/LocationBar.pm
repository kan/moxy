package Moxy::Plugin::LocationBar;
use strict;
use warnings;
use base qw/Moxy::Plugin/;
use Carp;
use HTML::Entities;

sub render_location_bar : Hook {
    my ($self, $context, $args) = @_;
    croak "invalid args" if ref $args ne 'HASH';
    return unless (($args->{response}->header('Content-Type')||'') =~ /html/);

    my $content = $args->{response}->content;
    my $bar = render_control_panel($args->{response}->request->uri);
    $content =~ s!(<body.*?>)!"$1$bar"!ie;
    $args->{response}->content( $content );
}

sub render_control_panel {
    my $current_url = shift;

    return sprintf(<<"...", encode_entities($current_url));
    <script>
        var moxy_base = location.protocol.replace(':', '') + '://' + location.host;
    </script>
    <form method="get" onsubmit="location.href=moxy_base +'/'+encodeURIComponent(document.getElementById('moxy_url').value);return false;">
        <input type="text" value="\%s" size="40" id="moxy_url" style="width:90%%;" />
        <input type="submit" value="go" />
    </form>
...
}

1;
