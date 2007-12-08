use strict;
use warnings;
use lib qw(./lib);
use Data::Dumper;
use Moxy;
use YAML;
use FindBin;
use File::Spec;

my $fname = File::Spec->catfile($FindBin::RealBin, 'config.yaml');
my $config = YAML::LoadFile($fname);
$config->{global}->{log}->{level} = 'error';
my $moxy = Moxy->new($config);

open my $fh, '>', 'deps.txt';
print $fh "$_\n" for sort {$a cmp $b} grep !/^\//, grep !/Moxy/, keys %INC;
close $fh;
