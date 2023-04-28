module plix.panic;

import plix.print : println;

extern (C) noreturn _halt();

// Panic marker for debugging.
extern (C) void _panic() {
    pragma(inline, false);
}

extern (C) noreturn panic(string file, int line, string message) {
    println(file, ":", line, ": ", message);
    _panic();
    _halt();
}
