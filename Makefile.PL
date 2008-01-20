use strict;
use warnings;
use inc::Module::Install;

name("Moxy");
all_from("lib/Moxy.pm");

requires('HTTP::MobileAgent');
requires('CGI');
requires('FindBin');
requires('Path::Class');
requires('YAML');
requires('Template');
requires('Carp');
requires('Getopt::Long');
requires('Pod::Usage');
requires('Class::Accessor');
requires('UNIVERSAL::require');
requires('Log::Dispatch');
requires('Encode::JP::Mobile' => 0.22);
requires 'HTML::ReplacePictogramMobileJp' => 0.03;
requires 'HTTP::Proxy';
requires 'Params::Validate';

build_requires('Test::More');
build_requires('Path::Class');
build_requires('Web::Scraper' => 0.24);

features(
    'Better Encoding detection' => [
        -default => 0,
        recommends('Encode::Detect', 1.0),
    ],
    'POD Testing' => [
        -default => 0,
        recommends('Test::Pod'),
        recommends('Test::Pod::Coverage'),
    ],
);

tests 't/*.t t/*/*.t t/*/*/*.t';

auto_include;
auto_install;

install_script('moxy.pl');
WriteAll;

