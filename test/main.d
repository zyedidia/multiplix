module test.main;

import io = ulib.io;
import kernel.board;

extern (C) void kmain() {
    Uart.init(115200);
    int el;
    asm {
        "mrs %0, CurrentEL" : "=r"(el);
    }
    io.writeln("EL: ", el >> 2);
}
