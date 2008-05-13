package Moxy::Cmd;
use strict;
use warnings;
use base qw/App::Cmd::Simple/;

use File::Spec::Functions;
use FindBin;
use HTTP::Engine '0.0.5';
use Moxy;
use YAML;

sub opt_spec {
    return (
        [ 'daemonize|d' => "daemonize" ],
        [
            'config|c' => "path to configuration file",
            { default => catfile( $FindBin::Bin, 'config.yaml' ) }
        ],
        [ 'help|h' => "display manual" ]
    );
}

sub validate_args {
    my ($self, $opt, $args) = @_;
    die $self->usage() if $opt->{help};
}

sub run {
    my ($self, $opt, $args) = @_;

    my $config = YAML::LoadFile( $opt->{config} );
    $config->{global}->{log} ||= { level => 'debug' };

    if ($opt->{daemonize}) {
        if (my $pid = fork) {
            exit 0; 
        } elsif (defined $pid) {
            $self->_stdio_close();
            $self->_start($config);
        } else {
            die "fork failed: $@";
        }
    } else {
        $self->_start($config);
    }
}

sub _start {
    my ($self, $config) = @_;

    my $moxy = Moxy->new($config);
    HTTP::Engine->new(
        interface => {
            module => $config->{global}->{server}->{module},
            args =>   $config->{global}->{server}->{args},
            request_handler => sub {
                my $c = shift;
                $moxy->handle_request( $c );
            },
        }
    )->run;
}

sub _stdio_close {
    close(STDIN);
    close(STDOUT);
    close(STDERR);

    open(STDIN,  "+>/dev/null"); ## no critic.
    open(STDOUT, "+>&STDIN");    ## no critic.
    open(STDERR, "+>&STDIN");    ## no critic.
}

1;
