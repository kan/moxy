# html filter
use strict;
use warnings;
use Moxy;
use HTTP::Response;
use Test::Base;
use FindBin;
use File::Spec::Functions;
use HTTP::Response;

plan tests => 1*blocks;

my $m = Moxy->new(
    {
        global => {
            assets_path => catfile( $FindBin::Bin, '..', 'assets' ),
            storage => {
                module    => 'DBM_File',
                file      => 't/testing.ndbm',
                dbm_class => 'NDBM_File',
            },
            'log' => {
                level => 'info',
            },
        },
        plugins => [
            { module => 'GPS' },
        ],
    }
);

filters {
    input    => [qw/yaml response response_filter fetch_content/],
};

sub response {
    my $input = shift;
    my $req = HTTP::Response->new();
    $req->header('Content-Type' => 'text/html');
    $req->content($input->{html});
    +{ response => $req, carrier => $input->{carrier} };
}

sub response_filter {
    my $input = shift;
    $m->run_hook("response_filter_$input->{carrier}", { response => $input->{response} });
    $input->{response};
}

sub fetch_content {
    my $req = shift;
    $req->content;
}

sub remove_space { my $x = shift; $x =~ s/^\s+//mg; $x =~ s/\n//g; $x }

run_is input => 'expected';

__END__

===
--- input
carrier: E
html: <a href="device:location?url=http://example.com/">get location</a>
--- expected: <a href="http://gps.moxy/au/?redirect_to=http://example.com/">get location</a>

===
--- input
carrier: V
html: <a href="location:cell?url=http://example.com/">get location</a>
--- expected: <a href="http://gps.moxy/softbank/?redirect_to=http%3A%2F%2Fexample.com%2F">get location</a>

