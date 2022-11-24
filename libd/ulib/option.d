module ulib.option;

import ulib.trait;

alias Optp(T) = Opt(T*);

struct Opt(T) {
    this(T s) {
        value = s;
        static if (!isPointer!T) {
            exists = true;
        }
    }

    bool has() const {
        static if (isPointer!T) {
            return value != null;
        } else {
            return exists;
        }
    }

    T get() const {
        static if (isPointer!T) {
            assert(value != null, "option is none");
            return value;
        } else {
            assert(exists, "option is none");
            return value;
        }
    }

private:
    static if (!isPointer!T) {
        bool exists = false;
    }
    T value;
}

unittest {
    auto o = Opt!int(42);
    assert(o.has());
    assert(o.get() == 42);

    auto v = Opt!int();
    assert(!v.has());
}
