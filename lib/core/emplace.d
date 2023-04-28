module core.emplace;

import builtins : memcpy, memset;
import core.bits;

enum HasCtor(T) = __traits(hasMember, T, "__ctor");
enum HasDtor(T) = __traits(hasMember, T, "__xdtor");

template emplace_init(T, Args...) {
    // Initializes the memory at `val` as a new value of type T, and calls its
    // constructor. If `T.__ctor` exists then the constructor is called.
    //
    // Returns `true` on success and `false` on failure.
    bool emplace_init(T* val, Args args) {
        static if (!is(T == struct)) {
            *val = T.init;
        } else {
            auto initializer = __traits(initSymbol, T);
            if (initializer.ptr == null) {
                memset(val, 0, T.sizeof);
            } else {
                memcpy(val, initializer.ptr, initializer.length);
            }
        }
        static if (HasCtor!T) {
            val.__ctor(args);
        } else {
            static assert(args.length == 0, "no constructor exists, but arguments were provided");
        }
        return true;
    }
}
