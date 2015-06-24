use v6;

class PDF::Compose::Page {

    use Font::AFM;
    use PDF::Compose::Units :ALL;
    use PDF::Content::Text::Atom;
    use PDF::Content::Text::Block;
    use PDF::Compose::Font;

    has $.width = 595px;
    has $.height = 842px;

    method text( $text, Hash :$style = {}, Bool :$dry = False) {

        my $position = $style<position> // 'absolute';
        die "sorry can only handle absolute positioning at the moment"
            unless $position eq 'absolute';
        die "sorry cannot handle bottom positioning yet" if $style<bottom>;
        die "sorry cannot handle right positioning yet" if $style<right>;
        my $left = $style<left> // 0px;
        my $top = $style<top> // 0px;
        my $font-family = $style<font-family> // 'arial';
        my $font-weight = $style<font-weight> // 'normal';
        my $font-style = $style<font-style> // 'normal';
        my $font-size = $style<font-size> // 16px;
        my $width = $style<width> // self.width - $left;
        my $height = $style<height> // self.height - $top;
        my $line-height = $style<line-height> // $font-size * 1.2;

        # todo - see how others handle auto widths & page boundarys
        warn "pushing the boundaries: {:$width} {:$height} {:$top} {:$left}"
            unless $width > 0 && $height > 0 && $left >= 0 && $left < self.width && $top >= 0 && $top < self.height;

        my $font = PDF::Compose::Font.core-font( $font-family, :$font-weight, :$font-style );

        # take word spacing as one space character, for now
        my $word-spacing = $font.stringwidth( ' ', $font-size );

        my $kern = $style<font-kerning>
            && ( $style<font-kerning> eq 'normal'
                 || ($style<font-kerning> eq 'auto' && $font-size <= 32));

        # assume uniform simple text, for now
        my @chunks = $text.comb(/ \w [ [ \w | <:Punctuation > ] <![ \- ]> ]* '-'?
                                | <[ \c[NO-BREAK SPACE] ]>
                                | [ <![ \c[NO-BREAK SPACE] ]> \s ]+
                                | .
                                /).map( -> $word {
                                    $kern
                                        ?? $font.kern($word, $font-size, :$kern).list
                                        !! $font.encode($word)
                                 });

        my @atoms;
        while @chunks {
            my $content = @chunks.shift;
            my %atom = :$content;
            %atom<space> = @chunks && @chunks[0] ~~ Numeric
                ?? @chunks.shift
                !! 0;
            %atom<width> = $font.stringwidth($content, $font-size);
            # discard non-breaking white-space
            next if $content ~~ / <![ \c[NO-BREAK SPACE] ]> \s /;
            my $followed-by-ws = @chunks && @chunks[0] ~~ / <![ \c[NO-BREAK SPACE] ]> \s /;
            my $kerning = %atom<space> < 0;

            my $atom = PDF::Content::Text::Atom.new( |%atom, :$height );
            if $kerning {
                $atom.sticky = True;
            }
            elsif $atom.content eq "\c[NO-BREAK SPACE]" {
                $atom.elastic = True;
                $atom.sticky = True;
                @atoms[*-1].sticky = True
                    if @atoms;
            }
            elsif $followed-by-ws {
                $atom.elastic = True;
                $atom.space += $word-spacing;
            }

            @atoms.push: $atom;
        }

        my $text-block = PDF::Content::Text::Block.new( :@atoms, :$line-height, :$width, :$height, :$font-size );

        if my $text-align = $style<text-align> {
            $text-block.align( $text-align )
                if $text-align eq 'left' | 'right' | 'center' | 'justify';
        }

        $text-block;
    }
}
