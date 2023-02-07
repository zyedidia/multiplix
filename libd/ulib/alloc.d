module ulib.alloc;

import ulib.memory;
import ulib.bits;

enum HasCtor(T) = __traits(hasMember, T, "__ctor");
enum HasDtor(T) = __traits(hasMember, T, "__xdtor");

template emplace_init(T, Args...) {
    // LDC supports the more efficient initSymbol trait so we don't use a static T.init.
    version (LDC) {} else {
        immutable init = T.init;
    }
    // Initializes the memory at `val` as a new value of type T, and calls its
    // constructor. If `T.__ctor` exists then the constructor is called.
    //
    // Returns `true` on success and `false` on failure.
    bool emplace_init(T* val, Args args) {
        static if (!is(T == struct)) {
            *val = T.init;
        } else {
            version (LDC) {
                auto initializer = __traits(initSymbol, T);
                if (initializer.ptr == null) {
                    memset(val, 0, T.sizeof);
                } else {
                    memcpy(val, initializer.ptr, initializer.length);
                }
            } else {
                memcpy(val, &init, T.sizeof);
            }
        }
        static if (HasCtor!T) {
            val.__ctor(args);
        } else {
            static assert(args.length == 0, "no constructor/knew exists, but arguments were provided");
        }
        return true;
    }
}
