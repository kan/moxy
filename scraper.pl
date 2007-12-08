#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use File::Spec;
use lib File::Spec->catfile($FindBin::Bin, 'lib');

use Moxy::Scraper;
my @carrier = @ARGV ? @ARGV : qw/ i e v /;
Moxy::Scraper->new->run(@carrier);
