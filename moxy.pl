#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use File::Spec::Functions;
use lib catfile( $FindBin::Bin, 'lib' );
use Moxy::Cmd;

Moxy::Cmd->run;
