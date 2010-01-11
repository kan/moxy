use strict;
use FindBin;
use File::Spec;
use File::Basename;
use lib File::Spec->catfile( dirname(__FILE__), 'lib' );
use Plack::Builder;

use Moxy;

# preload
use Encode::JP::Mobile;

my $moxy = Moxy->new(+{
    # configuration here
});
print "assets path is: @{[ $moxy->assets_path ]}\n";

builder {
    enable_if { $_[0]->{REMOTE_ADDR} eq '127.0.0.1' } 
            "Plack::Middleware::ReverseProxy";

    $moxy->to_app();
};

