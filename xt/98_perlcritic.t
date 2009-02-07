use strict;
use warnings;
use Test::More;
eval q[require Test::Perl::Critic; Test::Perl::Critic->import(-profile => 'xt/perlcriticrc')];
plan(skip_all => "Test::Perl::Critic required for testing PBP compliance") if $@;

Test::Perl::Critic::all_critic_ok();
