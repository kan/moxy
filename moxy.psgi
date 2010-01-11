use strict;
use FindBin;
use File::Spec;
use File::Basename;
use lib File::Spec->catfile( dirname(__FILE__), 'lib' );
use File::Temp;
use Plack::Builder;

use HTTP::Engine;
use Moxy;

# preload
use Encode::JP::Mobile;

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
        assets_path => '/usr/local/webapp/moxy/assets',
    },
};
my $moxy = Moxy->new($config);
my $engine = HTTP::Engine->new(
    interface => {
        module => 'PSGI',
        request_handler => sub {
            $moxy->handle_request( @_ );
        },
    }
);
builder {
    enable_if { $_[0]->{REMOTE_ADDR} eq '127.0.0.1' } 
            "Plack::Middleware::ReverseProxy";
    sub { $engine->run(@_) };
};

