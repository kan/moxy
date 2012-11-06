use strict;
use warnings;
use Test::More;
BEGIN {
    eval q[use Test::Spelling];
    plan(skip_all => "Test::Spelling required for testing spelling") if $@;
}

my @stopwords = split /\n/, <<'...';
Tokuhiro
Matsuno
Kazuhiro
Osawa
IP
ip
yaml
kensiro
sinsu
Miyagawa
Tatsuhiko
http
TODO
referer
DoCoMo
UA
XHTML
DoCoMo's
Firefox
orz
ControlPanel
Moxy
moxy
Moxy's
plugins
QRCode
Subno
EZweb
Kan
Fushihara
ezweb
img
GPS
gps
Plagger
UserAgent
pm
qpsmtpd
GhostScript
ImageMagick
debian
lha
lzh
svn
CookieCutter
DisableTableTag
FlashUseImgTag
HTMLWidth
HTTP
HTTPEnv
Pictogram
RefererCutter
ShowHTTPHeaders
UserAgentSwitcher
UserID
WILLCOM
XMLisHTML
au
localsrc
Daisuke
Murase
Riedel
CGI
FastCGI
uri
cgi
HTML
TOOOOO
XXX
javascript
Akiko
Yokoyama
Bookmark
html
tokuhirom
dankogai
kogaidan
auth
pl
Sugano
OpenSocial
opensocial
...

add_stopwords(@stopwords);
all_pod_files_spelling_ok;


