package Moxy::Plugin;
use strict;
use warnings;

use YAML;
use Path::Class;
use HTTP::MobileAgent;
use Carp;
use Template;

sub _get_config {
    my ($proto, $context) = @_;

    my ($module,) = ($proto =~ m/Moxy::Plugin::([^:]+)/);

    for my $conf (@{$context->config->{plugins}}) {
        if ($conf->{module} eq $module) {
            return $conf || {};
        }
    }

    die "can't find $module";
}

sub _load_file {
    my ($proto, $context, $filename) = @_;

    return file($proto->assets_path($context), $filename)->slurp;
}

sub _load_yaml {
    my ($proto, $context, $filename) = @_;

    return YAML::LoadFile( file($proto->assets_path($context), $filename) );
}

sub config {
    my ($proto, $context) = @_;

    return $proto->_get_config($context)->{config} || {};
}

sub assets_path {
    my ($proto, $context) = @_;
    croak "argument \$context missing" unless ref $context;

    return dir($context->assets_path, 'plugins', $proto->_get_config($context)->{module})->stringify;
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
