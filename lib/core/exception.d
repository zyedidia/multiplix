module core.exception;

import core.stdc.stdarg;

extern (C) {
    noreturn _halt();
    void _panic();
    noreturn panic(string, int, string);
    pragma(printf)
    extern (C) void printf(const char* fmt, ...);
    extern (C) void vprintf(const char* fmt, va_list ap);
}

pragma(printf)
extern (C) noreturn panicf(scope const char* fmt, ...) {
    printf("panic: ");
    va_list ap;
    va_start(ap, fmt);
    vprintf(fmt, ap);
    va_end(ap);
    _panic();
    _halt();
}

// Compiler lowers final switch default case to this (which is a runtime error).
void __switch_errorT()(string file = __FILE__, usize line = __LINE__) @trusted {
    panic(file, cast(int) line, "no appropriate switch clause found");
}

// Called when an assert() fails.
void _assert_msg(string msg, string file, uint line) {
    panic(file, line, msg);
}

// Called when an assert() fails.
void _assert(string file, uint line) {
    panic(file, line, "assertion failure");
}

// Called when an invalid array index/slice or associative array key is accessed.
void _arraybounds(string file, uint line) {
    panic(file, line, "out of bounds");
}

// Called when an out of range slice of an array is created.
void _arraybounds_slice(string file, uint line, usize lower, usize upper, usize length) {
    panic(file, line, "slice out of bounds");
}

// Called when an out of range array index is accessed.
void _arraybounds_index(string file, uint line, usize index, usize length) {
    panic(file, line, "index out of bounds");
}

extern (C) {
    import builtins : strlen;

    void _d_assert_msg(string msg, string file, uint line) {
        _assert_msg(msg, file, line);
    }

    void _d_assert(string file, uint line) {
        _assert(file, line);
    }

    void _d_assertp(immutable(char*) file, uint line) {
        _assert(file[0 .. strlen(file)], line);
    }

    void _d_arraybounds(string file, uint line) {
        _arraybounds(file, line);
    }

    void _d_arrayboundsp(immutable(char*) file, uint line) {
        _arraybounds(file[0 .. strlen(file)], line);
    }

    void _d_arraybounds_slice(string file, uint line, usize lower, usize upper, usize length) {
        _arraybounds_slice(file, line, lower, upper, length);
    }

    void _d_arraybounds_slicep(immutable(char*) file, uint line, usize lower,
            usize upper, usize length) {
        _arraybounds_slice(file[0 .. strlen(file)], line, lower, upper, length);
    }

    void _d_arraybounds_index(string file, uint line, usize index, usize length) {
        _arraybounds_index(file, line, index, length);
    }

    void _d_arraybounds_indexp(immutable(char*) file, uint line, usize index, usize length) {
        _arraybounds_index(file[0 .. strlen(file)], line, index, length);
    }

    void _d_unittest(string file, uint line) {
        _assert(file, line);
    }

    void _d_unittestp(immutable(char*) file, uint line) {
        _assert(file[0 .. strlen(file)], line);
    }

    void _d_unittest_msg(string msg, string file, uint line) {
        _assert_msg(msg, file, line);
    }

    void __assert(immutable(char)* msg, immutable(char)* file, int line) {
        panicf("%s:%d: %s\n", file, line, msg);
    }

    // stack protection (GDC-only feature)

    version (GNU) {
        import gcc.attributes;

        @used:
        const ulong __stack_chk_guard = 0xdeadc0de;

        void __stack_chk_fail() {
            panicf("stack corruption detected");
        }
    }
}
