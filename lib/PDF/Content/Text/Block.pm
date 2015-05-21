use v6;

use PDF::Content::Text::Line;
use PDF::Content::Text::Atom;

class PDF::Content::Text::Block {
    has Numeric $.line-height;       #| e.g. line-height: 110%  ==>  1.1
    has $.width;
    has $.height;
    has @.lines;
    has @.overflow is rw;
    has $.font-size;

    method actual-width  { @!lines.max({ .actual-width }); }
    method actual-height { @!lines.sum({ .actual-height * ($.line-height || 1) }); }

    submethod BUILD(         :@atoms is copy,
                     Numeric :$word-spacing!,
                     Numeric :$!line-height!,
                     Numeric :$!font-size,
                     Numeric :$!width?,      #| optional constraint
                     Numeric :$!height?,     #| optional constraint
        ) {

        my $line;
        my $line-width = 0.0;

        while @atoms {

            my @word;
            my $atom;
            my $kerning;

            repeat {
                $atom = @atoms.shift;
                @word.push: $atom;
                $kerning = $atom.space < 0;
            } while @atoms && ($kerning
                               || $atom.content eq "\c[NO-BREAK SPACE]"
                               || @atoms[0].content eq "\c[NO-BREAK SPACE]");

            # consume a run of breaking spaces.
            while @atoms && @atoms[0].content ~~ /<![ \c[NO-BREAK SPACE] ]>\s/ {
                @atoms.shift;
                $atom.word-boundary = True;
            }

            my $word-width = [+] @word.map({ .width + .space });

            if !$line || ($!width && $line.atoms && $line-width + $word-width > $!width) {
                last if $!height && (@!lines + 1)  *  $!line-height > $!height;
                $line = PDF::Content::Text::Line.new();
                $line-width = 0.0;
                @!lines.push: $line;
            }

            if $line.atoms && $line.atoms[*-1].word-boundary {
                $line.atoms[*-1].space += $word-spacing;
                $line-width += $word-spacing;
            }

            $line.atoms.push: @word;
            $line-width += $word-width;
        }

        .atoms[*-1].word-boundary = False
            for @!lines;

        $!width //= self.actual-width;
        $!height //= self.actual-height;

        @!overflow = @atoms;
    }

    method align($mode) {
        .align($mode, :$!width )
            for self.lines;
    }

    method content {

        my @content = $.lines.map({
            (.content(:$.font-size), 'T*' => [])
        });

        @content;
    }

}