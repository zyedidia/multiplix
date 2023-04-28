module core.sync;

struct Unguard(T) {
    private T myval;
    pragma(inline, true)
    ref T val() shared {
        return *cast(T*) &myval;
    }
    alias val this;
}
