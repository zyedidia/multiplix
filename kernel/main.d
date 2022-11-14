module kernel.main;

import io = ulib.io;
import core.volatile;

import dev = kernel.board.virt.dev;

__gshared int x = 2;

void kmain() {
    io.writeln("Hello world");

    int i = x + 42;
    io.writeln(i);

    io.writeln(&kmain);
}

extern (C) {
    void ulib_tx(ubyte b) {
        dev.Uart.tx(b);
    }

    void ulib_exit(ubyte code) {
        dev.SysCon.shutdown();
    }
}
