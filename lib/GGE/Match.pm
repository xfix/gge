use v6;

# RAKUDO: See the postcircumfix:<{ }> below.
class Store {
    has %!hash is rw;
    has @!array is rw;

    method hash-access($key) { %!hash{$key} }
    method hash-delete($key) { %!hash.delete($key) }

    method array-access($index) { @!array[$index] }
    method array-setelem($index, $value) { @!array[$index] = $value }
    method array-push($item) { @!array.push($item) }
    method array-list() { @!array.list }
    method array-elems() { @!array.elems }
}

class GGE::Match {
    has $.target;
    has $.from is rw = 0;
    has $.to is rw = 0;
    has $!store = Store.new;

    # RAKUDO: Shouldn't need this
    multi method new(*%_) {
        self.bless(*, |%_);
    }

    multi method new(GGE::Match $match) {
        defined $match ?? self.new(:target($match.target), :from($match.from),
                                   :to($match.to))
                       !! self.new();
    }

    method true() {
        return $!to >= $!from;
    }

    method dump_str() {
        ?self.true()
            ?? sprintf '<%s @ 0>', $!target.substr($!from, $!to - $!from)
            !! '';
    }

    method Str() {
        $!target.substr($!from, $!to - $!from)
    }

    # RAKUDO: There's a bug preventing me from using hash lookup in a
    #         postcircumfix:<{ }> method. This workaround uses the above
    #         class to put the problematic hash lookup out of reach.
    method postcircumfix:<{ }>($key) { $!store.hash-access($key) }
    method postcircumfix:<[ ]>($index) { $!store.array-access($index) }

    method set($index, $value) { $!store.array-setelem($index, $value) }

    method delete($key) { $!store.hash-delete($key) }

    method push($submatch) {
        $!store.array-push($submatch);
    }

    method llist() {
        $!store.array-list();
    }

    method elems() {
        $!store.array-elems();
    }

    method ident() {
        my $mob = self.new(self);
        $mob.from = self.to;
        my $target = $mob.target;
        my $pos = $mob.to;
        if $target.substr($pos, 1) ~~ /<alpha>/ {
            ++$pos while $pos < $target.chars
                         && $target.substr($pos, 1) ~~ /\w/;
            $mob.to = $pos;
        }
        # RAKUDO: Putting 'return' here makes Rakudo blow up.
        $mob;
    }
}
