module ulib.iface;

// Templates for automatically creating interface types for structs in betterC.

// Usage example:
//
// struct Showable {
//     struct Vtbl {
//         void function() show;
//         void function(int) greet;
//     }
//
//     mixin MakeInterface!(Showable);
// }
//
// Struct that implements Showable:
//
// import core.stdc.stdio;
// struct Foo {
//     int x;
//     void show() {
//         printf("hi %d\n", x);
//     }
//     void greet(int name) {
//         printf("greetings %d %d\n", name, x);
//     }
// }
//
// A value `f` of type Foo* can be converted to a Showable with
// `Showable.impl(f)`

import ulib.trait;

auto call(Fptr, Args...)(void* this_, Fptr funcptr, Args args) {
    ReturnType!Fptr delegate(Args) dg;
    dg.funcptr = funcptr;
    dg.ptr = this_;
    return dg(args);
}

// MakeInterface populates the current struct with a self pointer, a vtable
// pointer, and wrapper functions that forward calls to the vtable. It also
// creates an `impl` function which converts a value of type `T*` to an
// interface by initializing a vtable and returning a wrapper that points to
// the object and its vtable. When using GDC the vtable is statically
// initialized per-type, but for LDC the vtable must be initialized at runtime
// because struct methods cannot be accessed at compile-time with LDC/DMD (see
// https://github.com/dlang/dmd/pull/10958).
template MakeInterface(Type) {
    alias Vtbl = Type.Vtbl;

    void* self;

    static foreach (m; __traits(allMembers, Vtbl)) {
        mixin(
            `auto ` ~ m ~ `(Args...)(Args args) {
                return call(self, vtbl.` ~ m ~ `, args);
            }`
        );
    }

    version (LDC) {
        Vtbl* vtbl;

        template vtbldat(T) {
            static Vtbl vtbldat;
        }

        static auto impl(T)(T* x) {
            static foreach (m; __traits(allMembers, Vtbl)) {
                mixin(`(vtbldat!T).` ~ m ~ ` = &T.` ~ m ~ `;`);
            }
            return Type(x, &vtbldat!T);
        }
    } else version (GNU) {
        immutable Vtbl* vtbl;

        static auto impl(T)(T* x) {
            // returns comma-separated list of functions in the Vtbl, for example:
            // "T.x1,T.x1,T.x3,"
            alias fnlist = () {
                string fns = "";
                static foreach (m; __traits(allMembers, Vtbl)) {
                    fns ~= `&T.` ~ m ~ `,`;
                }
                return fns;
            };
            mixin(`static immutable Vtbl tbl = Vtbl(
                ` ~ fnlist() ~ `
            );`);
            return Type(x, &tbl);
        }
    }
}
