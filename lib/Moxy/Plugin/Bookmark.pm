package Moxy::Plugin::Bookmark;
use strict;
use warnings;
use base qw/Moxy::Plugin/;

sub control_panel :Hook {
    my ($self, $context, $args) = @_;

    my $bookmark = $self->config->{config}->{bookmark};

    return $self->render_template(
        $context,
        'panel.tt' => {
            bookmark => $bookmark, 
        }
    );
}

1;
__END__

=head1 NAME

Moxy::Plugin::Bookmark

=head1 SYNOPSIS

  - module: Bookmark

=head1 DESCRIPTION

View of Bookmark.

=head1 AUTHOR

Akiko Yokoyama

Tokuhiro Matsuno

