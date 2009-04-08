#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use File::Spec::Functions;
use lib catfile( $FindBin::Bin, 'lib' );
use Getopt::Long qw/GetOptions/;
use File::Temp ();
use Moxy;
use HTTP::Engine;
use Hash::Merge;
use Pod::Usage; # core module

&main; exit;

sub main {
    GetOptions(
        'daemonize' => \my $daemonize,
        'port=i'    => \my $port,
        'log=s'     => \my $log,
        'timeout=i' => \my $timeout,
        'db=s'      => \my $sessiondb,
        'assets=s'  => \my $assets,
        'conf=s'    => \my $conffile,
        'help'      => \my $help,
    ) or pod2usage();
    pod2usage() if $help;

    # set default value
    $sessiondb ||= File::Temp->new( UNLINK => 1 );
    $port      ||= 3128;
    $log       ||= 'info';
    $timeout   ||= 16;
    $assets    ||= catfile( $FindBin::RealBin, 'assets' );

    my $conf = +{
        global => {
            server => {
                module => 'ServerSimple',
                args   => { port => $port, }
            },
            timeout => $timeout,
            log     => { level => $log, },
            session => {
                state => { module => 'BasicAuth', },
                store => {
                    module => 'DBM',
                    config => {
                        file => "$sessiondb", # we need stringify for file::temp
                        dbm_class => 'NDBM_File',
                    },
                },
            },
            assets_path => $assets,
        },
    };

    if ($conffile) {
        my $fconf = YAML::LoadFile($conffile);
        Hash::Merge::set_behavior('RIGHT_PRECEDENT');
        $conf = Hash::Merge::merge($conf, $fconf);
    }

    _run($daemonize, $conf);
}

sub _run {
    my ($daemonize_fg, $config) = @_;

    if ($daemonize_fg) {
        if (my $pid = fork) {
            exit 0; 
        } elsif (defined $pid) {
            _stdio_close();
            _start($config);
        } else {
            die "fork failed: $@";
        }
    } else {
        _start($config);
    }
}

sub _start {
    my ($config) = @_;

    my $moxy = Moxy->new($config);
    HTTP::Engine->new(
        interface => {
            module => $config->{global}->{server}->{module},
            args =>   $config->{global}->{server}->{args},
            request_handler => sub {
                my $req = shift;
                $moxy->handle_request( $req );
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

__END__

=head1 NAME

moxy.pl - bootstrap script for moxy

=head1 SYNOPSIS

    $ moxy.pl
        --daemonize         # daemonize or not?
        --port=4455         # specify your favorite port number
        --log=debug         # log level
        --timeout=3         # timeout
        --assets=/my/assets # path to assets dir
        --db=~/.moxy.db     # path to session db
        --help              # display this help message

