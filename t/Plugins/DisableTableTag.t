use strict;
use warnings;
use Moxy;
use HTTP::Request;
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
            { module => 'DisableTableTag' },
        ],
    }
);

filters {
    input    => [qw/response response_filter fetch_content remove_space/],
    expected => [qw/remove_space/],
};

sub response {
    my $html = shift;
    my $res = HTTP::Response->new(200);
    $res->header('Content-Type' => 'text/html');
    $res->content($html);
    $res;
}

sub response_filter {
    my $res = shift;
    $m->run_hook('response_filter_I', { response => $res });
    $res;
}

sub fetch_content {
    my $res = shift;
    $res->content;
}

sub remove_space { my $x = shift; $x =~ s/^\s+//mg; $x =~ s/\n//g; $x }

run_is input => 'expected';

__END__

===
--- input
<table>
    <tr>
        <td>foo</td>
        <th>bar</th>
    </tr>
</table>
--- expected
foo
bar

