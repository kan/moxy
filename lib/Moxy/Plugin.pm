package Moxy::Plugin;
use strict;
use warnings;

use YAML;
use Path::Class;
use HTTP::MobileAgent;
use Carp;
use Template;

sub assets_path {
    my ($proto, $context) = @_;
    croak "argument \$context missing" unless ref $context;

    my $module = $proto;
    $module =~ s/^Moxy::Plugin:://;
    $module =~ s/::/-/g;

    return dir($context->assets_path, 'plugins', $module)->stringify;
}

sub render_template {
    my ($self, $context, $fname, $args) = @_;
    croak "render_template is class method" if ref $self;

    my $tt = Template->new(ABSOLUTE => 1);
    $tt->process(
        file($self->assets_path($context), $fname)->stringify,
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
