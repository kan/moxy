use strict;
use FindBin;
use File::Spec;
use File::Basename;
use lib File::Spec->catfile( dirname(__FILE__), 'lib' );
use File::Temp;

use HTTP::Engine;
use Moxy;

my $sessiondb = File::Temp->new( UNLINK => 1 );
my $config = +{
    global => {
        timeout => 16,
        log     => { level => 'info', },
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
        assets_path => File::Spec->catfile( dirname(__FILE__), 'assets' ),
    },
};
my $moxy = Moxy->new($config);
my $engine = HTTP::Engine->new(
    interface => {
        module => 'PSGI',
        args =>   $config->{global}->{server}->{args},
        request_handler => sub {
            $moxy->handle_request( @_ );
        },
    }
);
my $app = sub { $engine->run(@_) };

