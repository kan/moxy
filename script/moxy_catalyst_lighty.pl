#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use File::Spec;
use lib File::Spec->catfile( $FindBin::Bin, '..', 'lib' );

use Catalyst::Engine::HTTP::Restarter::Watcher;
use File::Temp;
use File::Which qw/which/;
use MIME::Types;
use Parallel::SubFork qw/sub_fork/;
use Path::Class qw/file dir/;
use Template;

use Getopt::Long;

GetOptions(
    \my %opt,
    qw/help debug restart lighttpd=s port=i/,
);
$opt{port} ||= 3000;
$opt{lighttpd} ||= which('lighttpd') || '/usr/sbin/lighttpd';

$ENV{CATALYST_DEBUG} = 1 if $opt{debug};

my $home = dir($FindBin::Bin)->parent;
my $tmp  = $home->subdir('tmp');

$tmp->mkpath unless -d $tmp;

sub spawn_fastcgi {
    my $fastcgi = $home->file('script', 'moxy_catalyst_fastcgi.pl');
    my $socket  = $tmp->file('socket');

    exec "$fastcgi", '-l', "$socket", '-e';
}

sub restarter {
    # spawn FastCGI
    my $task = sub_fork(\&spawn_fastcgi);
    print STDERR qq/Restarter: spawn FastCGI (pid @{[ $task->pid ]})\n/;

    # copied from Catalyst::Engine::HTTP::Restarter
    my $watcher = Catalyst::Engine::HTTP::Restarter::Watcher->new(
        directory => "$home",
        regex     => '\.yml$|\.yaml$|\.pm$',
        delay     => 1,
    );

    while (1) {
        my @files = $watcher->watch;
        # check if our parent process has died
        exit if $^O ne 'MSWin32' and getppid == 1;

        if (@files) {
            my $files = join ', ', @files;
            print STDERR qq/File(s) "$files" modified, restarting\n\n/;

            # shutdown FastCGI
            kill TERM => $task->pid;
            $task->wait_for;
            print STDERR qq/Restarter: shutdown FastCGI (pid @{[ $task->pid ]})\n/;

            # restart FastCGI
            $task = sub_fork(\&spawn_fastcgi);
            print STDERR qq/Restarter: spawn FastCGI (pid @{[ $task->pid ]})\n/;
        }
    }
}

{
    my $task = sub_fork( $opt{restart} ? \&restarter : \&spawn_fastcgi );

    my $fh  = File::Temp->new;

    my $mime_types = do {
        my $res = "mimetype.assign = (\n";
        my %known_extensions;
        my $types = MIME::Types->new(only_complete => 1);
        for my $type ( $types->types ) {
            for my $ext ( sort map { lc } $type->extensions ) {
                next if $known_extensions{$ext}++;
                $res .= qq{".$ext" => "$type",\n};
            }
        }
        $res .= ")\n";
        $res;
    };

    my $template = <<'__CONF__';
server.modules = (
    "mod_fastcgi",
)

server.document-root = "[% home.subdir('root') %]"
server.port = [% opt.port %]

[% mime_types %]

$HTTP["url"] =~ "^/(?!js/|css/|images?/|swf/|static/|tmp/|favicon\.ico$|crossdomain\.xml$)" {
    fastcgi.server = (
        "" => (
            (
                "socket" => "[% home.file('tmp', 'socket') %]",
                "check-local" => "disable",
                "allow-x-send-file" => "enable",
            )
        ),
    )
}

__CONF__

    my $tt = Template->new;
    $tt->process(
        \$template,
        {   home       => $home,
            opt        => \%opt,
            mime_types => $mime_types,
        },
        \my $conf
    );

    print $fh $conf;

    system( $opt{lighttpd}, '-f', $fh->filename, '-D' );
}
