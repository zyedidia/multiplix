module core.option;

import core.trait;

struct Option(T) {
    this(T s) {
        value = s;
        static if (!isptr!T) {
            exists = true;
        }
    }

    static Option!T none() {
        static if (isptr!T) {
            return Option!T(null);
        } else {
            Option!T empty = void;
            empty.exists = false;
            return empty;
        }
    }

    bool has() {
        static if (isptr!T) {
            return value != null;
        } else {
            return exists;
        }
    }

    T get() {
        static if (isptr!T) {
            assert(value != null, "option is none");
        } else {
            assert(exists, "option is none");
        }
        return value;
    }

private:
    static if (!isptr!T) {
        bool exists = false;
    }
    T value;
}
