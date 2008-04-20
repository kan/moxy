#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use Path::Class;
use YAML;
use Getopt::Long;
use Pod::Usage;

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
my $server = 'HTTPProxy';
my $port = 5963;
my $host = 'localhost';

Getopt::Long::GetOptions(
    '--man'           => \my $man,
    '--daemon'        => \my $daemon,
    '--config=s'      => \$conf_file,
    '--server=s'      => \$server,
    '--port=i'        => \$port,
    '--host=i'        => \$host,
    '--max-clients=i' => \my $max_clients,
) or pod2usage(2);
Getopt::Long::Configure("bundling");
pod2usage(-verbose => 2) if $man;

my $config = YAML::LoadFile($conf_file);
$config->{global}->{log} ||= { level => 'debug' };

sub start {
    my $moxy = Moxy->new($config);
    my $server_module = "Moxy::Server::$server";
    $server_module->use or die $@;
    $server_module->run(
        $moxy => {
            port        => $port,
            host        => $host,
            max_clients => $max_clients,
        }
    );
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
        --server       => HTTPProxy or POE
        --port         => default: 5963
        --host         => default: localhost

=head1 DESCRIPTION

Proxy server for mobile web service development.

