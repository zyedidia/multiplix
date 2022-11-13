module kernel;

import io = ulib.io;
import core.volatile;

import dev = board.virt.dev;

void kmain() {
    io.writeln("Hello world");

    const int i = 42;
    io.writeln(i);

    io.writeln(&kmain);
}

extern (C) {
    void ulib_tx(ubyte b) {
        static import uart;
        uart.tx(b);
    }

    void ulib_exit(ubyte code) {
        dev.SysCon.shutdown();
    }
}
