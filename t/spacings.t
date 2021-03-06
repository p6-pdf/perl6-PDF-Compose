use v6;
use Test;
use PDF::Style::Body;
use PDF::Style::Element;
use CSS::Properties;
use CSS::Units :pt, :ops;
use PDF::Lite;

# also dump to HTML, for comparision

my CSS::Properties $css .= new: :style("font-family:Helvetica; width:250pt; height:80pt; position:absolute; top:20pt; left:20pt; border: 1px solid green");
my PDF::Style::Body $body .= new;
my @Html = '<html>', $body.html-start;

my PDF::Lite $pdf .= new;
my $page = $body.decorate: $pdf.add-page;
$page.gfx.comment = True;
my $n;

sub test($body, $base-css, $settings = {}, Bool :$feed = True) {
    my $css = $base-css.clone: |$settings;
    my $text = $css.write;
    warn {:$text}.perl;
    my $elem = $body.element( :$text, :$css );
    @Html.push: $elem.html;
    $page.gfx.do(.xobject, .left, .bottom) with $elem;

    if ($feed) {
        if ++$n %% 2 {
            $base-css.top +css= 100pt;
            $base-css.left = 20pt;
        }
        else {
            $base-css.left +css= 270pt;
        }
    }
}

for [ { :line-height<9pt> },
      { :line-height<15pt> },
      { :line-height<85%> },
      { :line-height<110%> },
      { :line-height(.85) },
      { :line-height(1.1) },
      { :letter-spacing<1pt> },
      { :letter-spacing<-1pt> },
      { :word-spacing<5pt> },
      { :word-spacing<15pt> },
      { :font-stretch<ultra-condensed> },
      { :font-stretch<ultra-expanded> },
      ] {

    test($body, $css, $_);
}

$css.delete('top');

# do one padded block positioned from the bottom

$css.bottom = $css.height +css 30pt;
$css.right = ($body.width)pt -css $css.left -css $css.width;
$css.delete('left');
test($body, $css, :!feed);

lives-ok {$pdf.save-as: "t/spacings.pdf"};

@Html.append: $body.html-end, '</html>', '';
"t/spacings.html".IO.spurt: @Html.join: "\n";

done-testing;
