module ulib.option;

import ulib.trait;

alias Optp(T) = Opt(T*);

struct Opt(T) if (isPointer!T) {
    this(T s) {
        value = s;
    }

    static Opt!T none() {
        return Opt!T(null);
    }

    bool has() {
        return value != null;
    }

    T get() {
        assert(value != null, "option is none");
        return value;
    }

private:
    T value;

}

struct Opt(T) if (!isPointer!T) {
    this(T s) {
        value = s;
        exists = true;
    }

    static Opt!T none() {
        Opt!T empty = void;
        empty.exists = false;
        return empty;
    }

    bool has() {
        return exists;
    }

    T get() {
        assert(exists, "option is none");
        return value;
    }

private:
    bool exists = false;
    T value;
}

unittest {
    auto o = Opt!int(42);
    assert(o.has());
    assert(o.get() == 42);

    auto v = Opt!int();
    assert(!v.has());
}
