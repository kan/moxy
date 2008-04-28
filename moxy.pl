#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use Path::Class;
use YAML;
use Getopt::Long;
use Pod::Usage;
use HTTP::Engine;

use lib file( $FindBin::RealBin, 'lib' )->stringify;
use Moxy;

sub stdio_close {
    close(STDIN);
    close(STDOUT);
    close(STDERR);

    open(STDIN,  "+>/dev/null"); ## no critic.
    open(STDOUT, "+>&STDIN");    ## no critic.
    open(STDERR, "+>&STDIN");    ## no critic.
}

my $conf_file = file( $FindBin::RealBin, 'config.yaml' )->stringify;

Getopt::Long::GetOptions(
    '--man'           => \my $man,
    '--daemon'        => \my $daemon,
    '--config=s'      => \$conf_file,
) or pod2usage(2);
Getopt::Long::Configure("bundling");
pod2usage(-verbose => 2) if $man;

my $config = YAML::LoadFile($conf_file);
$config->{global}->{log} ||= { level => 'debug' };

sub start {
    my $moxy = Moxy->new($config);
    my $server_conf = {
        global => $config->{global},
        plugins => [
            $config->{global}->{server}
        ]
    };
    HTTP::Engine->new(
        config         => $server_conf,
        handle_request => sub {
            my $c = shift;
            eval {
                my $response =
                  $moxy->handle_request( request => $c->req->as_http_request, );
                $c->res->set_http_response($response);
            };
            if ($@) {
                warn $@;
                $c->res->status(500);
                $c->res->body($@);
            }
        },
    )->run;
}

if ($daemon) {
    if (my $pid = fork) {
        exit 0; 
    } elsif (defined $pid) {
        stdio_close();
        start();
    } else {
        die "fork failed: $@";
    }
} else {
    start();
}

__END__

=head1 SYNOPSIS

    $ moxy.pl

    Options:
        --daemon       => run as daemon
        --config=s     => path to config file(default: config.yaml)
        --man          => show this manual

=head1 DESCRIPTION

Proxy server for mobile web service development.
