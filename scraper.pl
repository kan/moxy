#!/usr/bin/perl
use strict;
use warnings;

use Moxy::Scraper;
my @carrier = @ARGV ? @ARGV : qw/ i e v /;
Moxy::Scraper->new->run(@carrier);
