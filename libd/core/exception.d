module core.exception;

import kernel.spinlock;

import builtins = core.builtins;

shared Spinlock lock;

noreturn panic(Args...)(Args msg) {
    import ulib.print;
    import kernel.irq;
    Irq.off();
    lock.lock();
    printf("panic (%p): ", builtins.return_address(0)-4);
    println(msg);
    lock.unlock();
    _panic();
    _halt();
}

import core.stdc.stdarg;
pragma(printf)
extern (C) noreturn panicf(scope const char* fmt, ...) {
    import ulib.print;
    import kernel.irq;
    Irq.off();
    lock.lock();
    printf("panic (%p): ", builtins.return_address(0)-4);
    va_list ap;
    va_start(ap, fmt);
    vprintf(fmt, ap);
    va_end(ap);
    lock.unlock();
    _panic();
    _halt();
}

// panic marker for debugging
extern (C) void _panic() {
    pragma(inline, false);
    asm { "nop"; "nop"; }
}

// Compiler lowers final switch default case to this (which is a runtime error).
void __switch_errorT()(string file = __FILE__, size_t line = __LINE__) @trusted {
    panic(file, ":", line, ": No appropriate switch clause found");
}

// Called when an assert() fails.
void _assert_msg(string msg, string file, uint line) {
    panic(file, ":", line, ": ", msg);
}

// Called when an assert() fails.
void _assert(string file, uint line) {
    panic(file, ":", line, ": assertion failure");
}

// Called when an invalid array index/slice or associative array key is accessed.
void _arraybounds(string file, uint line) {
    panic(file, ":", line, ": out of bounds");
}

// Called when an out of range slice of an array is created.
void _arraybounds_slice(string file, uint line, size_t lower, size_t upper, size_t length) {
    panic(file, ":", line, ": invalid slice [", lower, " .. ", upper,
            "] of array of length ", length);
}

// Called when an out of range array index is accessed.
void _arraybounds_index(string file, uint line, size_t index, size_t length) {
    panic(file, ":", line, ": invalid index [", index, "] of array of length ", length);
}

extern (C) {
    void _d_assert_msg(string msg, string file, uint line) {
        _assert_msg(msg, file, line);
    }

    void _d_assert(string file, uint line) {
        _assert(file, line);
    }

    void _d_assertp(immutable(char*) file, uint line) {
        import libc : strlen;

        _assert(file[0 .. strlen(file)], line);
    }

    void _d_arraybounds(string file, uint line) {
        _arraybounds(file, line);
    }

    void _d_arrayboundsp(immutable(char*) file, uint line) {
        import libc : strlen;

        _arraybounds(file[0 .. strlen(file)], line);
    }

    void _d_arraybounds_slice(string file, uint line, size_t lower, size_t upper, size_t length) {
        _arraybounds_slice(file, line, lower, upper, length);
    }

    void _d_arraybounds_slicep(immutable(char*) file, uint line, size_t lower,
            size_t upper, size_t length) {
        import libc : strlen;

        _arraybounds_slice(file[0 .. strlen(file)], line, lower, upper, length);
    }

    void _d_arraybounds_index(string file, uint line, size_t index, size_t length) {
        _arraybounds_index(file, line, index, length);
    }

    void _d_arraybounds_indexp(immutable(char*) file, uint line, size_t index, size_t length) {
        import libc : strlen;

        _arraybounds_index(file[0 .. strlen(file)], line, index, length);
    }

    void _d_unittest(string file, uint line) {
        _assert(file, line);
    }

    void _d_unittest_msg(string msg, string file, uint line) {
        _assert_msg(msg, file, line);
    }

    void __assert(const(char)* msg, const(char)* file, int line) {
        import libc : strlen;

        string smsg = cast(string) msg[0 .. strlen(msg)];
        string sfile = cast(string) file[0 .. strlen(file)];
        _assert_msg(smsg, sfile, line);
    }

    // stack protection (GDC-only feature)

    version (GNU) {
        import gcc.attributes;

        @used:
        immutable ulong __stack_chk_guard = 0xdeadc0de;

        void __stack_chk_fail() {
            panic("stack corruption detected");
        }
    }
}
