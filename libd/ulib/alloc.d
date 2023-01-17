module ulib.alloc;

import ulib.memory;
import ulib.bits;

enum HasCtor(T) = __traits(hasMember, T, "__ctor");
enum HasDtor(T) = __traits(hasMember, T, "__dtor");

template emplace_init(T, Args...) {
    // LDC supports the more efficient initSymbol trait.
        immutable init = T.init;
    void emplace_init(T* val, Args args) {
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
            static assert(args.length == 0, "no constructor exists, but arguments were provided");
        }
    }
}
