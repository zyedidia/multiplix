module object;

alias string = immutable(char)[];
alias size_t = typeof(int.sizeof);
alias ptrdiff_t = typeof(cast(void*) 0 - cast(void*) 0);

alias noreturn = typeof(*null);

static if ((void*).sizeof == 8) {
    alias uintptr = ulong;
} else static if ((void*).sizeof == 4) {
    alias uintptr = uint;
} else {
    static assert(0, "pointer size must be 4 or 8 bytes");
}

void check(bool b) {
    import core.exception;

    if (!b) {
        panic("check failed");
    }
}

extern (C) void brk() {
    pragma(LDC_never_inline);
    asm {
        "nop";
    }
}

version (LDC) {
    extern (C) void _d_array_slice_copy(void* dst, size_t dstlen, void* src,
            size_t srclen, size_t elemsz) {
        cast(void) srclen;
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

// for printing pointers as hex values
struct Hex {
    uintptr p;
}

public import core.exception : panic;
