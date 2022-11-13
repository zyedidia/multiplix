module object;

alias string = immutable(char)[];
alias size_t = typeof(int.sizeof);
alias ptrdiff_t = typeof(cast(void*) 0 - cast(void*) 0);

static if ((void*).sizeof == 8) {
    alias uintptr = ulong;
} else static if ((void*).sizeof == 4) {
    alias uintptr = uint;
} else {
    static assert("pointer size must be 4 or 8 bytes");
}

version (LDC) {
    extern (C) void _d_array_slice_copy(void* dst, size_t dstlen, void* src,
            size_t srclen, size_t elemsz) {
        import ulib.memory : memmove;

        memmove(dst, src, dstlen * elemsz);
    }
} else {
    extern (C) void[] _d_arraycopy(size_t size, void[] from, void[] to) {
        import ulib.memory : memmove;

        memmove(to.ptr, from.ptr, to.length * size);
        return to;
    }
}
