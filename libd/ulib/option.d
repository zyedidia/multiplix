module ulib.option;

struct Option(T) {
    this(T s) {
        exists = true;
        value = s;
    }

    bool has() {
        return exists;
    }

    T get() {
        if (!exists) {
            assert(false, "option is none");
        }
        return value;
    }

private:
    bool exists = false;
    T value;
}

unittest {
    auto o = Option!int(42);
    assert(o.has());
    assert(o.get() == 42);

    auto v = Option!int();
    assert(!v.has());
}
