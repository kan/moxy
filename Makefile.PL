use strict;
use warnings;
use inc::Module::Install;

name("Moxy");
all_from("lib/Moxy.pm");

{
    no warnings 'redefine';
    *recommends_hack = $Module::Install::VERSION > 0.70 ?
        sub { recommends(@_); $_[0] } :
        \&recommends;
}

requires 'Class::Component' => 0.17;
requires 'HTTP::Engine' => '0.0.14';
requires 'HTTP::MobileAttribute';
requires 'CGI';
requires 'FindBin';
requires 'Path::Class';
requires 'Template' => 2.19;
requires 'Carp';
requires 'App::Cmd' => '0.013';
requires 'Class::Accessor';
requires 'UNIVERSAL::require' => '0.11';
requires 'Encode::JP::Mobile' => 0.22;
requires 'HTML::ReplacePictogramMobileJp' => 0.06;
requires 'Params::Validate' => 0.91;
requires 'HTML::Tree' => 3.23;
requires 'App::Cmd' => 0.013;
requires 'HTML::TreeBuilder::XPath' => 0.09;

test_requires('Test::More');
test_requires('Path::Class');

features(
    'Better Encoding detection' => [
        recommends_hack('Encode::Detect', 1.0),
        -default => 0,
    ],
    'Plugin::StripScripts' => [
        recommends_hack('HTML::StripScripts', 1.04),
        recommends_hack('HTML::StripScripts::Parser', 1.02),
        -default => 0,
    ],
    'Plugin::Scrubber' => [
        recommends_hack('HTML::Scrubber', 1.04),
        -default => 0,
    ],
);

tests 't/*.t t/*/*.t t/*/*/*.t';

author_tests('xt');

use_test_base;

install_script glob('script/*.pl');
WriteAll;

