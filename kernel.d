module kernel;

import io = ulib.io;
import core.volatile;

void kmain() {
    io.writeln("Hello world");
}

void shutdown() {
    enum poweroff = cast(uint*) 0x100000;
    volatileStore(poweroff, 0x5555);
}

extern (C) {
    void ulib_tx(ubyte b) {
        static import uart;
        uart.tx(b);
    }

    void ulib_exit(ubyte code) {
        shutdown();
    }
}
