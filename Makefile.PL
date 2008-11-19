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

requires 'App::Cmd'                       => 0.200;
requires 'Class::Component'               => 0.17;
requires 'Encode::JP::Mobile'             => 0.25;
requires 'HTML::ReplacePictogramMobileJp' => 0.06;
requires 'HTML::Tree'                     => 3.23;
requires 'HTML::TreeBuilder::XPath'       => 0.09;
requires 'HTTP::Engine'                   => '0.0.14';
requires 'Params::Validate'               => 0.91;
requires 'Template'                       => 2.19;
requires 'UNIVERSAL::require'             => '0.11';
requires 'CGI';
requires 'Carp';
requires 'Class::Accessor';
requires 'FindBin';
requires 'HTTP::MobileAttribute';
requires 'Path::Class';
requires 'HTTP::Session' => 0.20;
requires 'HTTP::Cookies';

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

