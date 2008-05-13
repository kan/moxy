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

requires 'Class::Component' => 0.16;
requires 'HTTP::Engine' => '0.0.5';
requires 'HTTP::MobileAttribute';
requires 'CGI';
requires 'FindBin';
requires 'Path::Class';
requires 'Template';
requires 'Carp';
requires 'App::Cmd' => '0.013';
requires 'Class::Accessor';
requires 'UNIVERSAL::require' => '0.11';
requires 'Encode::JP::Mobile' => 0.22;
requires 'HTML::ReplacePictogramMobileJp' => 0.05;
requires 'HTTP::Proxy';
requires 'Params::Validate';
requires 'HTML::Tree' => 3.23;
requires 'App::Cmd' => 0.013;

build_requires('Test::More');
build_requires('Path::Class');

features(
    'Better Encoding detection' => [
        recommends_hack('Encode::Detect', 1.0),
        -default => 0,
    ],
    'POD Testing' => [
        recommends_hack('Test::Pod'),
        recommends_hack('Test::Pod::Coverage'),
        -default => 0,
    ],
);

tests 't/*.t t/*/*.t t/*/*/*.t';

auto_include;
auto_install;

use_test_base;

install_script glob('script/*.pl');
WriteAll;

