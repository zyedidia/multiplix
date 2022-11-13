module ulib.sum;

import meta = ulib.meta;

struct Sum(T...) {
    @disable this();

    this(S)(S s) if (meta.contains!(S, T)) {
        static foreach (i, t; T) {
            static if (is(S == t)) {
                tag = i;
                mixin("sum._" ~ t.stringof ~ " = s;");
            }
        }
    }

    bool has(S)() if (meta.contains!(S, T)) {
        static foreach (i, t; T) {
            static if (is(S == t)) {
                return i == tag;
            }
        }
    }

    S get(S)() if (meta.contains!(S, T)) {
        static foreach (i, t; T) {
            static if (is(S == t)) {
                if (tag == i) {
                    return mixin("sum._" ~ t.stringof);
                } else {
                    assert(false, "sum type did not have " ~ S.stringof);
                }
            }
        }
    }

private:
    union _SumUnion {
        static foreach (t; T) {
            mixin(t.stringof ~ " _" ~ t.stringof ~ ";");
        }
    }

    _SumUnion sum;

    ubyte tag;
    static assert(T.length < typeof(tag).max);
}

unittest {
    auto s = Sum!(int, uint)(cast(uint) 42);

    assert(s.has!uint);
    assert(!s.has!int);
    assert(s.get!uint == 42);
}
