package Moxy::Storage::DBM_File;
use strict;
use warnings;
use base qw/Moxy::Storage/;
use Fcntl;
use UNIVERSAL::require;

sub new {
    my $class = shift;
    my $context = shift;
    my $config = shift;

    my $fname = $config->{file} || do {
        require File::Temp;
        (File::Temp::tempfile())[1];
    };
    $context->log(debug => "storage file is $fname");

    my $dbm_class = $config->{dbm_class} || 'GDBM_File';
    $dbm_class->use or die $@;

    bless {context => $context, fname => $fname, dbm_class => $dbm_class}, $class;
}

sub _open {
    my ($self, ) = @_;

    my %hash;
    tie %hash, $self->{dbm_class}, $self->{fname}, O_CREAT|O_RDWR, oct("600");
    return \%hash;
}

sub get {
    my ($self, $key) = @_;

    $self->{context}->log(debug => "get storage $key");

    $self->_open()->{$key};
}

sub set {
    my ($self, $key, $value) = @_;

    $self->{context}->log(debug => "set storage $key => $value");
    $self->_open()->{$key} = $value;
}

1;
__END__

=head1 NAME

Moxy::Storage::DBM_File - DBM_File based Storage class

=head1 AUTHORS

Tokuhiro Matsuno

=head1 SEE ALSO

L<Moxy>, L<HTTP::Proxy>

