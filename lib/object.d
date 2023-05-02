module object;

alias string = immutable(char)[];
alias usize = typeof(int.sizeof);
alias size_t = usize;

alias noreturn = typeof(*null);

static if ((void*).sizeof == 8) {
    alias uintptr = ulong;
} else static if ((void*).sizeof == 4) {
    alias uintptr = uint;
} else {
    static assert(0, "pointer size must be 4 or 8 bytes");
}

version (LDC) {
    extern (C) void _d_array_slice_copy(void* dst, usize dstlen, void* src,
            usize srclen, usize elemsz) {
        cast(void) srclen;
        import builtins : memcpy;
        memcpy(dst, src, dstlen * elemsz);
    }
} else {
    extern (C) void[] _d_arraycopy(usize size, void[] from, void[] to) {
        import builtins : memcpy;
        memcpy(to.ptr, from.ptr, to.length * size);
        return to;
    }
}

ref string _d_arrayappendT(return ref scope string x, scope string y) @trusted;
bool __equals(scope const string lhs, scope const string rhs);

void __switch_error()(string file = __FILE__, usize line = __LINE__) {
    import core.exception : __switch_errorT;
    __switch_errorT(file, line);
}

// Like assert but allows side effects in the assertion expression. Does not
// perform a check if assertion expressions are disabled (-release flag).
void must(bool cond, string msg = "must failure", string file = __FILE__, int line = __LINE__) {
    version (assert) {
        ensure(cond, msg, file, line);
    }
}

// Like assert but allows side effects in the assertion expression and is not
// removed even if assertions are removed due to compiler flags.
void ensure(bool cond, string msg = "ensure failure", string file = __FILE__, int line = __LINE__) {
    import core.exception : panic;
    if (!cond) {
        panic(file, line, msg);
    }
}
