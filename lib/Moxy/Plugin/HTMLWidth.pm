package Moxy::Plugin::HTMLWidth;
use strict;
use warnings;
use base qw/Moxy::Plugin/;

sub register {
    my ($class, $context) = @_;

    $context->register_hook(response_filter => sub { $class->response_filter(@_) });
}

# HTML全体の横幅をUAの画面サイズに合わせる
sub response_filter {
    my ($class, $context, $args) = @_;

    if ( $args->{agent} && $args->{agent}->{width} ) {
        my $header = sprintf(
            q{<div style="border: 1px black solid; 
                                            margin-right:auto; 
                                            margin-left:auto; 
                                            width: %dpx">}, $args->{agent}->{width}
        );
        ${ $args->{content_ref} } =~ s!(<body[^>]*>)!$1$header!i;
        ${ $args->{content_ref} } =~ s!(</body>)!"</div>$1"!ie;
    }
}

1;
__END__

=for stopwords localsrc HTML

=head1 NAME

Moxy::Plugin::HTMLWidth - limit the HTML width

=head1 SYNOPSIS

  - module: HTMLWidth

=head1 DESCRIPTION

limit the HTML width

=head1 SEE ALSO

L<Moxy>
