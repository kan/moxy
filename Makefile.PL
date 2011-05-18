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

requires 'Plack'                          => '0.9032';
requires 'Plack::Middleware::ReverseProxy' => '0.05';
requires 'Class::Component'               => 0.17;
requires 'Encode::JP::Mobile'             => 0.25;
requires 'HTML::ReplacePictogramMobileJp' => 0.06;
requires 'HTML::Tree'                     => 3.23;
requires 'HTML::TreeBuilder::XPath'       => 0.09;
requires 'Params::Validate'               => 0.91;
requires 'Template'                       => 2.19;
requires 'UNIVERSAL::require'             => '0.11';
requires 'Class::Accessor';
requires 'HTTP::MobileAttribute' => 0.13;
requires 'Path::Class';
requires 'HTTP::Session' => 0.41;
requires 'HTTP::Cookies'; # part of LWP
requires 'Test::More' => 0.96;
requires 'NDBM_File';

test_requires('Test::More');
test_requires('Test::Requires');

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

if (eval "use Module::Install::AuthorTests;1;") {
    author_tests('xt');
}

use_test_base;
auto_set_repository();
install_script glob('script/*.pl');
WriteAll;

