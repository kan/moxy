package Moxy::Plugin::DisplayWidth;
use strict;
use warnings;
use base qw/Moxy::Plugin/;

# HTML全体の横幅をUAの画面サイズに合わせる
sub response_filter :Hook {
    my ($class, $context, $args) = @_;
    my $attr = $args->{mobile_attribute};

    # スマートフォンの場合はnon_mobileになるが、X-DISPLAY-SIZEヘッダーが定義されていれば
    # それをdisplay sizeとして採用する
    my $width;
    if ($attr->is_non_mobile) {
        $width = $attr->request->get('X-DISPLAY-SIZE');
        return if !$width || $width !~ /^\d+\*\d+$/;
        $width =~ s/\*.+//;
    }
    # HTTP::MobileAttribute::Plugin::Display は AirHPhone に対応していない。
    # が、ディスプレイ幅の指定がないと利用に耐えないので、現行機種のほとんどが 320px であることが下記 URL より確認できるので
    # http://www.willcom-inc.com/ja/lineup/spec/voice/index.html
    # 320px 固定にしておく。だれか Willcom が大好きでたまらないような人があらわれたら対応してください。
    else {
        $width = $attr->is_airh_phone ? 320 : $attr->display->width;
    }
    $width ||= 320; # なんかうまくとれなかったときのデフォルトのサイズは 320 とする。とくに理由はない。

    my $header = qq!<div style="border: 1px black solid; width: ${width}px; margin: 0 auto;float: left;">!;

    my $content = $args->{response}->content;
    $content =~ s!(<body[^>]*>)!$1$header!i;
    $content =~ s!(</body>)!"</div>$1"!ie;
    $args->{response}->content($content);
}

1;
__END__

=for stopwords localsrc HTML

=head1 NAME

Moxy::Plugin::DisplayWidth - limit the HTML width

=head1 SYNOPSIS

  - module: HTMLWidth

=head1 DESCRIPTION

limit the HTML width

=head1 AUTHOR

Kan Fushihara

Tokuhiro Matsuno

=head1 SEE ALSO

L<Moxy>
