use v6;
use GGE::Match;

enum GGE_BACKTRACK <
    GREEDY
    EAGER
    NONE
>;

role ShowContents {
    method contents() {
        self.ast;
    }
}

class GGE::Exp is GGE::Match {
    method structure($indent = 0) {
        my $contents
            = self.llist
                ?? "[{ map { "\n{$_.structure($indent + 1)}" }, self.llist }"
                   ~ "\n{'  ' x $indent}]"
                !! defined self.?contents
                    ?? " ('{self.contents}')"
                    !! '';
        '  ' x $indent ~ self.WHAT.perl ~ $contents;
    }
}

class GGE::Exp::Literal is GGE::Exp does ShowContents {
    method matches($string, $pos is rw) {
        if $pos >= $string.chars {
            return False;
        }
        my $value = ~self.ast;
        if $string.substr($pos, $value.chars) eq $value {
            $pos += $value.chars;
            return True;
        }
    }
}

class GGE::Exp::Quant is GGE::Exp {
    has &.backtrack = { False };

    method matches($string, $pos is rw) {
        for ^self<min> {
            return False if !self[0].matches($string, $pos);
        }
        my $n = self<min>;
        if self<backtrack> == EAGER {
            &!backtrack = {
                $n++ < self<max> && self[0].matches($string, $pos)
            };
        }
        else {
            my @positions;
            while $n++ < self<max> {
                push @positions, $pos;
                last if !self[0].matches($string, $pos);
            }
            if self<backtrack> == GREEDY {
                &!backtrack = {
                    @positions && $pos = pop @positions
                };
            }
        }
        return True;
    }
}

class GGE::Exp::CCShortcut is GGE::Exp does ShowContents {
    method matches($string, $pos is rw) {
        if $pos >= $string.chars {
            return False;
        }
        if self.Str eq '.'
           || self.Str eq '\\s' && $string.substr($pos, 1) eq ' '
           || self.Str eq '\\S' && $string.substr($pos, 1) ne ' '
           || self.Str eq '\\N' && !($string.substr($pos, 1) eq "\n"|"\r") {
            ++$pos;
            return True;
        }
        else {
            return False;
        }
    }
}

class GGE::Exp::Newline is GGE::Exp does ShowContents {
    method matches($string, $pos is rw) {
        if $pos >= $string.chars {
            return False;
        }
        if $string.substr($pos, 2) eq "\r\n" {
            $pos += 2;
            return True;
        }
        if $string.substr($pos, 1) eq "\n"|"\r" {
            ++$pos;
            return True;
        }
        else {
            return False;
        }
    }
}

class GGE::Exp::Anchor is GGE::Exp does ShowContents {
    method matches($string, $pos is rw) {
        return self.ast eq '^' && $pos == 0
            || self.ast eq '$' && $pos == $string.chars
            || self.ast eq '<<' && $string.substr($pos, 1) ~~ /\w/
               && ($pos == 0 || $string.substr($pos - 1, 1) !~~ /\w/)
            || self.ast eq '>>' && $pos > 0
               && $string.substr($pos - 1, 1) ~~ /\w/
               && ($pos == $string.chars || $string.substr($pos, 1) !~~ /\w/)
            || self.ast eq '^^' && ($pos == 0 || $pos < $string.chars
               && $string.substr($pos - 1, 1) eq "\n")
            || self.ast eq '$$' && ($string.substr($pos, 1) eq "\n"
               || $pos == $string.chars
                  && ($pos < 1 || $string.substr($pos - 1, 1) ne "\n"));
    }
}

class GGE::Exp::Concat is GGE::Exp {
}

class GGE::Exp::Modifier is GGE::Exp does ShowContents {
}

class GGE::Exp::EnumCharList is GGE::Exp does ShowContents {
    method matches($string, $pos is rw) {
        if $pos >= $string.chars {
            return False;
        }
        if defined self.ast.index($string.substr($pos, 1)) {
            ++$pos;
            return True;
        }
        else {
            return False;
        }
    }
}

class GGE::Exp::Alt is GGE::Exp {
}

class GGE::Exp::WS is GGE::Exp {
    method matches($string, $pos is rw) {
        return True;
    }
}
