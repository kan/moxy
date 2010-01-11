use strict;
use FindBin;
use File::Spec;
use File::Basename;
use lib File::Spec->catfile( dirname(__FILE__), 'lib' );
use Plack::Builder;

use Moxy;

# preload
use Encode::JP::Mobile;

my $config = +{
    global => {
        timeout => 16,
        session => {
            state => { module => 'BasicAuth', },
        },
        assets_path => File::Spec->catfile(dirname(__FILE__), 'assets'),
    },
};
my $moxy = Moxy->new($config);
builder {
    enable_if { $_[0]->{REMOTE_ADDR} eq '127.0.0.1' } 
            "Plack::Middleware::ReverseProxy";

    $moxy->to_app();
};

