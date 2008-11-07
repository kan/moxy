package Moxy::Plugin;
use strict;
use warnings;
use base qw/Class::Component::Plugin/;
use YAML;
use Path::Class;
use Carp;
use Template;

sub assets_path {
    my ($proto, $context) = @_;
    croak "argument \$context missing" unless ref $context;

    my $module = ref $proto || $proto;
    $module =~ s/^Moxy::Plugin:://;
    $module =~ s/::/-/g;

    dir($context->assets_path, 'plugins', $module);
}

sub render_template {
    my ($self, $context, $fname, $args) = @_;

    my $tt = Template->new(
        ABSOLUTE => 1,
        ENCODING => 'utf8',
    );
    $tt->process(
        $self->assets_path($context)->file($fname)->stringify,
        $args,
        \my $output
    ) or die $tt->error;
    return $output;
}

1;
__END__

=head1 NAME

Moxy::Plugin - abstract base class of Moxy plugin

=head1 DESCRIPTION

This is abstract base class of Moxy plugins.

=head1 AUTHOR

    Kan Fushihara
    Tokuhiro Matsuno

=head1 SEE ALSO

L<Moxy>
