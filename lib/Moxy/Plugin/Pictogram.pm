package Moxy::Plugin::Pictogram;
use strict;
use warnings;
use base qw/Moxy::Plugin/;
use Moxy::Util;
use Path::Class;
use HTML::Entities::ImodePictogram qw/decode_pictogram find_pictogram/;

my $EZENTITIREF2EZPICTNUMBER;
my $ez_sjis_pattern;
my %ez_sjis_map;
my $ez_uni2number;

sub register {
    my ($class, $context) = @_;

    # pre loading data.

    {
        # EZ.UNI.HEX => EZ.PICT-NUMBER
        $EZENTITIREF2EZPICTNUMBER = $class->_load_yaml($context, 'ez.uni2number.yaml');

        # I.SJIS.HEX => EZ.PICT-NUMBER
        my $isjishex2ezpictnumber = $class->_load_yaml( $context, 'i2ezpict.yaml' );
        $EZENTITIREF2EZPICTNUMBER = { %$EZENTITIREF2EZPICTNUMBER, %$isjishex2ezpictnumber };
    }

    my $ez_code = $class->_load_file( $context, 'ez.sjis.txt' );
    $ez_sjis_pattern = join('|', grep { quotemeta($_) } split /\n/, $ez_code);
    my $cnt = 0;
    %ez_sjis_map = map { $_ =~ s/\\x//g; lc($_) => ++$cnt } split /\n/, $ez_code; ## no critic.

    # registering pictogram replacer.
    for my $carrier (qw/I E V/) {
        $context->register_hook( "response_filter_$carrier" => sub {
            my $method = "filter_pictogram_$carrier";
            $class->$method(@_) 
        });
    }
      # airH" uses DoCoMo's pictogram. so cool.
    $context->register_hook( response_filter_H => sub {
        $class->filter_pictogram_I(@_) 
    });

    # deliver pictogram
    $context->register_hook(request_filter => sub {
        my ($context, $args) = @_;

        if ($args->{request}->uri =~ m{http://pictogram\.moxy/([iev]/[0-9]+.gif)}) {
            my $fname = file($context->assets_path, "server", 'pictogram', $1);
            return 0 unless -f $fname;
            my $content = $fname->slurp;
            return 0 unless $content;

            my $response = HTTP::Response->new( 200, 'ok' );
            $response->header('Expires' => 'Thu, 15 Apr 2030 20:00:00 GMT');
            $response->content_type( "image/gif" );
            $response->content($content);
            $args->{filter}->proxy->response($response);
        }
    });
}

# generate pictogram html.
sub pict_html {
    my ($class, $context, $carrier, $number) = @_;

    my $pict_html = $class->_load_file( $context, 'pict.tmpl' );
    if ($class->config($context)->{no_pict}) {
        # 絵文字非表示モード
        return sprintf("[%s:%03d]", $carrier, $number||1);
    } else {
        return sprintf( $pict_html, $carrier, $number||1 );
    }
}

sub filter_pictogram_I {
    my ($class, $context, $args) = @_;

    # run only html
    return unless (($args->{response}->header('Content-Type')||'') =~ /html/);

    my $raw_text = decode_pictogram(${ $args->{content_ref} });
    find_pictogram($raw_text, sub {
                        my($char, $number, $cp) = @_;
                        return $class->pict_html($context, 'i', $number);
                   });

    ${ $args->{content_ref} } = $raw_text;
}

# take from HTML::Entities::ImodePictogram
my $one_byte  = '[\x00-\x7F\xA1-\xDF]';
my $two_bytes = '[\x81-\x9F\xE0-\xFC][\x40-\x7E\x80-\xFC]';
my $sjis_re   = qr<$one_byte|$two_bytes>;

sub filter_pictogram_E {
    my ($class, $context, $args) = @_;

    # run only html
    return unless (($args->{response}->header('Content-Type')||'') =~ /html/);

    my $disp = sub {
        my ($context, $carrier, $number) = @_;
        $class->pict_html($context, $carrier, sprintf("%d", $number||0));
    };

    # do convert pictogram
    ${ $args->{content_ref} } =~ s[(($ez_sjis_pattern)|$sjis_re)]
                                  [defined $2 ? $disp->($context, 'e', $ez_sjis_map{unpack("H*",$2)}) : $1]ige;
    ${ $args->{content_ref} } =~ s/<img[^<>]+localsrc=["'](\d+)[^<>]+>/$disp->($context, 'e', $1)/ige;
    ${ $args->{content_ref} } =~ s/&#(\d+);/$disp->($context, 'e', $EZENTITIREF2EZPICTNUMBER->{sprintf('%X', $1)})/gie;
    ${ $args->{content_ref} } =~ s/&#x(\w+);/$disp->($context, 'e', $EZENTITIREF2EZPICTNUMBER->{$1})/gie;
}


sub filter_pictogram_V {
    my ($class, $context, $args) = @_;

    # run only html
    return unless (($args->{response}->header('Content-Type')||'') =~ /html/);

    # see Encode::JP::Mobile::Vodafone
    # G! => E001, G" => E002, G# => E003 ...
    # E! => E101, F! => E201, O! => E301, P! => E401, Q! => E501
    my %HighCharToBit = (G => 0xE000, E => 0xE100, F => 0xE200,
                         O => 0xE300, P => 0xE400, Q => 0xE500);

    ${ $args->{content_ref} } =~ s{\x1b\x24([GEFOPQ])([\x20-\x7F]+)\x0f}{
        join '', map { $class->pict_html($context, 'v', ($HighCharToBit{$1} | ord($_) -32)) } split //, $2
    }ge;

    my $charset = Moxy::Util->detect_charset($args->{response}, $args->{content_ref});
    if ($charset =~ /utf-?8/i) {
        ${ $args->{content_ref} } =~ s/&#(\d+);/$class->pict_html($context, 'v', $1)/gie;
        ${ $args->{content_ref} } =~ s/&#x(\w+);/$class->pict_html($context, 'v', hex($1))/gie;
    }
}

1;
__END__

=for stopwords  pictograms

=head1 NAME

Moxy::Plugin::Pictogram - show pictograms

=head1 SYNOPSIS

  - module: Pictogram

=head1 DESCRIPTION

show pictograms.

=head1 SEE ALSO

L<Moxy>
