PDF-Style-p6
============
__Experimental and under construction!__

This is a styling module designed to work with the Raku PDF Tool-chain, including  `PDF::Lite` and `PDF::API6`, etc.

It implements some basic CSS styling of PDF components, including pages, forms, images, or text blocks.

## Simple Styling

```
use v6;
use PDF::Lite;
use PDF::Style;
use CSS::Properties;
use CSS::Units :pt, :ops;

my PDF::Lite $pdf .= new;
my $page = $pdf.add-page;
$page.media-box = 0, 0, 350, 140;

# create and output a styled text-block
my CSS::Properties $css .= new: :style("font-family:Helvetica; width:250pt; height:80pt; border:1pt dashed green; padding: 5pt; word-spacing:10pt;");

my $text = q:to"--ENOUGH!!--".lines.join: ' ';
    Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt
    ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco.
    --ENOUGH!!--

$css.bottom = 20pt;
$css.left = 20pt;
my PDF::Style $text-elem .= element: :$text, :$css;

# display it on the page
$page.gfx.do( .xobject, .bottom, .left) with $text-elem;
$pdf.save-as: "examples/styled-text.pdf";
```
![example.pdf](examples/.previews/styled-text-001.png)

## Supported Properties

Type | Properties
---  | ---
Borders | border-color, border-style ('dotted', 'dashed', 'solid' only),  border-width, padding, margin
Backgrounds | background-color, background-image (url encoded only), background-position, background-repeat
Sizing  | height, max-height, min-height, width, max-width, min-width
Text | font-family, font-style, font-size, font-kerning, font-stretch, font-weight, color, letter-spacing, line-height, text-align vertical-align ('top', 'center', 'bottom' only), word-spacing 
Positioning  | bottom, top, left, right
Body | size, (also border and background properties: padding, border, margin, background-color, etc)
Other | opacity

## Bodies [PDF::Style::Body]

Elements positions and sizes on a body are calculated from CSS properties `top`, `right, `bottom`, `left`, `width` and `height`.

```
use PDF::Lite;
use PDF::Style::Body;
use PDF::Style::Element;
use CSS::Properties;
use CSS::Units :pt, :ops;
use PDF::Content::XObject;

my PDF::Content::XObject $background-image .= open: "t/images/tiny.png";
my $style = "background-color: rgb(180,180,250); background-image: url($background-image); opacity: 0.25; width:420pt; height:595pt";
my PDF::Style::Body $body .= new: :$style;

my PDF::Lite $pdf .= new;

# Create a page, sized and decorated from the body element
my $page = $body.decorate: $pdf.add-page;

# create and lay up some styled elements
my CSS::Properties $css .= new: :style("font-family:Helvetica; width:250pt; height:80pt; top:20pt; left:20pt; border: 1pt solid green; padding: 2pt");

my $text = "Text, styled as $css";

my PDF::Style::Element $text-elem = $body.element( :$text, :$css );

given $text-elem {
    note "text top-left is {.top}pt {.left}pt from page bottom, left corner";
    # output the element on the page.
    $page.gfx.do(.xobject, .left, .bottom);
}

# now position an image below the text block,
# after some styling adjustments
$css.border-color = 'red';
$css.border-style = 'dashed';
$css.top +css= ($text-elem.height('padding') + 5)pt;
$css.height = Nil;

my Str $image = "t/images/snoopy-happy-dance.jpg";
given $body.element(:$image, :$css) {
    note "image bottom-right is {.bottom}pt {.left}pt from page bottom, left corner";
    $page.gfx.do(.xobject, .left, .bottom);
}

# position from bottom right
$css .= new: :style("border:2pt dashed green; bottom:5pt; color:blue; font-family:Helvetica; padding:2pt; right:5pt; text-align:right; width:120pt;");
$page.gfx.do(.xobject, .left, .bottom)
    given $body.element( :text("Text styled as $css"), :$css );

$pdf.save-as: "examples/styling.pdf";
# also save as HTML

"t/example.html".IO.spurt: $body.html;
```
![example.pdf](t/.previews/styling-001.png)

## CSS Property todo lists:

Property|Notes|To-do
---|---|---
border-style|'dotted', 'dashed', 'solid'|Other styles.
text-decoration||NYI
text-indent||NYI
text-transform||NYI
vertical-align|'top', 'center', 'bottom' only|Other modes
  
### CSS Property Shortlist
- content
- direction
- display
- font-variant
- empty-cells
- float
- list-style, list-style-image, list-style-position, list-style-type
- outline, outline-width, outline-style, outline-color
- overflow
- unicode-bidi
- table-layout
- text-decoration
- visibility
- white-spacing

### Nice to have:

Fonts:
- font-synthesis
- @font-face

Body
- @top-left-corner, etc
- page-break-before, page-break-after, page-break-inside

CSS Transforms http://dev.w3.org/csswg/css-transforms/#transform
- transform
- transform-origin

