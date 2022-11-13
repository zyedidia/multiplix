module core.exception;

import io = ulib.io;
import sys = ulib.sys;

void panic(Args...)(Args msg) {
    io.writeln("panic: ", msg);
    sys.exit(1);
}

// Compiler lowers final switch default case to this (which is a runtime error).
void __switch_errorT()(string file = __FILE__, size_t line = __LINE__) @trusted {
    assert(0, "No appropriate switch clause found");
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

    void _d_arraybounds(string file, uint line) {
        _arraybounds(file, line);
    }

    void _d_arraybounds_slice(string file, uint line, size_t lower, size_t upper, size_t length) {
        _arraybounds_slice(file, line, lower, upper, length);
    }

    void _d_arraybounds_index(string file, uint line, size_t index, size_t length) {
        _arraybounds_index(file, line, index, length);
    }

    void _d_unittest(string file, uint line) {
        _assert(file, line);
    }

    void _d_unittest_msg(string msg, string file, uint line) {
        _assert_msg(msg, file, line);
    }

    void __assert(const(char)* msg, const(char)* file, int line) {
        import ulib.memory : strlen;

        string smsg = cast(string) msg[0 .. strlen(msg)];
        string sfile = cast(string) file[0 .. strlen(file)];
        _assert_msg(smsg, sfile, line);
    }
}
